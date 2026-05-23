import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../lecturer/ambil_kehadiran_screen.dart';
import '../lecturer/lapor_disiplin_screen.dart';
import '../lecturer/my_timetable_screen.dart';
import '../booking/create_booking_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../../utils/dialogs.dart';

class PensyarahDashboardScreen extends ConsumerWidget {
  const PensyarahDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final current = auth.currentUser!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Log Keluar',
          onPressed: () => showLogoutConfirmation(context, ref),
        ),
        title: Text('Pensyarah — ${current.name.split(' ').first}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: EHadirTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
                  boxShadow: EHadirTheme.glowShadow,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        current.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Selamat Datang,',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                          Text(
                            current.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Menu Utama',
                style: TextStyle(
                  color: EHadirTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              // 2x2 Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: [
                    _MenuCard(
                      title: 'Ambil Kehadiran',
                      icon: Icons.fact_check_rounded,
                      color: EHadirTheme.approved,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AmbilKehadiranScreen()),
                      ),
                    ),
                    _MenuCard(
                      title: 'Lapor Disiplin',
                      icon: Icons.gavel_rounded,
                      color: EHadirTheme.rejected,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LaporDisiplinScreen()),
                      ),
                    ),
                    _MenuCard(
                      title: 'Jadual Saya',
                      icon: Icons.calendar_month_rounded,
                      color: EHadirTheme.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => MyTimetableScreen(
                                onTakeAttendance: (slotId) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AmbilKehadiranScreen(
                                          initialSlotId: slotId),
                                    ),
                                  );
                                })),
                      ),
                    ),
                    _MenuCard(
                      title: 'Tempah Bilik',
                      icon: Icons.add_location_alt_rounded,
                      color: EHadirTheme.accent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateBookingScreen()),
                      ),
                    ),
                    _MenuCard(
                      title: 'Tempahan Saya',
                      icon: Icons.bookmark_rounded,
                      color: const Color(0xFF7C4DFF),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => MyBookingsScreen(
                                currentLecturerId: current.id)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EHadirTheme.card,
      borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: EHadirTheme.divider),
            borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: EHadirTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
