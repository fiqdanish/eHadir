import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/discipline_report_model.dart';
import '../../services/auth_service.dart';
import '../../services/discipline_service.dart';
import '../../theme.dart';
import '../../utils/dialogs.dart';
import '../ketua_jabatan/laporan_disiplin_kj_screen.dart';
import '../ketua_program/tugaskan_subjek_screen.dart';

class KetuaJabatanDashboardScreen extends ConsumerWidget {
  const KetuaJabatanDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final current = auth.currentUser!;
    final service = ref.watch(disciplineServiceProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Log Keluar',
          onPressed: () => showLogoutConfirmation(context, ref),
        ),
        title: Text('Ketua Jabatan — ${current.program}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Keluar',
            onPressed: () => showLogoutConfirmation(context, ref),
          ),
        ],
      ),
      body: StreamBuilder<List<DisciplineReportModel>>(
        stream: service.streamAll(),
        builder: (context, snap) {
          final reports = snap.data ?? const <DisciplineReportModel>[];
          final pending =
              reports.where((r) => r.status == ReportStatus.pending).length;
          final reviewed =
              reports.where((r) => r.status == ReportStatus.reviewed).length;
          final resolved =
              reports.where((r) => r.status == ReportStatus.resolved).length;
          final escalated =
              reports.where((r) => r.status == ReportStatus.escalated).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              // ─── Header banner ───
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE64A19), Color(0xFFFF7043)],
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
                        borderRadius:
                            BorderRadius.circular(EHadirTheme.radiusMd),
                      ),
                      child: const Icon(Icons.corporate_fare_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Papan Pemuka Jabatan',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            current.program,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Tugaskan Subjek entry ───
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TugaskanSubjekScreen()),
                ),
                borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: EHadirTheme.card,
                    borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
                    border: Border.all(
                        color: EHadirTheme.primary.withValues(alpha: 0.4),
                        width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              EHadirTheme.primary.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(EHadirTheme.radiusMd),
                        ),
                        child: const Icon(Icons.library_books_rounded,
                            color: EHadirTheme.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tugaskan Subjek Pensyarah',
                                style: TextStyle(
                                    color: EHadirTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(height: 2),
                            Text(
                                'Tetapkan subjek yang diajar setiap pensyarah dalam jabatan',
                                style: TextStyle(
                                    color: EHadirTheme.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: EHadirTheme.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ─── Discipline reports entry (M2) ───
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LaporanDisiplinKjScreen()),
                ),
                borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: EHadirTheme.card,
                    borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
                    border: Border.all(
                        color: EHadirTheme.rejected.withValues(alpha: 0.4),
                        width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              EHadirTheme.rejected.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(EHadirTheme.radiusMd),
                        ),
                        child: const Icon(Icons.gavel_rounded,
                            color: EHadirTheme.rejected, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tindakan Laporan Disiplin',
                                style: TextStyle(
                                    color: EHadirTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                            SizedBox(height: 2),
                            Text(
                                'Selesaikan atau eskalasi laporan yang telah disemak oleh Ketua Program',
                                style: TextStyle(
                                    color: EHadirTheme.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      if (reviewed > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ReportStatus.reviewed.color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$reviewed perlu tindakan',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded,
                          color: EHadirTheme.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Stats grid ───
              const Text('Ringkasan Disiplin',
                  style: TextStyle(
                      color: EHadirTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _statCard('Menunggu', pending,
                          ReportStatus.pending.color, Icons.schedule_rounded)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _statCard(
                          'Disemak',
                          reviewed,
                          ReportStatus.reviewed.color,
                          Icons.fact_check_rounded)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _statCard(
                          'Selesai',
                          resolved,
                          ReportStatus.resolved.color,
                          Icons.check_circle_rounded)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _statCard(
                          'Eskalasi',
                          escalated,
                          ReportStatus.escalated.color,
                          Icons.priority_high_rounded)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EHadirTheme.card,
        borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
        border: Border.all(color: EHadirTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count',
                    style: const TextStyle(
                        color: EHadirTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                Text(label,
                    style: const TextStyle(
                        color: EHadirTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
