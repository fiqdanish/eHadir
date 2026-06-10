import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/discipline_service.dart';
import '../../widgets/discipline_report_detail.dart';
import '../../widgets/discipline_report_list.dart';

/// Ketua Program — Discipline Reports view for own program.
class LaporanDisiplinKpScreen extends ConsumerWidget {
  const LaporanDisiplinKpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(authProvider).currentUser!;
    final service = ref.watch(disciplineServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Disiplin'),
      ),
      body: DisciplineReportList(
        stream: service.streamByProgram(current.program),
        viewerRole: DisciplineViewerRole.kp,
        headerTitle: 'Semakan Laporan Disiplin',
        headerSubtitle: current.program,
        headerIcon: Icons.fact_check_rounded,
      ),
    );
  }
}
