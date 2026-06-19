import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../models/department.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class BulkCreateUsersScreen extends ConsumerStatefulWidget {
  const BulkCreateUsersScreen({super.key});

  @override
  ConsumerState<BulkCreateUsersScreen> createState() =>
      _BulkCreateUsersScreenState();
}

// ─── Per-row data holder ──────────────────────────────────────

class _BulkUserEntry {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  UserRole role;
  String program;
  bool obscure;

  _BulkUserEntry()
      : nameCtrl = TextEditingController(),
        emailCtrl = TextEditingController(),
        passwordCtrl = TextEditingController(),
        role = UserRole.pensyarah,
        program = kPrograms.first,
        obscure = true;

  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
  }
}

// ─── Screen ───────────────────────────────────────────────────

class _BulkCreateUsersScreenState
    extends ConsumerState<BulkCreateUsersScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_BulkUserEntry> _entries = [];
  bool _isCreating = false;
  int _progressDone = 0;
  int _progressTotal = 0;

  @override
  void initState() {
    super.initState();
    _addEntry();
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  void _addEntry() {
    if (_entries.length >= 30) return;
    setState(() => _entries.add(_BulkUserEntry()));
  }

  void _removeEntry(int index) {
    final removed = _entries.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _createAll() async {
    if (!_formKey.currentState!.validate()) return;

    final users = _entries.map((e) {
      String programOrDept;
      if (e.role == UserRole.admin ||
          e.role == UserRole.timbalanPengarahAkademik) {
        programOrDept = 'Global';
      } else {
        programOrDept = e.program;
      }
      return BulkUserData(
        name: e.nameCtrl.text.trim(),
        email: e.emailCtrl.text.trim(),
        password: e.passwordCtrl.text,
        role: e.role,
        program: programOrDept,
      );
    }).toList();

    setState(() {
      _isCreating = true;
      _progressDone = 0;
      _progressTotal = users.length;
    });

    final results = await ref.read(authProvider).bulkCreateUsers(
      users,
      onProgress: (done, total) {
        if (mounted) setState(() => _progressDone = done);
      },
    );

    if (!mounted) return;
    setState(() => _isCreating = false);
    _showResults(results);
  }

  void _showResults(List<BulkCreateResult> results) {
    final successes = results.where((r) => r.success).length;
    final failures = results.length - successes;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: EHadirTheme.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EHadirTheme.radiusLg)),
        title: Row(
          children: [
            Icon(
              failures == 0
                  ? Icons.check_circle_rounded
                  : Icons.info_outline_rounded,
              color: failures == 0 ? EHadirTheme.approved : EHadirTheme.pending,
              size: 26,
            ),
            const SizedBox(width: 10),
            const Text('Keputusan Penciptaan',
                style: TextStyle(
                    color: EHadirTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (failures == 0 ? EHadirTheme.approved : EHadirTheme.pending)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
                ),
                child: Row(
                  children: [
                    Text(
                      '$successes berjaya',
                      style: const TextStyle(
                          color: EHadirTheme.approved,
                          fontWeight: FontWeight.w600),
                    ),
                    if (failures > 0) ...[
                      const Text('  ·  ',
                          style:
                              TextStyle(color: EHadirTheme.textSecondary)),
                      Text(
                        '$failures gagal',
                        style: const TextStyle(
                            color: EHadirTheme.rejected,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final r = results[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            r.success
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: r.success
                                ? EHadirTheme.approved
                                : EHadirTheme.rejected,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name,
                                    style: const TextStyle(
                                        color: EHadirTheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                Text(r.email,
                                    style: const TextStyle(
                                        color: EHadirTheme.textSecondary,
                                        fontSize: 12)),
                                if (!r.success && r.error != null)
                                  Text(r.error!,
                                      style: const TextStyle(
                                          color: EHadirTheme.rejected,
                                          fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (failures > 0)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tutup & Semak Semula'),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: EHadirTheme.approved),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (successes > 0) Navigator.of(context).pop();
            },
            child: const Text('OK, Selesai'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cipta Pengguna Pukal'),
        actions: [
          if (!_isCreating)
            TextButton.icon(
              onPressed: _entries.length >= 30 ? null : _addEntry,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'Tambah (${_entries.length}/30)',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isCreating ? _buildProgress() : _buildForm(),
      floatingActionButton: _isCreating
          ? null
          : FloatingActionButton.extended(
              onPressed: _createAll,
              backgroundColor: EHadirTheme.approved,
              icon: const Icon(Icons.group_add_rounded),
              label: Text('Cipta ${_entries.length} Pengguna'),
            ),
    );
  }

  Widget _buildProgress() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: _progressTotal > 0 ? _progressDone / _progressTotal : null,
              strokeWidth: 5,
              color: EHadirTheme.approved,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Mencipta akaun $_progressDone / $_progressTotal…',
            style: const TextStyle(
                color: EHadirTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text('Sila tunggu, jangan tutup skrin ini.',
              style: TextStyle(
                  color: EHadirTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: _entries.length,
        itemBuilder: (ctx, i) => _UserEntryCard(
          index: i,
          entry: _entries[i],
          canDelete: _entries.length > 1,
          onDelete: () => _removeEntry(i),
          onRoleChanged: () => setState(() {}),
        ),
      ),
    );
  }
}

// ─── Individual user card ─────────────────────────────────────

class _UserEntryCard extends StatefulWidget {
  final int index;
  final _BulkUserEntry entry;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback onRoleChanged;

  const _UserEntryCard({
    required this.index,
    required this.entry,
    required this.canDelete,
    required this.onDelete,
    required this.onRoleChanged,
  });

  @override
  State<_UserEntryCard> createState() => _UserEntryCardState();
}

class _UserEntryCardState extends State<_UserEntryCard> {
  _BulkUserEntry get e => widget.entry;

  @override
  Widget build(BuildContext context) {
    final showProgram = e.role != UserRole.admin &&
        e.role != UserRole.timbalanPengarahAkademik;
    final isDept = e.role == UserRole.ketuaJabatan;
    final deptValue =
        Department.all.contains(e.program) ? e.program : Department.all.first;
    final progValue =
        kPrograms.contains(e.program) ? e.program : kPrograms.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: EHadirTheme.card,
        borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
        border: Border.all(color: EHadirTheme.divider),
        boxShadow: EHadirTheme.cardShadow,
      ),
      child: Column(
        children: [
          // ── Card header ──────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: EHadirTheme.surfaceLight,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(EHadirTheme.radiusMd)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: EHadirTheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                        color: EHadirTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Pengguna Baharu',
                    style: TextStyle(
                        color: EHadirTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const Spacer(),
                if (widget.canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: EHadirTheme.rejected, size: 20),
                    onPressed: widget.onDelete,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Buang',
                  ),
              ],
            ),
          ),

          // ── Fields ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Name
                TextFormField(
                  controller: e.nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: EHadirTheme.textPrimary),
                  decoration: _deco(
                      hint: 'Nama Penuh',
                      icon: Icons.person_outline_rounded),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama diperlukan';
                    }
                    if (v.trim().length < 3) return 'Nama terlalu pendek';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Email
                TextFormField(
                  controller: e.emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: EHadirTheme.textPrimary),
                  decoration:
                      _deco(hint: 'E-mel', icon: Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'E-mel diperlukan';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                        .hasMatch(v.trim())) {
                      return 'Format e-mel tidak sah';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Password
                TextFormField(
                  controller: e.passwordCtrl,
                  obscureText: e.obscure,
                  style: const TextStyle(color: EHadirTheme.textPrimary),
                  decoration: _deco(
                    hint: 'Kata Laluan Sementara',
                    icon: Icons.lock_outline_rounded,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        e.obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: EHadirTheme.textSecondary,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => e.obscure = !e.obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Kata laluan diperlukan';
                    }
                    if (v.length < 6) return 'Minimum 6 aksara';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Role
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: EHadirTheme.surfaceLight,
                    borderRadius:
                        BorderRadius.circular(EHadirTheme.radiusMd),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<UserRole>(
                      value: e.role,
                      isExpanded: true,
                      dropdownColor: EHadirTheme.card,
                      style: const TextStyle(
                          color: EHadirTheme.textPrimary, fontSize: 15),
                      icon: const Icon(Icons.expand_more_rounded,
                          color: EHadirTheme.textSecondary),
                      items: UserRole.values
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Row(children: [
                                  Icon(_roleIcon(r),
                                      size: 16, color: _roleColor(r)),
                                  const SizedBox(width: 8),
                                  Text(r.displayName),
                                ]),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          if (v == UserRole.ketuaJabatan &&
                              e.role != UserRole.ketuaJabatan) {
                            e.program = Department.all.first;
                          } else if (v != UserRole.ketuaJabatan &&
                              e.role == UserRole.ketuaJabatan) {
                            e.program = kPrograms.first;
                          }
                          e.role = v;
                        });
                        widget.onRoleChanged();
                      },
                    ),
                  ),
                ),

                // Program / Department
                if (showProgram) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: EHadirTheme.surfaceLight,
                      borderRadius:
                          BorderRadius.circular(EHadirTheme.radiusMd),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: isDept
                          ? DropdownButton<String>(
                              value: deptValue,
                              isExpanded: true,
                              dropdownColor: EHadirTheme.card,
                              style: const TextStyle(
                                  color: EHadirTheme.textPrimary,
                                  fontSize: 15),
                              icon: const Icon(Icons.expand_more_rounded,
                                  color: EHadirTheme.textSecondary),
                              items: Department.all
                                  .map((d) => DropdownMenuItem(
                                      value: d, child: Text(d)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => e.program = v ?? e.program),
                            )
                          : DropdownButton<String>(
                              value: progValue,
                              isExpanded: true,
                              dropdownColor: EHadirTheme.card,
                              style: const TextStyle(
                                  color: EHadirTheme.textPrimary,
                                  fontSize: 15),
                              icon: const Icon(Icons.expand_more_rounded,
                                  color: EHadirTheme.textSecondary),
                              items: kPrograms
                                  .map((p) => DropdownMenuItem(
                                      value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => e.program = v ?? e.program),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _deco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: EHadirTheme.textSecondary, size: 18),
    );
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.pensyarah:
        return Icons.school_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.ketuaProgram:
        return Icons.manage_accounts_rounded;
      case UserRole.ketuaJabatan:
        return Icons.corporate_fare_rounded;
      case UserRole.timbalanPengarahAkademik:
        return Icons.stars_rounded;
    }
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
}
