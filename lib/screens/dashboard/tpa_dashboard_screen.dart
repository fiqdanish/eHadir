import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/discipline_service.dart';
import '../../models/discipline_report_model.dart';
import '../../theme.dart';
import '../../utils/dialogs.dart';

class TPADashboardScreen extends ConsumerWidget {
  const TPADashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discipline = ref.watch(disciplineServiceProvider);

    return StreamBuilder<List<DisciplineReportModel>>(
      stream: discipline.streamAll(),
      builder: (ctx, snap) {
        final reports = snap.data ?? const <DisciplineReportModel>[];
        return _buildScaffold(context, ref, reports);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, WidgetRef ref,
      List<DisciplineReportModel> reports) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Log Keluar',
          onPressed: () => showLogoutConfirmation(context, ref),
        ),
        title: const Text('TPA — Global Masalah Disiplin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Keluar',
            onPressed: () => showLogoutConfirmation(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF57F17), Color(0xFFFFD54F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
              boxShadow: EHadirTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
                  ),
                  child: const Icon(Icons.stars_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pusat Pemantauan Disiplin',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Semua Program · ${reports.length} rekod dilaporkan',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Data Table
          Expanded(
            child: reports.isEmpty
                ? const Center(
                    child: Text('Tiada rekod disiplin dilaporkan.',
                        style: TextStyle(color: EHadirTheme.textSecondary)))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: EHadirTheme.card,
                            borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
                            border: Border.all(color: EHadirTheme.divider),
                          ),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                                EHadirTheme.surfaceLight),
                            dataRowMaxHeight: 80,
                            dataRowMinHeight: 60,
                            columns: const [
                              DataColumn(label: Text('Program', style: TextStyle(fontWeight: FontWeight.w600))),
                              DataColumn(label: Text('Tarikh', style: TextStyle(fontWeight: FontWeight.w600))),
                              DataColumn(label: Text('Nama Pelajar', style: TextStyle(fontWeight: FontWeight.w600))),
                              DataColumn(label: Text('Masalah Disiplin', style: TextStyle(fontWeight: FontWeight.w600))),
                              DataColumn(label: Text('Tahap Keterukan', style: TextStyle(fontWeight: FontWeight.w600))),
                              DataColumn(label: Text('Dilapor Oleh', style: TextStyle(fontWeight: FontWeight.w600))),
                            ],
                            rows: reports.map((r) {
                              return DataRow(
                                cells: [
                                  DataCell(_programBadge(r.program)),
                                  DataCell(Text(DateFormat('dd MMM yyyy').format(r.reportedAt),
                                      style: const TextStyle(color: EHadirTheme.textSecondary, fontSize: 13))),
                                  DataCell(Text(r.studentName,
                                      style: const TextStyle(color: EHadirTheme.textPrimary, fontWeight: FontWeight.w600))),
                                  DataCell(
                                    SizedBox(
                                      width: 200,
                                      child: Text(r.issueDescription,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: EHadirTheme.textSecondary, fontSize: 13)),
                                    ),
                                  ),
                                  DataCell(_severityBadge(r.severityLevel)),
                                  DataCell(Text(r.reportedByName,
                                      style: const TextStyle(color: EHadirTheme.textSecondary, fontSize: 13))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _programBadge(String program) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: EHadirTheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(program,
          style: const TextStyle(
              color: EHadirTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _severityBadge(SeverityLevel severity) {
    Color color;
    switch (severity) {
      case SeverityLevel.ringan:
        color = const Color(0xFF2E7D32); // Green
        break;
      case SeverityLevel.sederhana:
        color = const Color(0xFFF57F17); // Amber/Orange
        break;
      case SeverityLevel.serius:
        color = const Color(0xFFC62828); // Red
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        severity.label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
