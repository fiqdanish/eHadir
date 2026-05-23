import 'package:flutter/material.dart';

class Timetable {
  final String id;
  final String subject;
  final String lecturerId;
  final String room;
  final String cohort; // e.g., "CS101"
  final int dayOfWeek; // 1 = Mon, 7 = Sun
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  int get startMinutes => startTime.hour * 60 + startTime.minute;
  int get endMinutes => endTime.hour * 60 + endTime.minute;

  Timetable({
    required this.id,
    required this.subject,
    required this.lecturerId,
    required this.room,
    required this.cohort,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  bool overlapsWith(Timetable other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    return startMinutes < other.endMinutes && endMinutes > other.startMinutes;
  }
}
