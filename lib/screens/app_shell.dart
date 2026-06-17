import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../theme.dart';

// Import dashboards
import 'dashboard/admin_dashboard_screen.dart';
import 'dashboard/ketua_program_dashboard_screen.dart';
import 'dashboard/ketua_jabatan_dashboard_screen.dart';
import 'dashboard/tpa_dashboard_screen.dart';
import 'dashboard/pensyarah_dashboard_screen.dart';

// Import modules
import 'lecturer/ambil_kehadiran_screen.dart';
import 'lecturer/weekly_timetable_screen.dart';
import 'profile/profile_screen.dart';
import 'reporting/laporan_hub_screen.dart';
import 'reporting/reporting_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  final AppUser currentUser;
  const AppShell({super.key, required this.currentUser});

  @override
  ConsumerState<AppShell> createState() => AppShellState();
}

class AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;
  String? _attendanceSlotId;
  int _laporanTab = 0;

  void navigateToTab(int index) {
    if (index >= 0 && index < _buildTabs().length) {
      setState(() => _currentIndex = index);
    }
  }

  void navigateToAttendanceTab(String slotId) {
    setState(() {
      _attendanceSlotId = slotId;
      _currentIndex = 2;
    });
  }

  /// Jump to the Laporan tab on a specific sub-tab (0 = Statistik, 1 = Lapor).
  void navigateToLaporan({int subTab = 0}) {
    setState(() {
      _laporanTab = subTab.clamp(0, 1);
      _currentIndex = 3;
    });
  }

  List<_NavTab> _buildTabs() {
    final role = widget.currentUser.role;

    Widget utama;
    switch (role) {
      case UserRole.admin:
        utama = const AdminDashboardScreen();
        break;
      case UserRole.ketuaProgram:
        utama = const KetuaProgramDashboardScreen();
        break;
      case UserRole.ketuaJabatan:
        utama = const KetuaJabatanDashboardScreen();
        break;
      case UserRole.timbalanPengarahAkademik:
        utama = const TPADashboardScreen();
        break;
      case UserRole.pensyarah:
        utama = const PensyarahDashboardScreen();
        break;
    }

    // Laporan tab:
    //   Pensyarah → hub with both Statistik (M3) and Lapor Disiplin (M2 submit)
    //   KP / KJ / Admin / TPA → ReportingScreen only (reviewer roles don't file
    //     reports — they use their dashboard cards to open review screens).
    final Widget laporan = role == UserRole.pensyarah
        ? LaporanHubScreen(
            key: ValueKey('laporan-$_laporanTab'),
            initialTab: _laporanTab,
          )
        : Scaffold(
            appBar: AppBar(title: const Text('Laporan')),
            body: const ReportingScreen(),
          );

    // Jadual + Kehadiran are lecturer-only modules. Neither the Ketua Program
    // nor the Ketua Jabatan teaches, so those two tabs are hidden for them.
    final showLecturerTabs = role != UserRole.ketuaProgram &&
        role != UserRole.ketuaJabatan;

    return [
      _NavTab(Icons.home_rounded, 'Utama', utama),
      if (showLecturerTabs)
        _NavTab(Icons.calendar_month_rounded, 'Jadual',
            const WeeklyTimetableScreen()),
      if (showLecturerTabs)
        _NavTab(
          Icons.fact_check_rounded,
          'Kehadiran',
          AmbilKehadiranScreen(
            key: ValueKey(_attendanceSlotId ?? 'attendance-tab'),
            initialSlotId: _attendanceSlotId,
          ),
        ),
      _NavTab(Icons.bar_chart_rounded, 'Laporan', laporan),
      _NavTab(Icons.person_rounded, 'Profil', const ProfileScreen()),
    ];
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => navigateToTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? EHadirTheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? EHadirTheme.primary : EHadirTheme.textSecondary,
              size: 22,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isSelected
                  ? Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            color: EHadirTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _buildTabs();
    // Clamp in case the active index is beyond this role's (shorter) tab list.
    final index = _currentIndex.clamp(0, tabs.length - 1);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [for (final t in tabs) t.screen],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: EHadirTheme.divider),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < tabs.length; i++)
                _buildNavItem(i, tabs[i].icon, tabs[i].label),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single bottom-navigation destination: its icon, label, and screen.
class _NavTab {
  final IconData icon;
  final String label;
  final Widget screen;
  const _NavTab(this.icon, this.label, this.screen);
}
