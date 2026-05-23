import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/mock_db_service.dart';
import '../../models/class_slot_model.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class MyTimetableScreen extends ConsumerWidget {
  final Function(String slotId) onTakeAttendance;

  const MyTimetableScreen({super.key, required this.onTakeAttendance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final db = ref.watch(mockDbProvider);
    final currentUser = auth.currentUser!;
    
    List<ClassSlotModel> slots = [];
    if (currentUser.role == UserRole.ketuaProgram) {
      slots = db.getClassSlotsForProgram(currentUser.program);
    } else {
      slots = db.getClassSlotsForLecturer(currentUser.id);
    }
    slots.sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Jadual Saya'),
            floating: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: EHadirTheme.primaryGradient,
              ),
            ),
          ),
          if (slots.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy_rounded,
                        size: 64, color: EHadirTheme.textSecondary.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    const Text('Tiada jadual ditemui.',
                        style: TextStyle(color: EHadirTheme.textSecondary)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _TimetableCard(
                    slot: slots[i],
                    onTakeAttendance: onTakeAttendance,
                  ),
                  childCount: slots.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimetableCard extends StatelessWidget {
  final ClassSlotModel slot;
  final Function(String slotId) onTakeAttendance;

  const _TimetableCard({required this.slot, required this.onTakeAttendance});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: EHadirTheme.card,
        borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
        border: Border.all(color: EHadirTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: EHadirTheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
                  ),
                  child: Column(
                    children: [
                      Text(DateFormat('MMM').format(slot.date).toUpperCase(),
                          style: const TextStyle(
                              color: EHadirTheme.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                      Text(DateFormat('dd').format(slot.date),
                          style: const TextStyle(
                              color: EHadirTheme.accent,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(slot.subjectName,
                          style: const TextStyle(
                              color: EHadirTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.room_rounded,
                              size: 14, color: EHadirTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(slot.roomId,
                              style: const TextStyle(
                                  color: EHadirTheme.textSecondary,
                                  fontSize: 13)),
                          const SizedBox(width: 12),
                          const Icon(Icons.schedule_rounded,
                              size: 14, color: EHadirTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(slot.timeRangeFormatted,
                              style: const TextStyle(
                                  color: EHadirTheme.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.people_alt_rounded,
                              size: 14, color: EHadirTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text('Program: ${slot.program}',
                              style: const TextStyle(
                                  color: EHadirTheme.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: EHadirTheme.surfaceLight,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(EHadirTheme.radiusMd),
                  bottomRight: Radius.circular(EHadirTheme.radiusMd)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    onTakeAttendance(slot.id);
                  },
                  icon: const Icon(Icons.fact_check_rounded, size: 18),
                  label: const Text('Ambil Kehadiran'),
                  style: TextButton.styleFrom(
                    foregroundColor: EHadirTheme.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
