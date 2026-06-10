import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/discipline_report_model.dart';
import '../services/auth_service.dart';
import '../services/discipline_service.dart';
import '../screens/lecturer/lapor_disiplin_screen.dart';
import '../theme.dart';

enum DisciplineViewerRole { pensyarah, kp, kj }

/// Opens a modal bottom sheet showing the full report + the actions
/// available to [viewerRole] given the report's current status.
Future<void> showDisciplineReportDetail({
  required BuildContext context,
  required WidgetRef ref,
  required DisciplineReportModel report,
  required DisciplineViewerRole viewerRole,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportDetailSheet(report: report, viewerRole: viewerRole),
  );
}

class _ReportDetailSheet extends ConsumerWidget {
  final DisciplineReportModel report;
  final DisciplineViewerRole viewerRole;

  const _ReportDetailSheet({required this.report, required this.viewerRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: EHadirTheme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: EHadirTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: EdgeInsets.fromLTRB(
                    20, 16, 20, 24 + media.viewInsets.bottom),
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  _infoRow(
                    icon: Icons.school_rounded,
                    label: 'Pelajar',
                    value: '${report.studentName}'
                        '${report.studentClass.isNotEmpty ? '  ·  ${report.studentClass}' : ''}',
                  ),
                  _infoRow(
                    icon: Icons.person_rounded,
                    label: 'Dilapor oleh',
                    value: report.reportedByName,
                  ),
                  _infoRow(
                    icon: Icons.event_rounded,
                    label: 'Tarikh laporan',
                    value: DateFormat('dd MMM yyyy, HH:mm')
                        .format(report.reportedAt),
                  ),
                  _infoRow(
                    icon: Icons.school_outlined,
                    label: 'Program',
                    value: report.program,
                  ),
                  const SizedBox(height: 12),
                  _label('Keterangan Isu'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: EHadirTheme.surfaceLight,
                      borderRadius:
                          BorderRadius.circular(EHadirTheme.radiusMd),
                    ),
                    child: Text(
                      report.issueDescription,
                      style: const TextStyle(
                        color: EHadirTheme.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _label('Status Aliran Kerja'),
                  const SizedBox(height: 8),
                  _statusTimeline(),
                  if (report.actionNote != null &&
                      report.actionNote!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _label('Catatan Tindakan (Ketua Jabatan)'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: report.status.color.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(EHadirTheme.radiusMd),
                        border: Border.all(
                          color: report.status.color.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        report.actionNote!,
                        style: const TextStyle(
                          color: EHadirTheme.textPrimary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ..._actions(context, ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────

  Widget _header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: report.severityLevel.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
          ),
          child: Icon(
            Icons.gavel_rounded,
            color: report.severityLevel.color,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laporan Disiplin — ${report.severityLevel.label}',
                style: const TextStyle(
                  color: EHadirTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              _statusBadge(report.status),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Status timeline ──────────────────────────────────────

  Widget _statusTimeline() {
    final steps = <_TimelineStep>[
      _TimelineStep(
        label: 'Dihantar',
        sub: report.reportedByName,
        time: report.reportedAt,
        done: true,
        color: ReportStatus.pending.color,
        icon: Icons.send_rounded,
      ),
      _TimelineStep(
        label: 'Disemak oleh Ketua Program',
        sub: report.reviewedByName,
        time: report.reviewedAt,
        done: report.status != ReportStatus.pending,
        color: ReportStatus.reviewed.color,
        icon: ReportStatus.reviewed.icon,
      ),
      _TimelineStep(
        label: report.status == ReportStatus.escalated
            ? 'Dieskalasi oleh Ketua Jabatan'
            : 'Diselesaikan oleh Ketua Jabatan',
        sub: report.resolvedByName,
        time: report.resolvedAt,
        done: report.status == ReportStatus.resolved ||
            report.status == ReportStatus.escalated,
        color: report.status == ReportStatus.escalated
            ? ReportStatus.escalated.color
            : ReportStatus.resolved.color,
        icon: report.status == ReportStatus.escalated
            ? ReportStatus.escalated.icon
            : ReportStatus.resolved.icon,
      ),
    ];
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(step: steps[i], isLast: i == steps.length - 1),
      ],
    );
  }

  // ─── Actions per role ─────────────────────────────────────

  List<Widget> _actions(BuildContext context, WidgetRef ref) {
    switch (viewerRole) {
      case DisciplineViewerRole.pensyarah:
        if (report.status != ReportStatus.pending) {
          return [
            _infoNote(
              'Laporan ini telah disemak. Anda tidak boleh lagi mengubah atau memadamnya.',
            ),
          ];
        }
        return [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _onEdit(context),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Kemaskini'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _onDelete(context, ref),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Padam'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EHadirTheme.rejected,
                  ),
                ),
              ),
            ],
          ),
        ];

      case DisciplineViewerRole.kp:
        if (report.status != ReportStatus.pending) {
          return [
            _infoNote(
              report.status == ReportStatus.reviewed
                  ? 'Anda telah menyemak laporan ini. Menunggu tindakan Ketua Jabatan.'
                  : 'Laporan ini telah ditangani oleh Ketua Jabatan.',
            ),
          ];
        }
        return [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _onMarkReviewed(context, ref),
              icon: const Icon(Icons.fact_check_rounded, size: 18),
              label: const Text('Tandakan Disemak'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ReportStatus.reviewed.color,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ];

      case DisciplineViewerRole.kj:
        if (report.status == ReportStatus.pending) {
          return [
            _infoNote(
              'Menunggu Ketua Program menyemak laporan ini terlebih dahulu.',
            ),
          ];
        }
        if (report.status != ReportStatus.reviewed) {
          return [
            _infoNote(
              report.status == ReportStatus.escalated
                  ? 'Laporan ini telah dieskalasi.'
                  : 'Laporan ini telah diselesaikan.',
            ),
          ];
        }
        return [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _onResolve(context, ref),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Tandakan Selesai'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ReportStatus.resolved.color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _onEscalate(context, ref),
                  icon: const Icon(Icons.priority_high_rounded, size: 18),
                  label: const Text('Eskalasi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ReportStatus.escalated.color,
                    side: BorderSide(color: ReportStatus.escalated.color),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ];
    }
  }

  // ─── Action handlers ─────────────────────────────────────

  void _onEdit(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LaporDisiplinScreen(existing: report)),
    );
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Padam Laporan?'),
        content: const Text(
          'Tindakan ini tidak boleh diundur. Laporan akan dipadam terus dari sistem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: EHadirTheme.rejected,
            ),
            child: const Text('Padam'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(disciplineServiceProvider).deleteReport(report.id);
      if (!context.mounted) return;
      Navigator.pop(context);
      _snack(context, 'Laporan dipadam.', EHadirTheme.approved);
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, 'Gagal: $e', EHadirTheme.rejected);
    }
  }

  Future<void> _onMarkReviewed(BuildContext context, WidgetRef ref) async {
    final kp = ref.read(authProvider).currentUser!;
    try {
      await ref.read(disciplineServiceProvider).markReviewed(report.id, kp);
      if (!context.mounted) return;
      Navigator.pop(context);
      _snack(context, 'Laporan ditandakan sebagai disemak.',
          EHadirTheme.approved);
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, 'Gagal: $e', EHadirTheme.rejected);
    }
  }

  Future<void> _onResolve(BuildContext context, WidgetRef ref) async {
    final note = await _promptForNote(
      context: context,
      title: 'Selesaikan Laporan',
      hint: 'Catatan tindakan (pilihan)',
      buttonLabel: 'Selesai',
      buttonColor: ReportStatus.resolved.color,
      required: false,
    );
    if (note == null) return; // user cancelled
    final kj = ref.read(authProvider).currentUser!;
    try {
      await ref
          .read(disciplineServiceProvider)
          .markResolved(report.id, kj, note: note);
      if (!context.mounted) return;
      Navigator.pop(context);
      _snack(context, 'Laporan diselesaikan.', EHadirTheme.approved);
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, 'Gagal: $e', EHadirTheme.rejected);
    }
  }

  Future<void> _onEscalate(BuildContext context, WidgetRef ref) async {
    final note = await _promptForNote(
      context: context,
      title: 'Eskalasi Laporan',
      hint: 'Sebab eskalasi (diperlukan)',
      buttonLabel: 'Eskalasi',
      buttonColor: ReportStatus.escalated.color,
      required: true,
    );
    if (note == null) return;
    final kj = ref.read(authProvider).currentUser!;
    try {
      await ref
          .read(disciplineServiceProvider)
          .markEscalated(report.id, kj, note: note);
      if (!context.mounted) return;
      Navigator.pop(context);
      _snack(context, 'Laporan dieskalasi.', EHadirTheme.pending);
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, 'Gagal: $e', EHadirTheme.rejected);
    }
  }

  Future<String?> _promptForNote({
    required BuildContext context,
    required String title,
    required String hint,
    required String buttonLabel,
    required Color buttonColor,
    required bool required,
  }) async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final res = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            maxLines: 4,
            decoration: InputDecoration(hintText: hint),
            validator: (v) {
              if (!required) return null;
              if (v == null || v.trim().isEmpty) return 'Catatan diperlukan';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(context, ctrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
    return res;
  }

  // ─── Small UI helpers ────────────────────────────────────

  void _snack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: EHadirTheme.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: EHadirTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: EHadirTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: EHadirTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _infoNote(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EHadirTheme.surfaceLight,
        borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
        border: Border.all(color: EHadirTheme.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 18, color: EHadirTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: EHadirTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(ReportStatus s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 14, color: s.color),
          const SizedBox(width: 4),
          Text(
            s.label,
            style: TextStyle(
              color: s.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep {
  final String label;
  final String? sub;
  final DateTime? time;
  final bool done;
  final Color color;
  final IconData icon;
  _TimelineStep({
    required this.label,
    this.sub,
    this.time,
    required this.done,
    required this.color,
    required this.icon,
  });
}

class _TimelineRow extends StatelessWidget {
  final _TimelineStep step;
  final bool isLast;
  const _TimelineRow({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final dim = !step.done;
    final color =
        dim ? EHadirTheme.textSecondary.withValues(alpha: 0.4) : step.color;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Icon(step.icon, size: 14, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: EHadirTheme.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      color: dim
                          ? EHadirTheme.textSecondary
                          : EHadirTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (step.sub != null && step.sub!.isNotEmpty)
                    Text(
                      step.sub!,
                      style: const TextStyle(
                        color: EHadirTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  if (step.time != null)
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(step.time!),
                      style: const TextStyle(
                        color: EHadirTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
