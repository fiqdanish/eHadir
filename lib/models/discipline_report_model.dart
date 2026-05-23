enum SeverityLevel { ringan, sederhana, serius }

extension SeverityLevelExtension on SeverityLevel {
  String get label {
    switch (this) {
      case SeverityLevel.ringan:
        return 'Ringan';
      case SeverityLevel.sederhana:
        return 'Sederhana';
      case SeverityLevel.serius:
        return 'Serius';
    }
  }
}

class DisciplineReportModel {
  final String id;
  final String studentName;
  final String studentId;
  final String issueDescription;
  final SeverityLevel severityLevel;
  final String program;      // Program of the reporting lecturer → routes report
  final String reportedBy;   // lecturer's uid
  final String reportedByName;
  final DateTime reportedAt;

  DisciplineReportModel({
    required this.id,
    required this.studentName,
    required this.studentId,
    required this.issueDescription,
    required this.severityLevel,
    required this.program,
    required this.reportedBy,
    required this.reportedByName,
    required this.reportedAt,
  });
}
