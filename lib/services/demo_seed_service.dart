import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance_record.dart';
import '../models/discipline_report_model.dart';

/// One-tap "seed demo data" used to fill Module 3 with realistic content
/// for a presentation: 5 [ClassAttendance] documents across two programs
/// plus 8 [DisciplineReportModel] documents covering every severity and
/// status the UI can render.
///
/// Idempotent — every doc gets a deterministic id (prefixed `demo_*`) so
/// re-running replaces, never duplicates.
class DemoSeedService {
  DemoSeedService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String dcp = 'DCP — Diploma Kompetensi Elektrik (Kuasa)';
  static const String dgs = 'DGS — Diploma Teknologi Kejuruteraan Gas';

  Future<DemoSeedResult> seedAll() async {
    final attendanceCount = await _seedAttendance();
    final reportsCount = await _seedReports();
    return DemoSeedResult(
      attendanceClasses: attendanceCount,
      disciplineReports: reportsCount,
    );
  }

  /// Wipes only the demo docs (those with id starting `demo_`) so the
  /// presenter can return Firestore to a clean state afterwards.
  Future<DemoSeedResult> clearAll() async {
    int aCount = 0;
    int rCount = 0;

    final attSnap = await _db.collection('classAttendance').get();
    for (final d in attSnap.docs) {
      if (d.id.startsWith('demo_')) {
        await d.reference.delete();
        aCount++;
      }
    }
    final repSnap = await _db.collection('disciplineReports').get();
    for (final d in repSnap.docs) {
      if (d.id.startsWith('demo_')) {
        await d.reference.delete();
        rCount++;
      }
    }
    return DemoSeedResult(
      attendanceClasses: aCount,
      disciplineReports: rCount,
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  ATTENDANCE — 5 class docs
  // ═══════════════════════════════════════════════════════════

  Future<int> _seedAttendance() async {
    // H/T/MC/CK/'' — 14 weeks per row.
    // Mix gives every percentage tier (<80, <90, <95, 100) some members.
    final classes = <_ClassSeed>[
      // ── DCP, Ts. Choh — high-attendance class
      _ClassSeed(
        docId: 'demo_SE_DCP_1A',
        subjectCode: 'DEV10043',
        subjectName: 'Software Engineering',
        studentClass: 'DCP 1A',
        program: dcp,
        lecturerId: 'u1',
        lecturerName: 'Ts. Choh Jing Yi',
        weeks: {
          's1': _w(['H', 'H', 'T', 'H', 'H', 'H', 'H']),
          's2': _w(['H', 'H', 'H', 'H', 'H', 'H', 'H']),
          's6': _w(['H', 'T', 'T', 'H', 'H', 'T', 'H']),
        },
      ),
      // ── DCP, Ts. Choh — middling class
      _ClassSeed(
        docId: 'demo_WD_DCP_1A',
        subjectCode: 'DEV20015',
        subjectName: 'Web Development',
        studentClass: 'DCP 1A',
        program: dcp,
        lecturerId: 'u1',
        lecturerName: 'Ts. Choh Jing Yi',
        weeks: {
          's1': _w(['H', 'T', 'H', 'H', 'MC', 'H', 'H']),
          's2': _w(['H', 'H', 'H', 'T', 'H', 'H', 'H']),
          's6': _w(['T', 'T', 'T', 'H', 'T', 'H', 'T']),
        },
      ),
      // ── DCP, fictional second lecturer so the KJ "Prestasi Pensyarah"
      //    ranking actually has two rows.
      _ClassSeed(
        docId: 'demo_MA_DCP_1A',
        subjectCode: 'DEV30021',
        subjectName: 'Mobile Application Development',
        studentClass: 'DCP 1A',
        program: dcp,
        lecturerId: 'u_demo_pn_norhayati',
        lecturerName: 'Pn. Norhayati binti Ahmad',
        weeks: {
          's1': _w(['H', 'H', 'H', 'H', 'H', 'H', 'H']),
          's2': _w(['H', 'T', 'H', 'H', 'H', 'H', 'H']),
          's6': _w(['H', 'H', 'T', 'H', 'H', 'H', 'T']),
        },
      ),
      // ── DGS, Dr. Afif — decent class
      _ClassSeed(
        docId: 'demo_DB_DGS_1A',
        subjectCode: 'DEV20012',
        subjectName: 'Database Systems',
        studentClass: 'DGS 1A',
        program: dgs,
        lecturerId: 'u2',
        lecturerName: 'Dr. Afif Shaqir',
        weeks: {
          's3': _w(['H', 'H', 'H', 'H', 'H', 'H', 'T']),
          's4': _w(['H', 'MC', 'H', 'H', 'H', 'T', 'H']),
          's7': _w(['H', 'H', 'H', 'T', 'H', 'H', 'T']),
        },
      ),
      // ── DGS, Prof. Irfan — weaker class, two students at risk
      _ClassSeed(
        docId: 'demo_NS_DGS_1A',
        subjectCode: 'DEV30009',
        subjectName: 'Network Security',
        studentClass: 'DGS 1A',
        program: dgs,
        lecturerId: 'u7',
        lecturerName: 'Prof. Irfan',
        weeks: {
          's3': _w(['H', 'T', 'T', 'H', 'T', 'H', 'H']),
          's4': _w(['T', 'T', 'H', 'T', 'H', 'T', 'T']),
          's7': _w(['H', 'H', 'H', 'H', 'H', 'H', 'H']),
        },
      ),
    ];

    for (final c in classes) {
      final ca = ClassAttendance(
        subjectCode: c.subjectCode,
        subjectName: c.subjectName,
        studentClass: c.studentClass,
        program: c.program,
        lecturerId: c.lecturerId,
        lecturerName: c.lecturerName,
        weeks: c.weeks,
        updatedAt: DateTime.now(),
      );
      await _db
          .collection('classAttendance')
          .doc(c.docId)
          .set(ca.toFirestore());
    }
    return classes.length;
  }

  /// Pads a partial week list to the full 14-week semester.
  static List<String> _w(List<String> partial) {
    return [
      ...partial,
      ...List<String>.filled(
          ClassAttendance.weeksPerSemester - partial.length, ''),
    ];
  }

  // ═══════════════════════════════════════════════════════════
  //  DISCIPLINE — 8 reports
  // ═══════════════════════════════════════════════════════════

  Future<int> _seedReports() async {
    final now = DateTime.now();
    final reports = <_ReportSeed>[
      // ── DCP ────────────────────────────────────────────
      _ReportSeed(
        id: 'demo_rpt_dcp_1',
        studentName: 'Ali bin Abu',
        studentId: 's1',
        studentClass: 'DCP 1A',
        description:
            'Pelajar didapati ponteng kelas Software Engineering pada M3 '
            'tanpa sebab munasabah. Telah diberikan teguran lisan.',
        severity: SeverityLevel.serius,
        status: ReportStatus.reviewed,
        program: dcp,
        reportedBy: 'u1',
        reportedByName: 'Ts. Choh Jing Yi',
        daysAgo: 5,
        reviewedBy: 'u4',
        reviewedByName: 'En. Ahmad Razak',
      ),
      _ReportSeed(
        id: 'demo_rpt_dcp_2',
        studentName: 'Muhammad Haziq',
        studentId: 's6',
        studentClass: 'DCP 1A',
        description:
            'Datang lewat ke kelas Web Development sebanyak 4 kali berturut '
            'pada minggu lepas. Mengganggu pelajar lain.',
        severity: SeverityLevel.sederhana,
        status: ReportStatus.pending,
        program: dcp,
        reportedBy: 'u1',
        reportedByName: 'Ts. Choh Jing Yi',
        daysAgo: 2,
      ),
      _ReportSeed(
        id: 'demo_rpt_dcp_3',
        studentName: 'Nurul Aisyah',
        studentId: 's2',
        studentClass: 'DCP 1A',
        description:
            'Tidak membawa peralatan amali yang diperlukan dan menggunakan '
            'telefon dalam kelas amali Mobile App Development.',
        severity: SeverityLevel.ringan,
        status: ReportStatus.resolved,
        program: dcp,
        reportedBy: 'u_demo_pn_norhayati',
        reportedByName: 'Pn. Norhayati binti Ahmad',
        daysAgo: 9,
        reviewedBy: 'u4',
        reviewedByName: 'En. Ahmad Razak',
        resolvedBy: 'u5',
        resolvedByName: 'Dr. Farah Nadia',
        actionNote: 'Pelajar dimaklumkan & telah memohon maaf.',
      ),
      _ReportSeed(
        id: 'demo_rpt_dcp_4',
        studentName: 'Muhammad Haziq',
        studentId: 's6',
        studentClass: 'DCP 1A',
        description:
            'Kehadiran di bawah 50% bagi Web Development. Tidak hadir 3 '
            'sesi berturut tanpa MC. Tindakan lanjut perlu diambil.',
        severity: SeverityLevel.serius,
        status: ReportStatus.escalated,
        program: dcp,
        reportedBy: 'u1',
        reportedByName: 'Ts. Choh Jing Yi',
        daysAgo: 12,
        reviewedBy: 'u4',
        reviewedByName: 'En. Ahmad Razak',
        resolvedBy: 'u5',
        resolvedByName: 'Dr. Farah Nadia',
        actionNote: 'Eskalasi kepada Timbalan Pengarah Akademik.',
      ),
      // ── DGS ────────────────────────────────────────────
      _ReportSeed(
        id: 'demo_rpt_dgs_1',
        studentName: 'Tan Wei Ming',
        studentId: 's3',
        studentClass: 'DGS 1A',
        description:
            'Tidak menghantar tugasan Database Systems sebanyak 2 kali. '
            'Memerlukan kaunseling akademik.',
        severity: SeverityLevel.sederhana,
        status: ReportStatus.reviewed,
        program: dgs,
        reportedBy: 'u2',
        reportedByName: 'Dr. Afif Shaqir',
        daysAgo: 3,
        reviewedBy: 'u_demo_kp_dgs',
        reviewedByName: 'En. Faizal bin Ismail',
      ),
      _ReportSeed(
        id: 'demo_rpt_dgs_2',
        studentName: 'Raj Kumar',
        studentId: 's4',
        studentClass: 'DGS 1A',
        description:
            'Bergaduh dengan pelajar lain di luar makmal selepas waktu '
            'Network Security. Insiden direkodkan oleh pengawal keselamatan.',
        severity: SeverityLevel.serius,
        status: ReportStatus.pending,
        program: dgs,
        reportedBy: 'u7',
        reportedByName: 'Prof. Irfan',
        daysAgo: 1,
      ),
      _ReportSeed(
        id: 'demo_rpt_dgs_3',
        studentName: 'Siti Rahim',
        studentId: 's7',
        studentClass: 'DGS 1A',
        description:
            'Bercakap dengan kuat dan mengganggu sesi Database Systems. '
            'Diberikan amaran lisan dalam kelas.',
        severity: SeverityLevel.ringan,
        status: ReportStatus.reviewed,
        program: dgs,
        reportedBy: 'u2',
        reportedByName: 'Dr. Afif Shaqir',
        daysAgo: 6,
        reviewedBy: 'u_demo_kp_dgs',
        reviewedByName: 'En. Faizal bin Ismail',
      ),
      _ReportSeed(
        id: 'demo_rpt_dgs_4',
        studentName: 'Raj Kumar',
        studentId: 's4',
        studentClass: 'DGS 1A',
        description:
            'Lewat menyertai kelas Network Security online sebanyak 3 kali. '
            'Memberi alasan masalah internet.',
        severity: SeverityLevel.ringan,
        status: ReportStatus.resolved,
        program: dgs,
        reportedBy: 'u7',
        reportedByName: 'Prof. Irfan',
        daysAgo: 14,
        reviewedBy: 'u_demo_kp_dgs',
        reviewedByName: 'En. Faizal bin Ismail',
        resolvedBy: 'u_demo_kj_elektrik',
        resolvedByName: 'Pn. Salina binti Othman',
        actionNote: 'Pelajar dimaklumkan & telah membuat penambahbaikan.',
      ),
    ];

    for (final r in reports) {
      final reportedAt = now.subtract(Duration(days: r.daysAgo));
      final data = <String, dynamic>{
        'studentName': r.studentName,
        'studentId': r.studentId,
        'studentClass': r.studentClass,
        'issueDescription': r.description,
        'severityLevel': r.severity.code,
        'status': r.status.code,
        'program': r.program,
        'reportedBy': r.reportedBy,
        'reportedByName': r.reportedByName,
        'reportedAt': Timestamp.fromDate(reportedAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (r.reviewedBy != null) {
        data['reviewedBy'] = r.reviewedBy;
        data['reviewedByName'] = r.reviewedByName;
        data['reviewedAt'] =
            Timestamp.fromDate(reportedAt.add(const Duration(days: 1)));
      }
      if (r.resolvedBy != null) {
        data['resolvedBy'] = r.resolvedBy;
        data['resolvedByName'] = r.resolvedByName;
        data['resolvedAt'] =
            Timestamp.fromDate(reportedAt.add(const Duration(days: 2)));
        if (r.actionNote != null) data['actionNote'] = r.actionNote;
      }
      await _db.collection('disciplineReports').doc(r.id).set(data);
    }
    return reports.length;
  }
}

class DemoSeedResult {
  final int attendanceClasses;
  final int disciplineReports;
  const DemoSeedResult({
    required this.attendanceClasses,
    required this.disciplineReports,
  });
}

class _ClassSeed {
  final String docId;
  final String subjectCode;
  final String subjectName;
  final String studentClass;
  final String program;
  final String lecturerId;
  final String lecturerName;
  final Map<String, List<String>> weeks;

  const _ClassSeed({
    required this.docId,
    required this.subjectCode,
    required this.subjectName,
    required this.studentClass,
    required this.program,
    required this.lecturerId,
    required this.lecturerName,
    required this.weeks,
  });
}

class _ReportSeed {
  final String id;
  final String studentName;
  final String studentId;
  final String studentClass;
  final String description;
  final SeverityLevel severity;
  final ReportStatus status;
  final String program;
  final String reportedBy;
  final String reportedByName;
  final int daysAgo;
  final String? reviewedBy;
  final String? reviewedByName;
  final String? resolvedBy;
  final String? resolvedByName;
  final String? actionNote;

  const _ReportSeed({
    required this.id,
    required this.studentName,
    required this.studentId,
    required this.studentClass,
    required this.description,
    required this.severity,
    required this.status,
    required this.program,
    required this.reportedBy,
    required this.reportedByName,
    required this.daysAgo,
    this.reviewedBy,
    this.reviewedByName,
    this.resolvedBy,
    this.resolvedByName,
    this.actionNote,
  });
}

final demoSeedServiceProvider =
    Provider<DemoSeedService>((ref) => DemoSeedService());
