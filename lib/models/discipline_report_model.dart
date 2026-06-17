import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum SeverityLevel { ringan, sederhana, serius }

extension SeverityLevelExtension on SeverityLevel {
  String get label {
    switch (this) {
      case SeverityLevel.ringan:    return 'Ringan';
      case SeverityLevel.sederhana: return 'Sederhana';
      case SeverityLevel.serius:    return 'Serius';
    }
  }

  String get code {
    switch (this) {
      case SeverityLevel.ringan:    return 'ringan';
      case SeverityLevel.sederhana: return 'sederhana';
      case SeverityLevel.serius:    return 'serius';
    }
  }

  Color get color {
    switch (this) {
      case SeverityLevel.ringan:    return const Color(0xFF10B981); // emerald
      case SeverityLevel.sederhana: return const Color(0xFFF59E0B); // amber
      case SeverityLevel.serius:    return const Color(0xFFEF4444); // red
    }
  }

  static SeverityLevel fromCode(String? code) {
    switch (code) {
      case 'sederhana': return SeverityLevel.sederhana;
      case 'serius':    return SeverityLevel.serius;
      default:          return SeverityLevel.ringan;
    }
  }
}

/// Workflow status for a discipline report.
///   pending   → freshly filed by Pensyarah, awaiting KP review
///   reviewed  → KP acknowledged; passes to KJ for action
///   resolved  → KJ closed the case
///   escalated → KJ flagged for higher action (e.g. HEP / disciplinary committee)
enum ReportStatus { pending, reviewed, resolved, escalated }

extension ReportStatusExtension on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.pending:   return 'Menunggu';
      case ReportStatus.reviewed:  return 'Disemak';
      case ReportStatus.resolved:  return 'Selesai';
      case ReportStatus.escalated: return 'Dieskalasi';
    }
  }

  String get code {
    switch (this) {
      case ReportStatus.pending:   return 'pending';
      case ReportStatus.reviewed:  return 'reviewed';
      case ReportStatus.resolved:  return 'resolved';
      case ReportStatus.escalated: return 'escalated';
    }
  }

  Color get color {
    switch (this) {
      case ReportStatus.pending:   return const Color(0xFFF59E0B); // amber
      case ReportStatus.reviewed:  return const Color(0xFF3B82F6); // blue
      case ReportStatus.resolved:  return const Color(0xFF10B981); // emerald
      case ReportStatus.escalated: return const Color(0xFFEF4444); // red
    }
  }

  IconData get icon {
    switch (this) {
      case ReportStatus.pending:   return Icons.schedule_rounded;
      case ReportStatus.reviewed:  return Icons.fact_check_rounded;
      case ReportStatus.resolved:  return Icons.check_circle_rounded;
      case ReportStatus.escalated: return Icons.priority_high_rounded;
    }
  }

  static ReportStatus fromCode(String? code) {
    switch (code) {
      case 'reviewed':  return ReportStatus.reviewed;
      case 'resolved':  return ReportStatus.resolved;
      case 'escalated': return ReportStatus.escalated;
      default:          return ReportStatus.pending;
    }
  }
}

class DisciplineReportModel {
  final String id;
  final String studentName;
  final String studentId;
  final String studentClass;
  final String issueDescription;
  final SeverityLevel severityLevel;
  final ReportStatus status;
  final String program;       // Program of the reporting lecturer → routes report
  final String reportedBy;    // lecturer's uid
  final String reportedByName;
  final DateTime reportedAt;
  // KP review
  final String? reviewedBy;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  // KJ resolution / escalation
  final String? resolvedBy;
  final String? resolvedByName;
  final DateTime? resolvedAt;
  final String? actionNote;
  final DateTime? updatedAt;

  const DisciplineReportModel({
    required this.id,
    required this.studentName,
    required this.studentId,
    required this.studentClass,
    required this.issueDescription,
    required this.severityLevel,
    required this.program,
    required this.reportedBy,
    required this.reportedByName,
    required this.reportedAt,
    this.status = ReportStatus.pending,
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
    this.resolvedBy,
    this.resolvedByName,
    this.resolvedAt,
    this.actionNote,
    this.updatedAt,
  });

  DisciplineReportModel copyWith({
    String? studentName,
    String? studentId,
    String? studentClass,
    String? issueDescription,
    SeverityLevel? severityLevel,
    ReportStatus? status,
    String? program,
    String? reportedBy,
    String? reportedByName,
    DateTime? reportedAt,
    String? reviewedBy,
    String? reviewedByName,
    DateTime? reviewedAt,
    String? resolvedBy,
    String? resolvedByName,
    DateTime? resolvedAt,
    String? actionNote,
    DateTime? updatedAt,
  }) {
    return DisciplineReportModel(
      id: id,
      studentName: studentName ?? this.studentName,
      studentId: studentId ?? this.studentId,
      studentClass: studentClass ?? this.studentClass,
      issueDescription: issueDescription ?? this.issueDescription,
      severityLevel: severityLevel ?? this.severityLevel,
      status: status ?? this.status,
      program: program ?? this.program,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedByName: reportedByName ?? this.reportedByName,
      reportedAt: reportedAt ?? this.reportedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedByName: resolvedByName ?? this.resolvedByName,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      actionNote: actionNote ?? this.actionNote,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Firestore ────────────────────────────────────────────

  factory DisciplineReportModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DisciplineReportModel(
      id: doc.id,
      studentName: d['studentName'] ?? '',
      studentId: d['studentId'] ?? '',
      studentClass: d['studentClass'] ?? '',
      issueDescription: d['issueDescription'] ?? '',
      severityLevel: SeverityLevelExtension.fromCode(d['severityLevel'] as String?),
      status: ReportStatusExtension.fromCode(d['status'] as String?),
      program: d['program'] ?? '',
      reportedBy: d['reportedBy'] ?? '',
      reportedByName: d['reportedByName'] ?? '',
      reportedAt: (d['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedBy: d['reviewedBy'] as String?,
      reviewedByName: d['reviewedByName'] as String?,
      reviewedAt: (d['reviewedAt'] as Timestamp?)?.toDate(),
      resolvedBy: d['resolvedBy'] as String?,
      resolvedByName: d['resolvedByName'] as String?,
      resolvedAt: (d['resolvedAt'] as Timestamp?)?.toDate(),
      actionNote: d['actionNote'] as String?,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'studentName': studentName,
        'studentId': studentId,
        'studentClass': studentClass,
        'issueDescription': issueDescription,
        'severityLevel': severityLevel.code,
        'status': status.code,
        'program': program,
        'reportedBy': reportedBy,
        'reportedByName': reportedByName,
        'reportedAt': Timestamp.fromDate(reportedAt),
        if (reviewedBy != null) 'reviewedBy': reviewedBy,
        if (reviewedByName != null) 'reviewedByName': reviewedByName,
        if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
        if (resolvedBy != null) 'resolvedBy': resolvedBy,
        if (resolvedByName != null) 'resolvedByName': resolvedByName,
        if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
        if (actionNote != null) 'actionNote': actionNote,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
