import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/mock_db_service.dart';
import '../../models/booking.dart';
import '../../theme.dart';
import 'package:intl/intl.dart';

class BookingDashboardScreen extends ConsumerStatefulWidget {
  final String currentUserId;
  final bool isAdmin;

  const BookingDashboardScreen({
    super.key,
    required this.currentUserId,
    this.isAdmin = false,
  });

  @override
  ConsumerState<BookingDashboardScreen> createState() => _BookingDashboardScreenState();
}

class _BookingDashboardScreenState extends ConsumerState<BookingDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final db = ref.watch(mockDbProvider);
        final myBookings = db.getBookingsForLecturer(widget.currentUserId);
        final pending = myBookings.where((b) => b.status == BookingStatus.pending).length;
        final approved = myBookings.where((b) => b.status == BookingStatus.approved).length;
        final rejected = myBookings.where((b) => b.status == BookingStatus.rejected).length;

        return FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              children: [
                _buildHeader(db),
                const SizedBox(height: 24),
                _buildStatCards(myBookings.length, pending, approved, rejected),
                const SizedBox(height: 28),
                _buildQuickActions(context),
                const SizedBox(height: 28),
                _buildRecentActivity(myBookings, db),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(MockDatabaseService db) {
    final user = db.getUserById(widget.currentUserId);
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: EHadirTheme.headerGradient,
        borderRadius: BorderRadius.circular(EHadirTheme.radiusXl),
        boxShadow: EHadirTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: EHadirTheme.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
            ),
            child: Text(
              '📅 ${DateFormat('EEEE, d MMMM yyyy').format(DateTime.now())}',
              style: const TextStyle(color: EHadirTheme.accent, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(int total, int pending, int approved, int rejected) {
    return Row(
      children: [
        _statCard('Total', total, EHadirTheme.primary, Icons.event_note_rounded),
        const SizedBox(width: 10),
        _statCard('Pending', pending, EHadirTheme.pending, Icons.schedule_rounded),
        const SizedBox(width: 10),
        _statCard('Approved', approved, EHadirTheme.approved, Icons.check_circle_rounded),
        const SizedBox(width: 10),
        _statCard('Rejected', rejected, EHadirTheme.rejected, Icons.cancel_rounded),
      ],
    );
  }

  Widget _statCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: EHadirTheme.card,
          borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: count),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, _) => Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: EHadirTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: EHadirTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                icon: Icons.add_circle_outline_rounded,
                label: 'New Booking',
                subtitle: 'Request a replacement class',
                gradient: EHadirTheme.primaryGradient,
                onTap: () {
                  // Navigate handled by AppShell tab switch
                  final scaffold = Scaffold.maybeOf(context);
                  if (scaffold != null && scaffold.hasDrawer) {
                    // fallback
                  }
                  // We'll use a callback pattern
                  _showSnackBar('Tap the "New Booking" tab below to create a booking');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionCard(
                icon: Icons.history_rounded,
                label: 'My Bookings',
                subtitle: 'View booking status',
                gradient: const LinearGradient(
                  colors: [Color(0xFF00796B), Color(0xFF00BFA5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () {
                  _showSnackBar('Tap the "My Bookings" tab below to view history');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
          boxShadow: EHadirTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List<Booking> bookings, MockDatabaseService db) {
    final recent = bookings.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            color: EHadirTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: EHadirTheme.card,
              borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.event_available_rounded, color: EHadirTheme.textSecondary, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'No bookings yet',
                    style: TextStyle(color: EHadirTheme.textSecondary, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Create your first booking to get started!',
                    style: TextStyle(color: EHadirTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          ...recent.map((b) => _bookingActivityCard(b, db)),
      ],
    );
  }

  Widget _bookingActivityCard(Booking booking, MockDatabaseService db) {
    final statusColor = EHadirTheme.statusColor(booking.statusLabel);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EHadirTheme.card,
        borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
        border: Border(
          left: BorderSide(color: statusColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.subject,
                  style: const TextStyle(
                    color: EHadirTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${booking.room} • ${DateFormat('dd MMM yyyy').format(booking.date)} • ${booking.timeRangeFormatted}',
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(EHadirTheme.statusIcon(booking.statusLabel), color: statusColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  booking.statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
