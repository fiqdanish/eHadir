import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/mock_db_service.dart';
import '../../services/booking_service.dart';
import '../../models/booking.dart';
import '../../theme.dart';

class ManageBookingsScreen extends ConsumerStatefulWidget {
  final String currentAdminId;

  const ManageBookingsScreen({super.key, required this.currentAdminId});

  @override
  ConsumerState<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends ConsumerState<ManageBookingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  String _filter = 'pending'; // pending | approved | rejected | all

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
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
          final allBookings = List<Booking>.from(db.allBookings)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final pending = allBookings.where((b) => b.status == BookingStatus.pending).toList();
          final approved = allBookings.where((b) => b.status == BookingStatus.approved).toList();
          final rejected = allBookings.where((b) => b.status == BookingStatus.rejected).toList();

          List<Booking> filtered;
          switch (_filter) {
            case 'pending':
              filtered = pending;
              break;
            case 'approved':
              filtered = approved;
              break;
            case 'rejected':
              filtered = rejected;
              break;
            default:
              filtered = allBookings;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              _buildHeader(pending.length),
              const SizedBox(height: 18),
              _buildFilterChips(allBookings.length, pending.length, approved.length, rejected.length),
              const SizedBox(height: 18),
              if (filtered.isEmpty)
                _buildEmptyState()
              else
                ...filtered.asMap().entries.map(
                  (entry) => _buildAdminBookingCard(entry.value, db, entry.key),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(int pendingCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF7C4DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
        boxShadow: EHadirTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Manage Bookings',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Review and approve booking requests',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
              ],
            ),
          ),
          if (pendingCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: EHadirTheme.pending,
                borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
              ),
              child: Column(
                children: [
                  Text(
                    '$pendingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Pending',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(int all, int pending, int approved, int rejected) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('Pending', 'pending', pending, EHadirTheme.pending),
          const SizedBox(width: 8),
          _filterChip('Approved', 'approved', approved, EHadirTheme.approved),
          const SizedBox(width: 8),
          _filterChip('Rejected', 'rejected', rejected, EHadirTheme.rejected),
          const SizedBox(width: 8),
          _filterChip('All', 'all', all, EHadirTheme.primary),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, int count, Color color) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : EHadirTheme.card,
          borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
          border: Border.all(
            color: isSelected ? color : EHadirTheme.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : EHadirTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.3) : EHadirTheme.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? color : EHadirTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              color: EHadirTheme.textSecondary.withValues(alpha: 0.4), size: 64),
          const SizedBox(height: 16),
          const Text('No bookings in this category',
              style: TextStyle(color: EHadirTheme.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAdminBookingCard(Booking booking, MockDatabaseService db, int index) {
    final statusColor = EHadirTheme.statusColor(booking.statusLabel);
    final lecturer = db.getUserById(booking.lecturerId);
    final isPending = booking.status == BookingStatus.pending;

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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: EHadirTheme.card,
          borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
          border: Border.all(
            color: isPending ? EHadirTheme.pending.withValues(alpha: 0.4) : EHadirTheme.divider,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lecturer info + status
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: EHadirTheme.primary.withValues(alpha: 0.3),
                        child: Text(
                          lecturer?.name.substring(0, 1) ?? '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lecturer?.name ?? 'Unknown',
                              style: const TextStyle(
                                color: EHadirTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _timeAgo(booking.createdAt),
                              style: const TextStyle(color: EHadirTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
                        ),
                        child: Text(
                          booking.statusLabel,
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Booking details
                  Text(
                    booking.subject,
                    style: const TextStyle(
                      color: EHadirTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _detailChip(Icons.calendar_today_rounded, DateFormat('dd MMM yyyy').format(booking.date)),
                      _detailChip(Icons.schedule_rounded, booking.timeRangeFormatted),
                      _detailChip(Icons.room_rounded, booking.room),
                      _detailChip(Icons.group_rounded, booking.cohort),
                    ],
                  ),

                  if (booking.remarks != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: EHadirTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notes_rounded, color: EHadirTheme.textSecondary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              booking.remarks!,
                              style: const TextStyle(color: EHadirTheme.textSecondary, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (booking.rejectionReason != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: EHadirTheme.rejected.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: EHadirTheme.rejected, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rejected: ${booking.rejectionReason}',
                              style: const TextStyle(color: EHadirTheme.rejected, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action buttons for pending bookings
            if (isPending)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: EHadirTheme.surfaceLight,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(EHadirTheme.radiusMd),
                    bottomRight: Radius.circular(EHadirTheme.radiusMd),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRejectDialog(booking),
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: EHadirTheme.rejected,
                          side: const BorderSide(color: EHadirTheme.rejected),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _approveBooking(booking),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EHadirTheme.approved,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: EHadirTheme.textSecondary, size: 14),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: EHadirTheme.textSecondary, fontSize: 13)),
      ],
    );
  }

  Future<void> _approveBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Booking'),
        content: Text('Approve "${booking.subject}" for ${booking.room} on ${DateFormat('dd MMM').format(booking.date)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: EHadirTheme.approved),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final bookingService = ref.read(bookingProvider);
      await bookingService.approveBooking(booking.id, widget.currentAdminId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking approved successfully! ✅'),
            backgroundColor: EHadirTheme.approved,
          ),
        );
      }
    }
  }

  void _showRejectDialog(Booking booking) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject "${booking.subject}" for ${booking.room}?',
                style: const TextStyle(color: EHadirTheme.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: EHadirTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Rejection reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final bookingService = ref.read(bookingProvider);
              await bookingService.rejectBooking(
                booking.id,
                widget.currentAdminId,
                reason: reasonController.text.isNotEmpty ? reasonController.text : null,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking rejected'),
                    backgroundColor: EHadirTheme.rejected,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: EHadirTheme.rejected),
            child: const Text('Reject'),
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
