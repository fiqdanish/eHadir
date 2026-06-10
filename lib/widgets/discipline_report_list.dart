import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/discipline_report_model.dart';
import '../theme.dart';
import 'discipline_report_detail.dart';

/// Filterable list of discipline reports shared by KP and KJ screens.
///
/// Reports are streamed by the caller; this widget only handles
/// filter chips, sorting, empty state, and per-row display.
class DisciplineReportList extends ConsumerStatefulWidget {
  final Stream<List<DisciplineReportModel>> stream;
  final DisciplineViewerRole viewerRole;

  /// When true, shows a "Program" filter row (used by KJ across programs).
  final bool showProgramFilter;

  /// Counter banner gradient — purely visual.
  final List<Color> headerGradient;

  /// Header title + subtitle.
  final String headerTitle;
  final String headerSubtitle;

  /// Icon for header.
  final IconData headerIcon;

  const DisciplineReportList({
    super.key,
    required this.stream,
    required this.viewerRole,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.headerIcon,
    this.showProgramFilter = false,
    this.headerGradient = const [Color(0xFF4F46E5), Color(0xFF3B82F6)],
  });

  @override
  ConsumerState<DisciplineReportList> createState() =>
      _DisciplineReportListState();
}

class _DisciplineReportListState extends ConsumerState<DisciplineReportList> {
  ReportStatus? _statusFilter;
  SeverityLevel? _severityFilter;
  String? _programFilter;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DisciplineReportModel>>(
      stream: widget.stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Ralat memuatkan laporan:\n${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: EHadirTheme.rejected),
              ),
            ),
          );
        }
        final all = snap.data ?? const <DisciplineReportModel>[];
        final filtered = all.where((r) {
          if (_statusFilter != null && r.status != _statusFilter) return false;
          if (_severityFilter != null && r.severityLevel != _severityFilter) {
            return false;
          }
          if (_programFilter != null && r.program != _programFilter) {
            return false;
          }
          return true;
        }).toList();

        return Column(
          children: [
            _header(all),
            _filters(all),
            const SizedBox(height: 6),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'Tiada laporan yang sepadan dengan tapisan.',
                        style: TextStyle(color: EHadirTheme.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ReportCard(
                        report: filtered[i],
                        onTap: () => showDisciplineReportDetail(
                          context: context,
                          ref: ref,
                          report: filtered[i],
                          viewerRole: widget.viewerRole,
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ─── Header ───────────────────────────────────────────────

  Widget _header(List<DisciplineReportModel> all) {
    final pending =
        all.where((r) => r.status == ReportStatus.pending).length;
    final reviewed =
        all.where((r) => r.status == ReportStatus.reviewed).length;
    final resolved =
        all.where((r) => r.status == ReportStatus.resolved).length;
    final escalated =
        all.where((r) => r.status == ReportStatus.escalated).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
        boxShadow: EHadirTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
                ),
                child:
                    Icon(widget.headerIcon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.headerTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.headerSubtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statTile('Menunggu', pending),
              _statTile('Disemak', reviewed),
              _statTile('Selesai', resolved),
              _statTile('Eskalasi', escalated),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, int count) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Filters ──────────────────────────────────────────────

  Widget _filters(List<DisciplineReportModel> all) {
    final programs = widget.showProgramFilter
        ? all.map((r) => r.program).toSet().toList()
      : const <String>[];
    if (widget.showProgramFilter) {
      programs.sort();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statusChip(null, 'Semua'),
                for (final s in ReportStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _statusChip(s, s.label),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _severityChip(null, 'Semua keterukan'),
                for (final s in SeverityLevel.values)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _severityChip(s, s.label),
                  ),
              ],
            ),
          ),
          if (widget.showProgramFilter && programs.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _programChip(null, 'Semua program'),
                  for (final p in programs)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _programChip(p, p.split(' — ').first),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(ReportStatus? s, String label) {
    final selected = _statusFilter == s;
    final color = s?.color ?? EHadirTheme.primary;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _statusFilter = s),
      selectedColor: color.withValues(alpha: 0.15),
      checkmarkColor: color,
      side: BorderSide(
        color: selected ? color : EHadirTheme.divider,
      ),
    );
  }

  Widget _severityChip(SeverityLevel? s, String label) {
    final selected = _severityFilter == s;
    final color = s?.color ?? EHadirTheme.primary;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _severityFilter = s),
      selectedColor: color.withValues(alpha: 0.15),
      checkmarkColor: color,
      side: BorderSide(
        color: selected ? color : EHadirTheme.divider,
      ),
    );
  }

  Widget _programChip(String? p, String label) {
    final selected = _programFilter == p;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _programFilter = p),
      selectedColor: EHadirTheme.accent.withValues(alpha: 0.15),
      checkmarkColor: EHadirTheme.accent,
      side: BorderSide(
        color: selected ? EHadirTheme.accent : EHadirTheme.divider,
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final DisciplineReportModel report;
  final VoidCallback onTap;
  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EHadirTheme.card,
          borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
          border: Border.all(color: EHadirTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12, top: 4),
                  decoration: BoxDecoration(
                    color: report.severityLevel.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.studentName,
                        style: const TextStyle(
                          color: EHadirTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (report.studentClass.isNotEmpty)
                        Text(
                          report.studentClass,
                          style: const TextStyle(
                            color: EHadirTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                _statusBadge(report.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.issueDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: EHadirTheme.textPrimary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_rounded,
                    size: 13, color: EHadirTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.reportedByName,
                    style: const TextStyle(
                      color: EHadirTheme.textSecondary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.event_rounded,
                    size: 13, color: EHadirTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(report.reportedAt),
                  style: const TextStyle(
                    color: EHadirTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(ReportStatus s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 13, color: s.color),
          const SizedBox(width: 4),
          Text(
            s.label,
            style: TextStyle(
              color: s.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
