import 'package:flutter/material.dart';

class ClassSlotModel {
  final String id;
  final String subjectName;
  final String roomId;       // room name, e.g. "Lab 1"
  final String lecturerId;   // Firebase uid of the lecturer
  final String lecturerName;
  final String program;      // e.g. "DGS"
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  ClassSlotModel({
    required this.id,
    required this.subjectName,
    required this.roomId,
    required this.lecturerId,
    required this.lecturerName,
    required this.program,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  int get startMinutes => startTime.hour * 60 + startTime.minute;
  int get endMinutes => endTime.hour * 60 + endTime.minute;

  String get timeRangeFormatted {
    String fmt(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${fmt(startTime)} – ${fmt(endTime)}';
  }
}
