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

  /// Same 100%-down model as [ClassAttendance.percentageFor]: start at 100%,
  /// each `T` deducts 1/14, MC/CK/blank don't deduct.
  double getAttendancePercentage(String subjectId) {
    final weeks = attendanceBySubject[subjectId];
    if (weeks == null || weeks.isEmpty) return 100.0;
    const semesterWeeks = 14;
    final absent = weeks.where((w) => w == 'T').length;
    final pct = (1 - absent / semesterWeeks) * 100;
    return pct.clamp(0.0, 100.0);
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
