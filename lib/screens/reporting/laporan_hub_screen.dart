import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../lecturer/sejarah_disiplin_screen.dart';
import 'reporting_screen.dart';

/// The bottom-nav "Laporan" hub.
///
/// Role behaviour:
///   • Pensyarah     → segmented control with two tabs:
///                       0 — Statistik (Module 3)
///                       1 — Lapor Disiplin (Module 2 history + new-report FAB)
///   • Everyone else → single Statistik panel (no segments, no second tab)
///
/// Only Pensyarah may file discipline reports, so the second segment is hidden
/// for KP / KJ / TPA / Admin. KP and KJ reach their own review/action screens
/// directly from their dashboards instead.
class LaporanHubScreen extends ConsumerStatefulWidget {
  /// 0 → Statistik, 1 → Lapor Disiplin. Ignored for non-Pensyarah users.
  final int initialTab;
  const LaporanHubScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<LaporanHubScreen> createState() => _LaporanHubScreenState();
}

class _LaporanHubScreenState extends ConsumerState<LaporanHubScreen> {
  late int _tab = widget.initialTab.clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;
    final isPensyarah = user?.role == UserRole.pensyarah;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        bottom: isPensyarah
            ? PreferredSize(
                preferredSize: const Size.fromHeight(58),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _SegmentedTabs(
                    selected: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
              )
            : null,
      ),
      body: isPensyarah
          ? IndexedStack(
              index: _tab,
              children: const [
                ReportingScreen(),
                SejarahDisiplinScreen(),
              ],
            )
          : const ReportingScreen(),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _SegmentedTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: EHadirTheme.surfaceLight,
        borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
        border: Border.all(color: EHadirTheme.divider),
      ),
      child: Row(
        children: [
          _seg(0, Icons.insights_rounded, 'Statistik'),
          _seg(1, Icons.gavel_rounded, 'Lapor Disiplin'),
        ],
      ),
    );
  }

  Widget _seg(int idx, IconData icon, String label) {
    final isSel = selected == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(idx),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? EHadirTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSel ? Colors.white : EHadirTheme.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    color:
                        isSel ? Colors.white : EHadirTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
