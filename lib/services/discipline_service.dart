import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/discipline_report_model.dart';
import '../models/user.dart';

/// Firestore-backed service for the Report Discipline Issue module (M2).
///
/// Storage layout — one document per report:
///   disciplineReports/{reportId}
///     studentId, studentName, studentClass, program,
///     issueDescription, severityLevel, status,
///     reportedBy, reportedByName, reportedAt,
///     reviewedBy?, reviewedByName?, reviewedAt?,
///     resolvedBy?, resolvedByName?, resolvedAt?,
///     actionNote?, updatedAt
///
/// Status workflow (enforced by guards before every write):
///   pending → reviewed (KP) → resolved | escalated (KJ)
class DisciplineService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'disciplineReports';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(_collection);

  // ─── Create ───────────────────────────────────────────────

  /// Submit a new discipline report (always starts as `pending`).
  Future<void> submitReport(DisciplineReportModel r) async {
    try {
      final fresh = r.copyWith(status: ReportStatus.pending);
      await _col.doc(r.id).set(fresh.toFirestore());
      notifyListeners();
    } catch (e) {
      debugPrint('DisciplineService.submitReport error: $e');
      rethrow;
    }
  }

  // ─── Update / Delete (Pensyarah, pending only) ───────────

  /// Update an existing report. Only allowed while `status == pending`.
  Future<void> updateReport(DisciplineReportModel r) async {
    final snap = await _col.doc(r.id).get();
    if (!snap.exists) {
      throw StateError('Laporan tidak dijumpai.');
    }
    final current = DisciplineReportModel.fromFirestore(snap);
    if (current.status != ReportStatus.pending) {
      throw StateError('Laporan ini telah disemak dan tidak boleh diubah.');
    }
    await _col.doc(r.id).set(r.toFirestore(), SetOptions(merge: true));
    notifyListeners();
  }

  /// Delete a report. Only allowed while `status == pending`.
  Future<void> deleteReport(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return;
    final current = DisciplineReportModel.fromFirestore(snap);
    if (current.status != ReportStatus.pending) {
      throw StateError('Laporan ini telah disemak dan tidak boleh dipadam.');
    }
    await _col.doc(id).delete();
    notifyListeners();
  }

  // ─── Status transitions ───────────────────────────────────

  /// KP marks a pending report as reviewed.
  Future<void> markReviewed(String id, AppUser kp) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) throw StateError('Laporan tidak dijumpai.');
    final current = DisciplineReportModel.fromFirestore(snap);
    if (current.status != ReportStatus.pending) {
      throw StateError('Hanya laporan berstatus Menunggu boleh disemak.');
    }
    await _col.doc(id).update({
      'status': ReportStatus.reviewed.code,
      'reviewedBy': kp.id,
      'reviewedByName': kp.name,
      'reviewedAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  /// KJ closes a reviewed report. Optional [note] explaining the action taken.
  Future<void> markResolved(String id, AppUser kj, {String? note}) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) throw StateError('Laporan tidak dijumpai.');
    final current = DisciplineReportModel.fromFirestore(snap);
    if (current.status != ReportStatus.reviewed) {
      throw StateError('Hanya laporan berstatus Disemak boleh diselesaikan.');
    }
    await _col.doc(id).update({
      'status': ReportStatus.resolved.code,
      'resolvedBy': kj.id,
      'resolvedByName': kj.name,
      'resolvedAt': Timestamp.fromDate(DateTime.now()),
      if (note != null && note.trim().isNotEmpty) 'actionNote': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  /// KJ escalates a reviewed report to higher authority. [note] is mandatory.
  Future<void> markEscalated(
    String id,
    AppUser kj, {
    required String note,
  }) async {
    if (note.trim().isEmpty) {
      throw ArgumentError('Catatan tindakan diperlukan untuk eskalasi.');
    }
    final snap = await _col.doc(id).get();
    if (!snap.exists) throw StateError('Laporan tidak dijumpai.');
    final current = DisciplineReportModel.fromFirestore(snap);
    if (current.status != ReportStatus.reviewed) {
      throw StateError('Hanya laporan berstatus Disemak boleh dieskalasi.');
    }
    await _col.doc(id).update({
      'status': ReportStatus.escalated.code,
      'resolvedBy': kj.id,
      'resolvedByName': kj.name,
      'resolvedAt': Timestamp.fromDate(DateTime.now()),
      'actionNote': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  // ─── Read ─────────────────────────────────────────────────

  /// Live stream of one report by id.
  Stream<DisciplineReportModel?> streamReport(String id) {
    return _col.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DisciplineReportModel.fromFirestore(doc);
    });
  }

  /// Pensyarah's own submitted reports, newest first.
  Stream<List<DisciplineReportModel>> streamByLecturer(String lecturerId) {
    return _col
        .where('reportedBy', isEqualTo: lecturerId)
        .snapshots()
        .map(_mapAndSort);
  }

  /// All reports tied to a program (KP feed).
  Stream<List<DisciplineReportModel>> streamByProgram(String program) {
    return _col
        .where('program', isEqualTo: program)
        .snapshots()
        .map(_mapAndSort);
  }

  /// All reports across every program (KJ / TPA feed).
  Stream<List<DisciplineReportModel>> streamAll() {
    return _col.snapshots().map(_mapAndSort);
  }

  List<DisciplineReportModel> _mapAndSort(QuerySnapshot snap) {
    final list = snap.docs.map(DisciplineReportModel.fromFirestore).toList();
    list.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    return list;
  }
}

final disciplineServiceProvider =
    ChangeNotifierProvider<DisciplineService>((ref) => DisciplineService());
