import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class ArchivedUsersScreen extends ConsumerStatefulWidget {
  const ArchivedUsersScreen({super.key});

  @override
  ConsumerState<ArchivedUsersScreen> createState() =>
      _ArchivedUsersScreenState();
}

class _ArchivedUsersScreenState extends ConsumerState<ArchivedUsersScreen> {
  List<ArchivedUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final users = await ref.read(authProvider).fetchArchivedUsers();
    if (mounted) setState(() { _users = users; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekod Pengguna Dipadam'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat Semula',
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B2737), Color(0xFFEF4444)],
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
                    borderRadius:
                        BorderRadius.circular(EHadirTheme.radiusMd),
                  ),
                  child: const Icon(Icons.archive_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Arkib Pengguna',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        _loading
                            ? 'Memuatkan...'
                            : '${_users.length} rekod disimpan',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 56,
                                color: EHadirTheme.textSecondary
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            const Text('Tiada rekod diarkibkan.',
                                style: TextStyle(
                                    color: EHadirTheme.textSecondary,
                                    fontSize: 15)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 40),
                          itemCount: _users.length,
                          itemBuilder: (_, i) =>
                              _ArchivedUserCard(user: _users[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Archived user card ───────────────────────────────────────

class _ArchivedUserCard extends StatelessWidget {
  final ArchivedUser user;
  const _ArchivedUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final reasonColor = _reasonColor(user.reason);
    final dateStr =
        DateFormat('dd MMM yyyy, hh:mm a').format(user.deletedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: EHadirTheme.card,
        borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
        border: Border.all(
            color: EHadirTheme.rejected.withValues(alpha: 0.25)),
        boxShadow: EHadirTheme.cardShadow,
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.fromLTRB(16, 12, 16, 4),
            leading: CircleAvatar(
              backgroundColor:
                  EHadirTheme.rejected.withValues(alpha: 0.12),
              child: Text(
                user.name.split(' ').map((w) => w[0]).take(2).join(),
                style: const TextStyle(
                    color: EHadirTheme.rejected,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
            ),
            title: Text(user.name,
                style: const TextStyle(
                    color: EHadirTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 3),
                Text(user.email,
                    style: const TextStyle(
                        color: EHadirTheme.textSecondary,
                        fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _roleBadge(user.role),
                    if (user.program.isNotEmpty &&
                        user.program != 'Global') ...[
                      const SizedBox(width: 6),
                      _programBadge(user.program),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: EHadirTheme.divider, height: 1),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Reason chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: reasonColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_reasonIcon(user.reason),
                          size: 14, color: reasonColor),
                      const SizedBox(width: 4),
                      Text(
                        user.reason.displayName,
                        style: TextStyle(
                            color: reasonColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (user.note.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '— ${user.note}',
                      style: const TextStyle(
                          color: EHadirTheme.textSecondary,
                          fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const Spacer(),
                // Date
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 12, color: EHadirTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(dateStr,
                        style: const TextStyle(
                            color: EHadirTheme.textSecondary,
                            fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(UserRole role) {
    final color = _roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(role.displayName,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _programBadge(String program) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: EHadirTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(program,
          style: const TextStyle(
              color: EHadirTheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.pensyarah:
        return EHadirTheme.accent;
      case UserRole.admin:
        return const Color(0xFF7C4DFF);
      case UserRole.ketuaProgram:
        return const Color(0xFF26A69A);
      case UserRole.ketuaJabatan:
        return const Color(0xFFFF7043);
      case UserRole.timbalanPengarahAkademik:
        return const Color(0xFFFFD54F);
    }
  }

  Color _reasonColor(DeleteReason r) {
    switch (r) {
      case DeleteReason.bersara:
        return const Color(0xFF7C4DFF);
      case DeleteReason.pindah:
        return const Color(0xFF26A69A);
      case DeleteReason.lainLain:
        return EHadirTheme.pending;
    }
  }

  IconData _reasonIcon(DeleteReason r) {
    switch (r) {
      case DeleteReason.bersara:
        return Icons.elderly_rounded;
      case DeleteReason.pindah:
        return Icons.transfer_within_a_station_rounded;
      case DeleteReason.lainLain:
        return Icons.more_horiz_rounded;
    }
  }
}
