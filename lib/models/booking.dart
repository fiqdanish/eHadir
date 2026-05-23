import 'package:flutter/material.dart';
import 'timetable.dart';

enum BookingStatus { pending, approved, rejected }
enum BookingType { replacement, reschedule }

class Booking {
  final String id;
  final String lecturerId;
  final String? originalTimetableId; 
  final BookingType type;
  
  final String subject;
  final String cohort;
  final String room;
  final DateTime date; 
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  
  final BookingStatus status;
  final DateTime createdAt;

  // Review / approval workflow fields
  final String? reviewedBy;       // Admin user ID
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? remarks;          // Lecturer's notes

  int get startMinutes => startTime.hour * 60 + startTime.minute;
  int get endMinutes => endTime.hour * 60 + endTime.minute;

  Booking({
    required this.id,
    required this.lecturerId,
    this.originalTimetableId,
    required this.type,
    required this.subject,
    required this.cohort,
    required this.room,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    this.remarks,
  });

  Booking copyWith({
    String? id,
    String? lecturerId,
    String? originalTimetableId,
    BookingType? type,
    String? subject,
    String? cohort,
    String? room,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    BookingStatus? status,
    DateTime? createdAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
    String? remarks,
  }) {
    return Booking(
      id: id ?? this.id,
      lecturerId: lecturerId ?? this.lecturerId,
      originalTimetableId: originalTimetableId ?? this.originalTimetableId,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      cohort: cohort ?? this.cohort,
      room: room ?? this.room,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      remarks: remarks ?? this.remarks,
    );
  }

  bool overlapsWith(Booking other) {
    if (date.year != other.date.year || 
        date.month != other.date.month || 
        date.day != other.date.day) {
      return false;
    }
    return startMinutes < other.endMinutes && endMinutes > other.startMinutes;
  }

  // Helper: check overlap against a Master Timetable slot for the same date
  bool overlapsWithTimetable(Timetable timetable, DateTime checkDate) {
    if (timetable.dayOfWeek != checkDate.weekday) return false;
    if (date.year != checkDate.year || 
        date.month != checkDate.month || 
        date.day != checkDate.day) {
      return false;
    }
    return startMinutes < timetable.endMinutes && endMinutes > timetable.startMinutes;
  }

  Timetable toTimetable() {
    return Timetable(
      id: 'booking_$id',
      subject: subject,
      lecturerId: lecturerId,
      room: room,
      cohort: cohort,
      dayOfWeek: date.weekday,
      startTime: startTime,
      endTime: endTime,
    );
  }

  String get statusLabel {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending Review';
      case BookingStatus.approved:
        return 'Approved';
      case BookingStatus.rejected:
        return 'Rejected';
    }
  }

  String get timeRangeFormatted {
    String fmt(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${fmt(startTime)} – ${fmt(endTime)}';
  }
}
