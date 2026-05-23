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
import 'lecturer/lapor_disiplin_screen.dart';
import 'lecturer/my_timetable_screen.dart';
import 'profile/profile_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  final AppUser currentUser;
  const AppShell({super.key, required this.currentUser});

  @override
  ConsumerState<AppShell> createState() => AppShellState();
}

class AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  void navigateToTab(int index) {
    if (index >= 0 && index < _buildScreens().length) {
      setState(() => _currentIndex = index);
    }
  }

  void navigateToAttendanceTab(String slotId) {
    setState(() {
      _currentIndex = 2; // Assuming Kehadiran is index 2
    });
  }

  List<Widget> _buildScreens() {
    // 0: Utama, 1: Jadual, 2: Kehadiran, 3: Laporan, 4: Profil/Tempah Bilik
    Widget utama;
    switch (widget.currentUser.role) {
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

    return [
      utama,
      MyTimetableScreen(onTakeAttendance: navigateToAttendanceTab), // Jadual
      const AmbilKehadiranScreen(), // Kehadiran
      const LaporDisiplinScreen(), // Laporan
      const ProfileScreen(), // Profil
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreens();
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: navigateToTab,
        selectedItemColor: EHadirTheme.accent,
        unselectedItemColor: EHadirTheme.textSecondary,
        backgroundColor: EHadirTheme.surface,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Utama'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Jadual'),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check_rounded), label: 'Kehadiran'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Laporan'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}
