import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assignment1/models/booking.dart';
import 'package:assignment1/models/conflict_result.dart';
import 'package:assignment1/services/mock_db_service.dart';
import 'package:assignment1/services/booking_service.dart';

void main() {
  late MockDatabaseService db;
  late BookingService bookingService;

  setUp(() {
    db = MockDatabaseService();
    bookingService = BookingService(db);
  });

  group('Conflict Detection Engine', () {
    test('No conflicts for a free slot', () {
      // Saturday at 9am in Lab 3 — no timetable conflict
      final booking = Booking(
        id: '',
        lecturerId: 'u1',
        type: BookingType.replacement,
        subject: 'Software Engineering',
        cohort: 'CS101',
        room: 'Lab 3',
        date: _nextWeekday(6), // Saturday
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
      );

      final result = bookingService.checkAllConflicts(booking);
      expect(result.hasConflicts, false);
    });

    test('Room conflict detected against master timetable', () {
      // Monday 9-11am Lab 1 — conflicts with t1
      final booking = Booking(
        id: '',
        lecturerId: 'u7', // different lecturer
        type: BookingType.replacement,
        subject: 'Test Subject',
        cohort: 'IT201',
        room: 'Lab 1', // Same room as t1
        date: _nextWeekday(1), // Monday
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
      );

      final result = bookingService.checkAllConflicts(booking);
      expect(result.hasConflicts, true);
      expect(result.hasHardConflicts, true);
      expect(result.conflicts.any((c) => c.type == ConflictType.room), true);
    });

    test('Lecturer schedule conflict detected', () {
      // Monday 9-11am Lab 3, same lecturer (u1) — conflicts with t1
      final booking = Booking(
        id: '',
        lecturerId: 'u1', // Same lecturer as t1
        type: BookingType.replacement,
        subject: 'Test Subject',
        cohort: 'IT201',
        room: 'Lab 3', // Different room
        date: _nextWeekday(1), // Monday
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
      );

      final result = bookingService.checkAllConflicts(booking);
      expect(result.hasConflicts, true);
      expect(result.conflicts.any((c) => c.type == ConflictType.lecturer), true);
    });

    test('Cohort conflict detected', () {
      // Monday 9-11am Bilik Kuliah 1, same cohort (CS101) — conflicts with t1
      final booking = Booking(
        id: '',
        lecturerId: 'u7', // Different lecturer
        type: BookingType.replacement,
        subject: 'Test Subject',
        cohort: 'CS101', // Same cohort as t1
        room: 'Bilik Kuliah 1', // Different room
        date: _nextWeekday(1), // Monday
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
      );

      final result = bookingService.checkAllConflicts(booking);
      expect(result.hasConflicts, true);
      expect(result.conflicts.any((c) => c.type == ConflictType.cohort), true);
    });

    test('Auto-approve clean booking', () async {
      final booking = Booking(
        id: '',
        lecturerId: 'u1',
        type: BookingType.replacement,
        subject: 'Software Engineering',
        cohort: 'CS101',
        room: 'Tutorial Room 1',
        date: _nextWeekday(6), // Saturday — free
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
      );

      final saved = await bookingService.submitBooking(booking);
      expect(saved.status, BookingStatus.approved);
    });

    test('Hard conflict throws and blocks submission', () async {
      final booking = Booking(
        id: '',
        lecturerId: 'u7',
        type: BookingType.replacement,
        subject: 'Test',
        cohort: 'IT201',
        room: 'Lab 1', // Conflicts with t1 on Monday
        date: _nextWeekday(1),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(
        () => bookingService.submitBooking(booking),
        throwsA(isA<BookingConflictException>()),
      );
    });
  });

  group('Approval Workflow', () {
    test('Approve pending booking', () async {
      // First, submit a force-submit booking with soft conflicts
      final booking = Booking(
        id: '',
        lecturerId: 'u1',
        type: BookingType.replacement,
        subject: 'Software Engineering',
        cohort: 'CS101',
        room: 'Lab 3', // Different room but same lecturer on Monday 9-11
        date: _nextWeekday(1),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
      );

      final saved = await bookingService.submitBooking(booking, forceSubmit: true);
      expect(saved.status, BookingStatus.pending);

      // Approve it
      await bookingService.approveBooking(saved.id, 'u3');
      final approved = db.allBookings.firstWhere((b) => b.id == saved.id);
      expect(approved.status, BookingStatus.approved);
      expect(approved.reviewedBy, 'u3');
    });

    test('Reject pending booking with reason', () async {
      final booking = Booking(
        id: '',
        lecturerId: 'u1',
        type: BookingType.replacement,
        subject: 'Software Engineering',
        cohort: 'CS101',
        room: 'Lab 3',
        date: _nextWeekday(1),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
      );

      final saved = await bookingService.submitBooking(booking, forceSubmit: true);
      await bookingService.rejectBooking(saved.id, 'u3', reason: 'Room under maintenance');

      final rejected = db.allBookings.firstWhere((b) => b.id == saved.id);
      expect(rejected.status, BookingStatus.rejected);
      expect(rejected.rejectionReason, 'Room under maintenance');
    });
  });

  group('Room Availability', () {
    test('Lab 1 is occupied Monday 9-11', () {
      final occupied = db.isRoomOccupied(
        'Lab 1',
        _nextWeekday(1),
        const TimeOfDay(hour: 9, minute: 0),
        const TimeOfDay(hour: 11, minute: 0),
      );
      expect(occupied, true);
    });

    test('Lab 3 is free Monday 9-11 (except for u1 on Wed)', () {
      final occupied = db.isRoomOccupied(
        'Tutorial Room 1',
        _nextWeekday(1),
        const TimeOfDay(hour: 9, minute: 0),
        const TimeOfDay(hour: 11, minute: 0),
      );
      expect(occupied, false);
    });

    test('Available rooms excludes occupied rooms', () {
      final available = db.getAvailableRooms(
        _nextWeekday(1),
        const TimeOfDay(hour: 9, minute: 0),
        const TimeOfDay(hour: 11, minute: 0),
      );
      // Lab 1 and Lab 2 are occupied on Monday 9-11
      expect(available.any((r) => r.name == 'Lab 1'), false);
      expect(available.any((r) => r.name == 'Tutorial Room 1'), true);
    });
  });
}

/// Helper: get the next occurrence of a given weekday (1=Mon, 7=Sun).
DateTime _nextWeekday(int weekday) {
  final now = DateTime.now();
  int daysAhead = weekday - now.weekday;
  if (daysAhead <= 0) {
    daysAhead += 7;
  }
  final date = now.add(Duration(days: daysAhead));
  return DateTime(date.year, date.month, date.day);
}
