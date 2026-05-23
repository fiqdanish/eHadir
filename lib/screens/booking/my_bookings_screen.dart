import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/mock_db_service.dart';
import '../../models/booking.dart';
import '../../theme.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  final String currentLecturerId;

  const MyBookingsScreen({super.key, required this.currentLecturerId});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Consumer(
        builder: (context, ref, _) {
          final db = ref.watch(mockDbProvider);
          final allBookings = db.getBookingsForLecturer(widget.currentLecturerId);
          final pending = allBookings.where((b) => b.status == BookingStatus.pending).toList();
          final approved = allBookings.where((b) => b.status == BookingStatus.approved).toList();
          final rejected = allBookings.where((b) => b.status == BookingStatus.rejected).toList();

          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: EHadirTheme.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
                          ),
                          child: const Icon(Icons.bookmark_rounded, color: EHadirTheme.accent, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('My Bookings',
                                  style: TextStyle(color: EHadirTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                              Text('Track your booking requests',
                                  style: TextStyle(color: EHadirTheme.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                        // Total count badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: EHadirTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
                          ),
                          child: Text(
                            '${allBookings.length}',
                            style: const TextStyle(
                              color: EHadirTheme.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Tab bar
                    Container(
                      decoration: BoxDecoration(
                        color: EHadirTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: EHadirTheme.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: EHadirTheme.accent,
                        unselectedLabelColor: EHadirTheme.textSecondary,
                        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        unselectedLabelStyle: const TextStyle(fontSize: 13),
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: 'All (${allBookings.length})'),
                          Tab(text: 'Pending (${pending.length})'),
                          Tab(text: 'Approved (${approved.length})'),
                          Tab(text: 'Rejected (${rejected.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingList(allBookings, db),
                    _buildBookingList(pending, db),
                    _buildBookingList(approved, db),
                    _buildBookingList(rejected, db),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, MockDatabaseService db) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, color: EHadirTheme.textSecondary.withValues(alpha: 0.4), size: 64),
            const SizedBox(height: 16),
            const Text('No bookings found',
                style: TextStyle(color: EHadirTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Your bookings will appear here',
                style: TextStyle(color: EHadirTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking, db, index);
      },
    );
  }

  Widget _buildBookingCard(Booking booking, MockDatabaseService db, int index) {
    final statusColor = EHadirTheme.statusColor(booking.statusLabel);
    final statusIcon = EHadirTheme.statusIcon(booking.statusLabel);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () => _showBookingDetail(context, booking, db),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: EHadirTheme.card,
            borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
            border: Border.all(color: EHadirTheme.divider),
          ),
          child: Column(
            children: [
              // Top section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: EHadirTheme.primaryDark,
                        borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('dd').format(booking.date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(booking.date),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.subject,
                            style: const TextStyle(
                              color: EHadirTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _infoChip(Icons.room_rounded, booking.room),
                              const SizedBox(width: 8),
                              _infoChip(Icons.group_rounded, booking.cohort),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _infoChip(Icons.schedule_rounded, booking.timeRangeFormatted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Status bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(EHadirTheme.radiusMd),
                    bottomRight: Radius.circular(EHadirTheme.radiusMd),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      booking.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _timeAgo(booking.createdAt),
                      style: const TextStyle(color: EHadirTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: EHadirTheme.textSecondary, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: EHadirTheme.textSecondary, size: 14),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: EHadirTheme.textSecondary, fontSize: 12)),
      ],
    );
  }

  void _showBookingDetail(BuildContext context, Booking booking, MockDatabaseService db) {
    final statusColor = EHadirTheme.statusColor(booking.statusLabel);
    final reviewer = booking.reviewedBy != null ? db.getUserById(booking.reviewedBy!) : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: EHadirTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(EHadirTheme.radiusXl)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: EHadirTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(booking.subject,
                style: const TextStyle(color: EHadirTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(EHadirTheme.statusIcon(booking.statusLabel), color: statusColor, size: 18),
                  const SizedBox(width: 8),
                  Text(booking.statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details
            _detailRow('📅', 'Date', DateFormat('EEEE, dd MMMM yyyy').format(booking.date)),
            _detailRow('🕐', 'Time', booking.timeRangeFormatted),
            _detailRow('🏫', 'Room', booking.room),
            _detailRow('👥', 'Cohort', booking.cohort),
            _detailRow('📝', 'Type',
                booking.type == BookingType.replacement ? 'Replacement Class' : 'Rescheduled Class'),
            if (booking.remarks != null) _detailRow('💬', 'Remarks', booking.remarks!),

            const SizedBox(height: 20),
            const Divider(color: EHadirTheme.divider),
            const SizedBox(height: 16),

            // Timeline
            const Text('Status Timeline',
                style: TextStyle(color: EHadirTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            _timelineStep('Submitted', DateFormat('dd MMM yyyy, HH:mm').format(booking.createdAt),
                EHadirTheme.approved, true),
            if (booking.reviewedAt != null)
              _timelineStep(
                booking.status == BookingStatus.approved ? 'Approved' : 'Rejected',
                '${DateFormat('dd MMM yyyy, HH:mm').format(booking.reviewedAt!)}${reviewer != null ? ' by ${reviewer.name}' : ''}',
                booking.status == BookingStatus.approved ? EHadirTheme.approved : EHadirTheme.rejected,
                true,
              )
            else if (booking.status == BookingStatus.pending)
              _timelineStep('Awaiting Review', 'Pending admin approval', EHadirTheme.pending, false),

            if (booking.status == BookingStatus.approved)
              _timelineStep('Active', 'Added to schedule', EHadirTheme.accent, true),

            if (booking.rejectionReason != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: EHadirTheme.rejected.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
                  border: Border.all(color: EHadirTheme.rejected.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: EHadirTheme.rejected, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rejection Reason',
                              style: TextStyle(color: EHadirTheme.rejected, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(booking.rejectionReason!,
                              style: const TextStyle(color: EHadirTheme.textSecondary, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(color: EHadirTheme.textSecondary, fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: EHadirTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _timelineStep(String title, String subtitle, Color color, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                child: completed
                    ? const Icon(Icons.check, color: Colors.white, size: 10)
                    : null,
              ),
              Container(width: 2, height: 30, color: color.withValues(alpha: 0.3)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(color: EHadirTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd MMM').format(dt);
  }
}
