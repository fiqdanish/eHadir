import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import '../models/conflict_result.dart';
import 'mock_db_service.dart';

final bookingProvider = ChangeNotifierProvider<BookingService>((ref) {
  final db = ref.watch(mockDbProvider);
  return BookingService(db);
});

/// Booking business-logic layer.
///
/// Wraps [MockDatabaseService] with conflict detection + approval workflow.
class BookingService extends ChangeNotifier {
  final MockDatabaseService _db;

  BookingService(this._db);

  // ═══════════════════════════════════════════════════════════
  //  CONFLICT DETECTION ENGINE
  // ═══════════════════════════════════════════════════════════

  /// Run a full conflict analysis against the master timetable AND
  /// already-approved bookings.  Returns a structured [ConflictResult].
  ConflictResult checkAllConflicts(Booking proposed) {
    final List<ConflictDetail> conflicts = [];

    final pStart = proposed.startMinutes;
    final pEnd   = proposed.endMinutes;

    // ── 1. Master timetable ──────────────────────────────────
    for (final t in _db.masterTimetable) {
      if (t.dayOfWeek != proposed.date.weekday) continue;
      if (pStart >= t.endMinutes || pEnd <= t.startMinutes) continue;

      // Time overlaps — check each dimension
      if (t.room == proposed.room) {
        conflicts.add(ConflictDetail(
          type: ConflictType.room,
          description:
              '${t.room} is occupied by "${t.subject}" (${_fmtTime(t.startTime)}–${_fmtTime(t.endTime)})',
          isHard: true,
          conflictingEntity: t.room,
        ));
      }
      if (t.lecturerId == proposed.lecturerId) {
        conflicts.add(ConflictDetail(
          type: ConflictType.lecturer,
          description:
              'You already have "${t.subject}" scheduled at ${_fmtTime(t.startTime)}–${_fmtTime(t.endTime)}',
          isHard: false,
          conflictingEntity: _db.getLecturerName(t.lecturerId),
        ));
      }
      if (t.cohort == proposed.cohort) {
        conflicts.add(ConflictDetail(
          type: ConflictType.cohort,
          description:
              'Cohort ${t.cohort} has "${t.subject}" at ${_fmtTime(t.startTime)}–${_fmtTime(t.endTime)}',
          isHard: false,
          conflictingEntity: t.cohort,
        ));
      }
    }

    // ── 2. Already-approved bookings ─────────────────────────
    for (final b in _db.approvedBookings) {
      if (b.date.year != proposed.date.year ||
          b.date.month != proposed.date.month ||
          b.date.day != proposed.date.day) {
        continue;
      }
      if (pStart >= b.endMinutes || pEnd <= b.startMinutes) {
        continue;
      }

      if (b.room == proposed.room) {
        conflicts.add(ConflictDetail(
          type: ConflictType.room,
          description:
              '${b.room} is reserved for "${b.subject}" (${_fmtTime(b.startTime)}–${_fmtTime(b.endTime)})',
          isHard: true,
          conflictingEntity: b.room,
        ));
      }
      if (b.lecturerId == proposed.lecturerId) {
        conflicts.add(ConflictDetail(
          type: ConflictType.lecturer,
          description:
              'You have a replacement class "${b.subject}" at ${_fmtTime(b.startTime)}–${_fmtTime(b.endTime)}',
          isHard: false,
          conflictingEntity: _db.getLecturerName(b.lecturerId),
        ));
      }
      if (b.cohort == proposed.cohort) {
        conflicts.add(ConflictDetail(
          type: ConflictType.cohort,
          description:
              'Cohort ${b.cohort} has replacement class "${b.subject}" at ${_fmtTime(b.startTime)}–${_fmtTime(b.endTime)}',
          isHard: false,
          conflictingEntity: b.cohort,
        ));
      }
    }

    // ── 3. Pending bookings (avoid double-pending same slot) ─
    for (final b in _db.pendingBookings) {
      if (b.date.year != proposed.date.year ||
          b.date.month != proposed.date.month ||
          b.date.day != proposed.date.day) {
        continue;
      }
      if (pStart >= b.endMinutes || pEnd <= b.startMinutes) {
        continue;
      }

      if (b.room == proposed.room) {
        conflicts.add(ConflictDetail(
          type: ConflictType.room,
          description:
              '${b.room} has a pending reservation for "${b.subject}" (${_fmtTime(b.startTime)}–${_fmtTime(b.endTime)})',
          isHard: false,
          conflictingEntity: b.room,
        ));
      }
    }

    return ConflictResult(conflicts: conflicts);
  }

  // ═══════════════════════════════════════════════════════════
  //  SUBMIT BOOKING
  // ═══════════════════════════════════════════════════════════

  /// Submit a booking request.
  ///
  /// • No conflicts → auto-approved.
  /// • Soft conflicts only + [forceSubmit] → pending for admin review.
  /// • Hard conflicts → throws.
  Future<Booking> submitBooking(Booking booking, {bool forceSubmit = false}) async {
    final result = checkAllConflicts(booking);

    if (result.hasHardConflicts) {
      throw BookingConflictException(
        'This booking has hard conflicts that cannot be overridden.',
        result,
      );
    }

    BookingStatus targetStatus;
    if (!result.hasConflicts) {
      targetStatus = BookingStatus.approved;
    } else if (forceSubmit) {
      targetStatus = BookingStatus.pending;
    } else {
      throw BookingConflictException(
        'Conflicts detected. Review them and force-submit if needed.',
        result,
      );
    }

    final finalBooking = booking.copyWith(status: targetStatus);
    final saved = await _db.submitBookingRequest(finalBooking);
    notifyListeners();
    return saved;
  }

  // ═══════════════════════════════════════════════════════════
  //  ADMIN ACTIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> approveBooking(String bookingId, String adminId) async {
    await _db.approveBooking(bookingId, adminId);
    notifyListeners();
  }

  Future<void> rejectBooking(String bookingId, String adminId, {String? reason}) async {
    await _db.rejectBooking(bookingId, adminId, reason: reason);
    notifyListeners();
  }

  // ─── formatting helper ────────────────────────────────────
  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

// ═══════════════════════════════════════════════════════════
//  CUSTOM EXCEPTION
// ═══════════════════════════════════════════════════════════

class BookingConflictException implements Exception {
  final String message;
  final ConflictResult conflicts;

  BookingConflictException(this.message, this.conflicts);

  @override
  String toString() => message;
}
