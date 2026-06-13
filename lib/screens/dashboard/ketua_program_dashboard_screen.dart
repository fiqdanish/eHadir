import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/discipline_report_model.dart';
import '../../services/auth_service.dart';
import '../../services/discipline_service.dart';
import '../../theme.dart';
import '../../utils/dialogs.dart';
import '../ketua_jabatan/bina_jadual_screen.dart';
import '../ketua_program/laporan_disiplin_kp_screen.dart';

/// Ketua Program dashboard.
///
/// In the scheduling flow the Ketua Program now BUILDS the weekly timetable
/// (day / time / room) for the assignments the Ketua Jabatan created in
/// "Tugaskan Subjek", via [BinaJadualScreen]. They also review the student
/// discipline reports raised by their program's lecturers.
class KetuaProgramDashboardScreen extends ConsumerWidget {
  const KetuaProgramDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(authProvider).currentUser!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Log Keluar',
          onPressed: () => showLogoutConfirmation(context, ref),
        ),
        title: Text('Ketua Program — ${current.program}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _buildPageHeader(current.program),
          const SizedBox(height: 16),
          _buildBinaJadualCard(context),
          const SizedBox(height: 10),
          _buildLaporDisiplinCard(context, ref, current.program),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────

  Widget _buildPageHeader(String program) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: EHadirTheme.primaryGradient,
        borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
        boxShadow: EHadirTheme.glowShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
            ),
            child: const Icon(Icons.calendar_view_week_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Papan Pemuka Program',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(program,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bina Jadual entry ───────────────────────────────────

  Widget _buildBinaJadualCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BinaJadualScreen()),
      ),
      borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EHadirTheme.card,
          borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
          border: Border.all(
              color: EHadirTheme.primary.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: EHadirTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
              ),
              child: const Icon(Icons.calendar_view_week_rounded,
                  color: EHadirTheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bina Jadual Mingguan',
                      style: TextStyle(
                          color: EHadirTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 2),
                  Text(
                      'Susun hari, slot masa, dan bilik bagi setiap tugasan pensyarah program anda',
                      style: TextStyle(
                          color: EHadirTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: EHadirTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  // ─── Discipline reports entry ────────────────────────────

  Widget _buildLaporDisiplinCard(
      BuildContext context, WidgetRef ref, String program) {
    final service = ref.watch(disciplineServiceProvider);
    return StreamBuilder<List<DisciplineReportModel>>(
      stream: service.streamByProgram(program),
      builder: (context, snap) {
        final reports = snap.data ?? const <DisciplineReportModel>[];
        final pending =
            reports.where((r) => r.status == ReportStatus.pending).length;
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LaporanDisiplinKpScreen()),
          ),
          borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EHadirTheme.card,
              borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
              border: Border.all(
                color: EHadirTheme.rejected.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: EHadirTheme.rejected.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
                  ),
                  child: const Icon(Icons.gavel_rounded,
                      color: EHadirTheme.rejected, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Laporan Disiplin Pelajar',
                          style: TextStyle(
                              color: EHadirTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text(
                          'Semak dan sahkan laporan disiplin daripada pensyarah program',
                          style: TextStyle(
                              color: EHadirTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                if (pending > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: EHadirTheme.pending,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$pending baru',
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
        );
      },
    );
  }
}
