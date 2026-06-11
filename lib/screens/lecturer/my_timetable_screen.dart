import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/booking_service.dart';
import '../../services/curriculum_service.dart';
import '../../models/class_slot_model.dart';
import '../../models/timetable_entry.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import 'ambil_kehadiran_screen.dart';

// ═══════════════════════════════════════════════════════════
//  UNIFIED SCHEDULE ITEM — merges regular entries + replacements
// ═══════════════════════════════════════════════════════════

/// Represents a single item in the unified schedule list.
/// Can be either a regular timetable entry or a replacement booking slot.
class _ScheduleItem {
  final DateTime date;
  final String subjectName;
  final String subjectCode;
  final String studentClass;
  final String program;
  final String roomId;
  final int startMinutes;
  final int endMinutes;
  final bool isReplacement;

  /// Only set for replacement items (for cancellation)
  final String? bookingRef;
  final String? classSlotId;

  const _ScheduleItem({
    required this.date,
    required this.subjectName,
    required this.subjectCode,
    required this.studentClass,
    required this.program,
    required this.roomId,
    required this.startMinutes,
    required this.endMinutes,
    required this.isReplacement,
    this.bookingRef,
    this.classSlotId,
  });

  String get timeRangeFormatted {
    String fmt(int mins) =>
        '${(mins ~/ 60).toString().padLeft(2, '0')}:${(mins % 60).toString().padLeft(2, '0')}';
    return '${fmt(startMinutes)} – ${fmt(endMinutes)}';
  }

  factory _ScheduleItem.fromEntry(TimetableEntry e) => _ScheduleItem(
        date: e.date,
        subjectName: e.subjectName,
        subjectCode: e.subjectCode,
        studentClass: e.studentClass,
        program: e.program,
        roomId: e.room,
        startMinutes: e.startMinutes,
        endMinutes: e.endMinutes,
        isReplacement: false,
      );

  factory _ScheduleItem.fromSlot(ClassSlotModel s) => _ScheduleItem(
        date: s.date,
        subjectName: s.subjectName,
        subjectCode: s.subjectCode,
        studentClass: s.studentClass,
        program: s.program,
        roomId: s.roomId,
        startMinutes: s.startMinutes,
        endMinutes: s.endMinutes,
        isReplacement: true,
        bookingRef: s.bookingRef,
        classSlotId: s.id,
      );
}

// ═══════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════

class MyTimetableScreen extends ConsumerWidget {
  const MyTimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth           = ref.watch(authProvider);
    final currentUser    = auth.currentUser!;
    final bookingService = ref.read(firestoreBookingProvider);
    final curriculum     = ref.read(curriculumServiceProvider);

    // ── Stream 1: replacement class slots from bookings ──
    final Stream<List<ClassSlotModel>> slotsStream =
        currentUser.role == UserRole.ketuaProgram
            ? bookingService.streamClassSlotsForProgram(currentUser.program)
            : bookingService.streamClassSlotsForLecturer(currentUser.id);

    // ── Stream 2: regular scheduled timetable entries ──
    final Stream<List<TimetableEntry>> entriesStream =
        curriculum.streamEntriesForLecturer(currentUser.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Jadual Saya'),
            floating: true,
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<List<ClassSlotModel>>(
              stream: slotsStream,
              builder: (context, slotsSnap) {
                return StreamBuilder<List<TimetableEntry>>(
                  stream: entriesStream,
                  builder: (context, entriesSnap) {
                    // Loading state
                    if (slotsSnap.connectionState == ConnectionState.waiting ||
                        entriesSnap.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    // Error state
                    if (slotsSnap.hasError || entriesSnap.hasError) {
                      return SizedBox(
                        height: 300,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.error_outline_rounded,
                                  size: 48, color: EHadirTheme.rejected),
                              SizedBox(height: 16),
                              Text('Ralat memuatkan jadual.',
                                  style: TextStyle(color: EHadirTheme.textSecondary)),
                            ],
                          ),
                        ),
                      );
                    }

                    // Merge & sort all items by date then start time
                    final replacementItems = (slotsSnap.data ?? [])
                        .map(_ScheduleItem.fromSlot)
                        .toList();
                    final regularItems = (entriesSnap.data ?? [])
                        .map(_ScheduleItem.fromEntry)
                        .toList();

                    final allItems = [...regularItems, ...replacementItems];
                    allItems.sort((a, b) {
                      final dateComp = a.date.compareTo(b.date);
                      if (dateComp != 0) return dateComp;
                      return a.startMinutes.compareTo(b.startMinutes);
                    });

                    // Empty state
                    if (allItems.isEmpty) {
                      return SizedBox(
                        height: 300,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy_rounded,
                                  size: 64,
                                  color: EHadirTheme.textSecondary.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              const Text('Tiada jadual ditemui.',
                                  style: TextStyle(color: EHadirTheme.textSecondary)),
                            ],
                          ),
                        ),
                      );
                    }

                    // Build the unified list
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Summary chips
                              _buildSummaryRow(
                                regularCount:     regularItems.length,
                                replacementCount: replacementItems.length,
                              ),
                              const SizedBox(height: 16),
                              // Card list
                              ...allItems.map((item) => _TimetableCard(
                                    item: item,
                                    bookingService: bookingService,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      {required int regularCount, required int replacementCount}) {
    return Wrap(
      spacing: 8,
      children: [
        _SummaryChip(
          label: '$regularCount Kelas Biasa',
          color: EHadirTheme.primary,
          icon: Icons.schedule_rounded,
        ),
        _SummaryChip(
          label: '$replacementCount Kelas Gantian',
          color: const Color(0xFFF59E0B),
          icon: Icons.swap_horiz_rounded,
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _SummaryChip({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TIMETABLE CARD
// ═══════════════════════════════════════════════════════════

class _TimetableCard extends StatelessWidget {
  final _ScheduleItem item;
  final FirestoreBookingService bookingService;

  const _TimetableCard({required this.item, required this.bookingService});

  @override
  Widget build(BuildContext context) {
    final accentColor = item.isReplacement
        ? const Color(0xFFF59E0B) // amber for replacements
        : EHadirTheme.primary;   // indigo for regular

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: EHadirTheme.card,
        borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
        border: Border.all(
            color: item.isReplacement
                ? const Color(0xFFFCD34D).withValues(alpha: 0.5)
                : EHadirTheme.divider),
        boxShadow: EHadirTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top: date badge + details ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(DateFormat('MMM').format(item.date).toUpperCase(),
                          style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                      Text(DateFormat('dd').format(item.date),
                          style: TextStyle(
                              color: accentColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(item.subjectName,
                                style: const TextStyle(
                                    color: EHadirTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                          ),
                          if (item.isReplacement)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('GANTIAN',
                                  style: TextStyle(
                                      color: Color(0xFF92400E),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.room_rounded,
                              size: 16, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Text(item.roomId,
                              style: const TextStyle(
                                  color: EHadirTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(width: 14),
                          const Icon(Icons.schedule_rounded,
                              size: 16, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 4),
                          Text(item.timeRangeFormatted,
                              style: const TextStyle(
                                  color: EHadirTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.group_rounded,
                              size: 16, color: Color(0xFF6366F1)),
                          const SizedBox(width: 4),
                          Text(
                            item.studentClass.isNotEmpty
                                ? item.studentClass
                                : 'Kelas Gantian',
                            style: const TextStyle(
                                color: EHadirTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Action row ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFC),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(EHadirTheme.radiusLg),
                  bottomRight: Radius.circular(EHadirTheme.radiusLg)),
              border: Border(top: BorderSide(color: EHadirTheme.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cancel button — only for replacement bookings
                if (item.isReplacement)
                  TextButton.icon(
                    onPressed: () => _confirmCancel(context),
                    icon: const Icon(Icons.cancel_outlined,
                        size: 16, color: EHadirTheme.rejected),
                    label: const Text('Batal',
                        style: TextStyle(color: EHadirTheme.rejected, fontSize: 13)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  )
                else
                  const SizedBox.shrink(),

                // Take attendance button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AmbilKehadiranScreen(
                          subjectCode: item.subjectCode.isNotEmpty
                              ? item.subjectCode
                              : item.subjectName,
                          subjectName:  item.subjectName,
                          studentClass: item.studentClass,
                          program:      item.program,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fact_check_rounded,
                      size: 16, color: Colors.white),
                  label: const Text('Ambil Kehadiran'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EHadirTheme.approved,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show a confirmation dialog, then batch-delete from bookings + classSlots.
  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batal Tempahan'),
        content: Text(
            'Adakah anda pasti ingin membatalkan tempahan "${item.subjectName}" '
            'pada ${DateFormat("dd MMM yyyy").format(item.date)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: EHadirTheme.rejected),
            child: const Text('Ya, Batal'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await bookingService.deleteBooking(
        bookingId:   item.bookingRef ?? '',
        classSlotId: item.classSlotId ?? '',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tempahan berjaya dibatalkan.'),
            backgroundColor: EHadirTheme.approved,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membatalkan: $e'),
            backgroundColor: EHadirTheme.rejected,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
