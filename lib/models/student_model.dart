class StudentModel {
  final String id;
  final String name;
  final String program;
  /// Class group label, e.g. "DED 1A".
  final String studentClass;
  // Map<subjectId, List<14 week statuses>>
  // Status values: 'H' = Hadir, 'T' = Tidak Hadir, 'MC' = MC, 'CK' = Cuti
  // Kebenaran, '' = not taken.
  final Map<String, List<String>> attendanceBySubject;

  StudentModel({
    required this.id,
    required this.name,
    required this.program,
    this.studentClass = '',
    Map<String, List<String>>? attendanceBySubject,
  }) : attendanceBySubject = attendanceBySubject ?? {};

  double getAttendancePercentage(String subjectId) {
    final weeks = attendanceBySubject[subjectId];
    if (weeks == null || weeks.isEmpty) return 0.0;
    final taken = weeks.where((w) => w.isNotEmpty).length;
    if (taken == 0) return 0.0;
    final present = weeks.where((w) => w == 'H').length;
    return (present / taken) * 100;
  }

  double get overallAttendancePercentage {
    if (attendanceBySubject.isEmpty) return 100.0;
    double total = 0;
    for (final subjectId in attendanceBySubject.keys) {
      total += getAttendancePercentage(subjectId);
    }
    return total / attendanceBySubject.length;
  }

  StudentModel copyWithAttendance(
      String subjectId, int weekIndex, String status) {
    final updated = Map<String, List<String>>.from(attendanceBySubject);
    final weeks = List<String>.from(
        updated[subjectId] ?? List.filled(14, ''));
    if (weekIndex >= 0 && weekIndex < 14) {
      weeks[weekIndex] = status;
    }
    updated[subjectId] = weeks;
    return StudentModel(
      id: id,
      name: name,
      program: program,
      studentClass: studentClass,
      attendanceBySubject: updated,
    );
  }
}
