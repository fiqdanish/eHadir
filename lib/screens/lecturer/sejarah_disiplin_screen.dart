import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/discipline_report_model.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/discipline_service.dart';
import '../../theme.dart';
import '../../widgets/discipline_report_detail.dart';
import 'lapor_disiplin_screen.dart';

/// Pensyarah's own history of submitted discipline reports.
class SejarahDisiplinScreen extends ConsumerWidget {
  const SejarahDisiplinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(authProvider).currentUser!;
    final service = ref.watch(disciplineServiceProvider);
    final canCreate = current.role == UserRole.pensyarah;

    return Scaffold(
      // No AppBar — this screen is normally embedded inside the
      // LaporanHubScreen which already provides the bar + segmented tabs.
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LaporDisiplinScreen()),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Laporan Baru'),
            )
          : null,
      body: StreamBuilder<List<DisciplineReportModel>>(
        stream: service.streamByLecturer(current.id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Ralat memuatkan laporan:\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: EHadirTheme.rejected),
                ),
              ),
            );
          }
          final reports = snap.data ?? const [];
          if (reports.isEmpty) {
            return _EmptyState(
              onCreate: canCreate
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LaporDisiplinScreen()),
                      )
                  : null,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: reports.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _ReportTile(
              report: reports[i],
              onTap: () => showDisciplineReportDetail(
                context: context,
                ref: ref,
                report: reports[i],
                viewerRole: DisciplineViewerRole.pensyarah,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback? onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: EHadirTheme.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: 56,
                color: EHadirTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada laporan dihantar',
              style: TextStyle(
                color: EHadirTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              onCreate == null
                  ? 'Tiada laporan untuk dipaparkan.'
                  : 'Tekan butang di bawah untuk membuat laporan disiplin baru.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: EHadirTheme.textSecondary),
            ),
            if (onCreate != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Laporan Baru'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final DisciplineReportModel report;
  final VoidCallback onTap;

  const _ReportTile({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EHadirTheme.card,
          borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
          border: Border.all(color: EHadirTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.studentName,
                    style: const TextStyle(
                      color: EHadirTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _statusBadge(report.status),
              ],
            ),
            if (report.studentClass.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                report.studentClass,
                style: const TextStyle(
                  color: EHadirTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              report.issueDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: EHadirTheme.textPrimary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _severityChip(report.severityLevel),
                const Spacer(),
                Icon(Icons.event_rounded,
                    size: 14, color: EHadirTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(report.reportedAt),
                  style: const TextStyle(
                    color: EHadirTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _severityChip(SeverityLevel s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
        border: Border.all(color: s.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        s.label,
        style: TextStyle(
          color: s.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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
