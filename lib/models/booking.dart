import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed booking model for Module 6.
///
/// Fields stored in the `bookings` Firestore collection:
///   - `id`          : Document ID (auto-generated)
///   - `subjectName` : Name of the subject
///   - `lecturerId`  : UID of the lecturer who booked
///   - `lecturerName`: Display name of the lecturer
///   - `roomId`      : Room name (e.g. "Bilik Kuliah A1")
///   - `date`        : Firestore Timestamp (normalised to midnight)
///   - `startTime`   : int — minutes from midnight (e.g. 09:00 = 540)
///   - `endTime`     : int — minutes from midnight (e.g. 11:00 = 660)
///   - `subjectCode` : Subject code (e.g. "SECJ1013")
///   - `studentClass`: Student class/group (e.g. "DED 1A")
///   - `program`     : Program name (e.g. "DCP — Diploma Kompetensi Elektrik (Kuasa)")
class FirestoreBooking {
  final String id;
  final String subjectName;
  final String lecturerId;
  final String lecturerName;
  final String roomId;
  final DateTime date;
  final int startTime; // minutes from midnight
  final int endTime;   // minutes from midnight
  final String subjectCode;
  final String studentClass;
  final String program;

  FirestoreBooking({
    required this.id,
    required this.subjectName,
    required this.lecturerId,
    required this.lecturerName,
    required this.roomId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.subjectCode,
    required this.studentClass,
    required this.program,
  });

  /// Convert a Firestore document snapshot → [FirestoreBooking].
  factory FirestoreBooking.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FirestoreBooking(
      id: doc.id,
      subjectName: d['subjectName'] ?? '',
      lecturerId: d['lecturerId'] ?? '',
      lecturerName: d['lecturerName'] ?? '',
      roomId: d['roomId'] ?? '',
      date: (d['date'] as Timestamp).toDate(),
      startTime: d['startTime'] ?? 0,
      endTime: d['endTime'] ?? 0,
      subjectCode: d['subjectCode'] ?? '',
      studentClass: d['studentClass'] ?? '',
      program: d['program'] ?? '',
    );
  }

  /// Convert this booking → Firestore-compatible map.
  Map<String, dynamic> toFirestore() => {
        'subjectName': subjectName,
        'lecturerId': lecturerId,
        'lecturerName': lecturerName,
        'roomId': roomId,
        'date': Timestamp.fromDate(
          DateTime(date.year, date.month, date.day), // normalise to midnight
        ),
        'startTime': startTime,
        'endTime': endTime,
        'subjectCode': subjectCode,
        'studentClass': studentClass,
        'program': program,
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Human-readable time range, e.g. "09:00 – 11:00".
  String get timeRangeFormatted {
    String fmt(int mins) {
      final h = (mins ~/ 60).toString().padLeft(2, '0');
      final m = (mins % 60).toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${fmt(startTime)} – ${fmt(endTime)}';
  }
}
