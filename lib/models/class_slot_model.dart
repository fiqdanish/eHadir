import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassSlotModel {
  final String id;
  final String subjectName;
  final String subjectCode;    // e.g. "SECJ1013"
  final String studentClass;   // e.g. "DED 1A"
  final String roomId;         // room name, e.g. "Bilik Kuliah A1"
  final String lecturerId;     // Firebase uid of the lecturer
  final String lecturerName;
  final String program;        // e.g. "DGS"
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String bookingRef;     // Firestore ID of the linked `bookings` doc

  ClassSlotModel({
    required this.id,
    required this.subjectName,
    required this.subjectCode,
    required this.studentClass,
    required this.roomId,
    required this.lecturerId,
    required this.lecturerName,
    required this.program,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.bookingRef = '',
  });

  int get startMinutes => startTime.hour * 60 + startTime.minute;
  int get endMinutes => endTime.hour * 60 + endTime.minute;

  String get timeRangeFormatted {
    String fmt(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${fmt(startTime)} – ${fmt(endTime)}';
  }

  // ─── Firestore ────────────────────────────────────────────────

  /// Deserialise a Firestore document snapshot into a [ClassSlotModel].
  factory ClassSlotModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final startMin = (d['startTime'] as num?)?.toInt() ?? 0;
    final endMin   = (d['endTime']   as num?)?.toInt() ?? 0;
    return ClassSlotModel(
      id:           doc.id,
      subjectName:  d['subjectName']  as String? ?? '',
      subjectCode:  d['subjectCode']  as String? ?? '',
      studentClass: d['studentClass'] as String? ?? '',
      roomId:       d['roomId']       as String? ?? '',
      lecturerId:   d['lecturerId']   as String? ?? '',
      lecturerName: d['lecturerName'] as String? ?? '',
      program:      d['program']      as String? ?? '',
      date: (d['date'] as Timestamp).toDate(),
      startTime: TimeOfDay(hour: startMin ~/ 60, minute: startMin % 60),
      endTime:   TimeOfDay(hour: endMin   ~/ 60, minute: endMin   % 60),
      bookingRef:   d['bookingRef']   as String? ?? '',
    );
  }

  /// Serialise this model for Firestore storage.
  Map<String, dynamic> toFirestore() => {
    'subjectName':  subjectName,
    'subjectCode':  subjectCode,
    'studentClass': studentClass,
    'roomId':       roomId,
    'lecturerId':   lecturerId,
    'lecturerName': lecturerName,
    'program':      program,
    // Normalise date to midnight so Firestore date equality queries work
    'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
    'startTime': startMinutes,
    'endTime':   endMinutes,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
