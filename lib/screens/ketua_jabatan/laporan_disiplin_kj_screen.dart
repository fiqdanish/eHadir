import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/discipline_service.dart';
import '../../widgets/discipline_report_detail.dart';
import '../../widgets/discipline_report_list.dart';

/// Ketua Jabatan — Discipline Reports view across all programs.
class LaporanDisiplinKjScreen extends ConsumerWidget {
  const LaporanDisiplinKjScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(disciplineServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Disiplin (Semua Program)'),
      ),
      body: DisciplineReportList(
        stream: service.streamAll(),
        viewerRole: DisciplineViewerRole.kj,
        showProgramFilter: true,
        headerTitle: 'Tindakan Laporan Disiplin',
        headerSubtitle: 'Selesaikan atau eskalasi laporan yang telah disemak',
        headerIcon: Icons.gavel_rounded,
        headerGradient: const [Color(0xFFE64A19), Color(0xFFFF7043)],
      ),
    );
  }
}
