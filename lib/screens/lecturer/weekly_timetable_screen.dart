import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/timetable_entry.dart';
import '../../services/auth_service.dart';
import '../../services/curriculum_service.dart';
import '../../theme.dart';
import 'ambil_kehadiran_screen.dart';

/// Pensyarah view of the weekly timetable laid out in the IKM "STUDENT'S TIME
/// TABLE" grid: 5 rows (Mon-Fri) × 9 columns (period 1..9). Mirrors the DED 1A
/// PDF template.
class WeeklyTimetableScreen extends ConsumerWidget {
  const WeeklyTimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser!;
    final curriculum = ref.read(curriculumServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Jadual Mingguan"),
      ),
      body: StreamBuilder<List<TimetableEntry>>(
        stream: curriculum.streamEntriesForLecturer(user.id),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snap.data ?? const <TimetableEntry>[];
          return Column(
            children: [
              _Header(name: user.name, program: user.program),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: _TimetableGrid(entries: entries),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HEADER
// ═══════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final String name;
  final String program;
  const _Header({required this.name, required this.program});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: EHadirTheme.primaryGradient,
        borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
        boxShadow: EHadirTheme.glowShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STUDENT\'S TIME TABLE',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(program,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_rounded,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(name,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 14),
              const Icon(Icons.event_rounded,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              const Text('SESI JAN - JUN 2026',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GRID
// ═══════════════════════════════════════════════════════════════

class _TimetableGrid extends StatelessWidget {
  final List<TimetableEntry> entries;
  const _TimetableGrid({required this.entries});

  static const double _kDayColW = 56;
  static const double _kPeriodW = 130;
  static const double _kHeaderH = 56;
  static const double _kRowH = 96;

  /// Build a per-day list of segments. Each segment is either a placed entry
  /// or a blank gap. The row is guaranteed to span exactly periods 1..9
  /// regardless of bad data (negative spans, overlaps, out-of-range entries).
  List<_Segment> _segmentsForDay(SchoolDay day) {
    int clamp(int v) => v < 1 ? 1 : (v > 9 ? 9 : v);

    // Clamp + sort + drop zero-length entries.
    final dayEntries = entries
        .where((e) => e.day == day)
        .map((e) {
          final s = clamp(e.startPeriod);
          // Force endPeriod >= startPeriod so span is always >= 1.
          final ee = clamp(e.endPeriod < s ? s : e.endPeriod);
          return _ClampedEntry(s, ee, e);
        })
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final out = <_Segment>[];
    int cursor = 1;
    for (final ce in dayEntries) {
      // Skip entries that have already been fully covered by an earlier
      // overlapping entry — keeps the row width sane.
      if (ce.end < cursor) continue;
      final effectiveStart = ce.start < cursor ? cursor : ce.start;

      if (effectiveStart > cursor) {
        out.add(_Segment.blank(cursor, effectiveStart - 1));
      }
      out.add(_Segment.entry(ce.entry, effectiveStart, ce.end));
      cursor = ce.end + 1;
    }
    if (cursor <= 9) {
      out.add(_Segment.blank(cursor, 9));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EHadirTheme.card,
        border: Border.all(color: EHadirTheme.divider),
        borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
      ),
      child: Column(
        children: [
          // Header row: time labels
          Row(
            children: [
              const SizedBox(width: _kDayColW, height: _kHeaderH),
              for (final p in Period.all)
                Container(
                  width: _kPeriodW,
                  height: _kHeaderH,
                  decoration: BoxDecoration(
                    color: EHadirTheme.surfaceLight,
                    border: Border(
                      left: BorderSide(color: EHadirTheme.divider),
                      bottom: BorderSide(color: EHadirTheme.divider),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${p.index}',
                          style: const TextStyle(
                              color: EHadirTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                      Text(p.label(),
                          style: const TextStyle(
                              color: EHadirTheme.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
          // Rows per day
          for (final day in SchoolDay.values)
            Row(
              children: [
                Container(
                  width: _kDayColW,
                  height: _kRowH,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: EHadirTheme.surfaceLight,
                    border: Border(
                      top: BorderSide(color: EHadirTheme.divider),
                    ),
                  ),
                  child: Text(day.short,
                      style: const TextStyle(
                          color: EHadirTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
                ..._segmentsForDay(day)
                    .where((seg) => seg.span > 0)
                    .map((seg) {
                  final w = _kPeriodW * seg.span;
                  final cell = Container(
                    width: w,
                    height: _kRowH,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: EHadirTheme.divider),
                        top: BorderSide(color: EHadirTheme.divider),
                      ),
                      color: seg.entry == null
                          ? Colors.white
                          : EHadirTheme.primary.withValues(alpha: 0.06),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: seg.entry == null
                        ? const SizedBox.shrink()
                        : _EntryCell(entry: seg.entry!),
                  );
                  // Tappable when there's an entry → open Ambil Kehadiran
                  // for that subject/class.
                  if (seg.entry == null) return cell;
                  return InkWell(
                    onTap: () {
                      final e = seg.entry!;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AmbilKehadiranScreen(
                            subjectCode: e.subjectCode,
                            subjectName: e.subjectName,
                            studentClass: e.studentClass,
                            program: e.program,
                          ),
                        ),
                      );
                    },
                    child: cell,
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}

class _Segment {
  final int start;
  final int end;
  final TimetableEntry? entry;
  const _Segment._(this.start, this.end, this.entry);
  factory _Segment.blank(int s, int e) => _Segment._(s, e, null);
  factory _Segment.entry(TimetableEntry e, int s, int en) =>
      _Segment._(s, en, e);
  /// Never returns a negative value — guarantees safe box constraints.
  int get span {
    final v = end - start + 1;
    return v < 0 ? 0 : v;
  }
}

/// Internal: an entry with start/end periods already clamped into [1..9]
/// and start ≤ end. Used by [_TimetableGrid._segmentsForDay] so the row
/// layout never produces a negative width.
class _ClampedEntry {
  final int start;
  final int end;
  final TimetableEntry entry;
  const _ClampedEntry(this.start, this.end, this.entry);
}

class _EntryCell extends StatelessWidget {
  final TimetableEntry entry;
  const _EntryCell({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.room.isNotEmpty)
          Text(entry.room.toUpperCase(),
              style: const TextStyle(
                  color: EHadirTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(entry.subjectCode,
                    style: const TextStyle(
                        color: EHadirTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(entry.studentClass,
                    style: const TextStyle(
                        color: EHadirTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        Text(entry.lecturerName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: EHadirTheme.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}
