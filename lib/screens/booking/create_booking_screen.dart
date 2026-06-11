import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';
import '../../services/mock_db_service.dart';
import '../../models/booking.dart';
import '../../models/room.dart';
import '../../models/timetable_entry.dart';
import '../../models/lecturer_assignment.dart';
import '../../theme.dart';
import '../app_shell.dart';
import '../../services/curriculum_service.dart';

/// Module 6: 3-Step Booking Wizard (unified flow)
///
/// Step 1: Maklumat Kelas & Pensyarah
/// Step 2: Pilih Tarikh, Slot & Bilik (unified availability grid)
/// Step 3: Pengesahan & Hantar
///
/// Includes the AppShell bottom navigation bar so the user can switch tabs
/// without needing to press the back button.
class CreateBookingScreen extends ConsumerStatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  ConsumerState<CreateBookingScreen> createState() =>
      _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen>
    with SingleTickerProviderStateMixin {

  // ─── Step tracking ──────────────────────────────────────
  int _currentStep = 0;

  // ─── Step 1 state ───────────────────────────────────────
  LecturerAssignment? _selectedClass;
  List<LecturerAssignment> _myClasses = [];
  bool _loadingClasses = true;
  String? _lecturerId;
  String? _lecturerName;

  // ─── Step 2 state (unified) ─────────────────────────────
  DateTime? _selectedDate;
  String? _selectedRoom;
  /// Set of selected period indices (1..9) — must be contiguous in one row.
  Set<int> _selectedPeriods = {};

  // ─── Step 3 state ───────────────────────────────────────
  bool _isSubmitting = false;

  // ─── Animation ──────────────────────────────────────────
  late AnimationController _animController;
  late Animation<double>   _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(authProvider).currentUser;
      if (user != null && mounted) {
        setState(() {
          _lecturerId   = user.id;
          _lecturerName = user.name;
        });
        
        try {
          final currSvc = ref.read(curriculumServiceProvider);
          final classes = await currSvc.streamAssignmentsForLecturer(user.id).first;
          if (mounted) {
            setState(() {
              _myClasses = classes;
              _loadingClasses = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() => _loadingClasses = false);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────
  int _timeToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ─── Derived from selected periods ─────────────────────
  TimeOfDay get _startTime {
    if (_selectedPeriods.isEmpty) return const TimeOfDay(hour: 8, minute: 0);
    final minP = _selectedPeriods.reduce((a, b) => a < b ? a : b);
    return Period.byIndex(minP).start;
  }

  TimeOfDay get _endTime {
    if (_selectedPeriods.isEmpty) return const TimeOfDay(hour: 9, minute: 0);
    final maxP = _selectedPeriods.reduce((a, b) => a > b ? a : b);
    return Period.byIndex(maxP).end;
  }

  // ─── Validation ─────────────────────────────────────────
  bool get _isStep1Valid => _selectedClass != null;
  bool get _isStep2Valid =>
      _selectedDate != null &&
      _selectedRoom != null &&
      _selectedPeriods.isNotEmpty;

  // ═══════════════════════════════════════════════════════════
  //  BOTTOM NAV — mirrors AppShell
  // ═══════════════════════════════════════════════════════════

  void _onNavTap(int index, BuildContext context) {
    final shell = context.findAncestorStateOfType<AppShellState>();
    if (shell != null) {
      Navigator.pop(context);
      shell.navigateToTab(index);
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildBottomNav(BuildContext context) {
    const items = [
      (Icons.home_rounded,          'Utama'),
      (Icons.calendar_month_rounded,'Jadual'),
      (Icons.fact_check_rounded,    'Kehadiran'),
      (Icons.bar_chart_rounded,     'Laporan'),
      (Icons.person_rounded,        'Profil'),
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: EHadirTheme.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final (icon, label) = items[i];
            return GestureDetector(
              onTap: () => _onNavTap(i, context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Icon(
                  icon,
                  color: EHadirTheme.textSecondary,
                  size: 22,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SUBMIT LOGIC
  // ═══════════════════════════════════════════════════════════

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final bookingService = ref.read(firestoreBookingProvider);

    final booking = FirestoreBooking(
      id:           '',
      subjectName:  _selectedClass!.subjectName,
      subjectCode:  _selectedClass!.subjectCode,
      studentClass: _selectedClass!.studentClass,
      program:      _selectedClass!.program,
      lecturerId:   _lecturerId!,
      lecturerName: _lecturerName!,
      roomId:       _selectedRoom!,
      date:         _selectedDate!,
      startTime:    _timeToMinutes(_startTime),
      endTime:      _timeToMinutes(_endTime),
    );

    try {
      await bookingService.saveBooking(booking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Tempahan berjaya disimpan! ✅',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: EHadirTheme.approved,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } on BookingConflictException catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Konflik: ${e.message}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: EHadirTheme.rejected,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat: $e'),
            backgroundColor: EHadirTheme.rejected,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tempah Bilik'),
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _buildPageHeader(),
            const SizedBox(height: 24),
            _buildProgressIndicator(),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentStep(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: EHadirTheme.primaryGradient,
        borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
        boxShadow: EHadirTheme.glowShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
            ),
            child: const Icon(Icons.add_business_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tempahan Bilik Ganti',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Mohon bilik untuk kelas gantian',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Progress Indicator ─────────────────────────────────
  Widget _buildProgressIndicator() {
    final steps = ['Subjek', 'Slot & Bilik', 'Hantar'];
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i == _currentStep;
        final isDone   = i < _currentStep;
        final color    = isDone
            ? EHadirTheme.approved
            : isActive
                ? EHadirTheme.accent
                : EHadirTheme.divider;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: isDone || isActive ? color : Colors.transparent,
                      border: Border.all(color: color, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : Text('${i + 1}',
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : EHadirTheme.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              )),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(steps[i],
                      style: TextStyle(
                        color: isActive || isDone
                            ? EHadirTheme.textPrimary
                            : EHadirTheme.textSecondary,
                        fontSize: 11,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                      )),
                ],
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: isDone ? EHadirTheme.approved : EHadirTheme.divider,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStep1(key: const ValueKey(0));
      case 1: return _buildStep2(key: const ValueKey(1));
      case 2: return _buildStep3Confirm(key: const ValueKey(2));
      default: return const SizedBox.shrink();
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  STEP 1: MAKLUMAT KELAS (unchanged)
  // ═══════════════════════════════════════════════════════════
  Widget _buildStep1({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Maklumat Kelas'),
        const SizedBox(height: 16),

        // ── Lecturer display (read-only — auto-filled from login) ──
        _cardContainer(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: EHadirTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    color: EHadirTheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pensyarah',
                        style: TextStyle(
                            color: EHadirTheme.textSecondary,
                            fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      _lecturerName ?? '—',
                      style: const TextStyle(
                          color: EHadirTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: EHadirTheme.approved.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(EHadirTheme.radiusSm),
                ),
                child: const Text('Log masuk',
                    style: TextStyle(
                        color: EHadirTheme.approved,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Subject selection ──
        _cardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Kelas',
                  style: TextStyle(
                      color: EHadirTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              if (_loadingClasses)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_myClasses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: EHadirTheme.pending.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded,
                          color: EHadirTheme.pending),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Anda belum ditugaskan kepada mana-mana kelas. Sila hubungi Ketua Program.',
                          style: TextStyle(color: EHadirTheme.pending),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: EHadirTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<LecturerAssignment>(
                      value: _selectedClass,
                      isExpanded: true,
                      hint: const Text('Pilih kelas untuk diganti...',
                          style: TextStyle(color: EHadirTheme.textSecondary)),
                      dropdownColor: EHadirTheme.card,
                      style: const TextStyle(
                          color: EHadirTheme.textPrimary, fontSize: 14),
                      items: _myClasses
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text('${c.subjectCode} - ${c.subjectName} (${c.studentClass})'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedClass = v;
                        });
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _navButtons(canNext: _isStep1Valid),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  STEP 2: UNIFIED — PILIH TARIKH, SLOT & BILIK
  // ═══════════════════════════════════════════════════════════
  Widget _buildStep2({Key? key}) {
    final allRooms   = ref.read(mockDbProvider).rooms;
    final bookingSvc = ref.read(firestoreBookingProvider);

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Pilih Tarikh, Slot & Bilik'),
        const SizedBox(height: 4),
        const Text(
          'Pilih tarikh dahulu, kemudian tekan slot yang tersedia pada grid di bawah.',
          style: TextStyle(color: EHadirTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),

        // ── Date picker card ──────────────────────────────
        _cardContainer(
          child: InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: EHadirTheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
                  ),
                  child: const Icon(Icons.calendar_today_rounded,
                      color: EHadirTheme.accent, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tarikh',
                          style: TextStyle(
                              color: EHadirTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(
                        _selectedDate != null
                            ? DateFormat('EEEE, dd MMMM yyyy')
                                .format(_selectedDate!)
                            : 'Tekan untuk pilih tarikh',
                        style: TextStyle(
                          color: _selectedDate != null
                              ? EHadirTheme.textPrimary
                              : EHadirTheme.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: EHadirTheme.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Legend ────────────────────────────────────────
        Row(
          children: [
            _legendDot(const Color(0xFF10B981), 'Tersedia'),
            const SizedBox(width: 14),
            _legendDot(EHadirTheme.accent, 'Dipilih'),
            const SizedBox(width: 14),
            _legendDot(const Color(0xFFEF4444), 'Penuh'),
          ],
        ),
        const SizedBox(height: 12),

        // ── Availability Grid ─────────────────────────────
        if (_selectedDate == null)
          _emptyStateCard(
            icon: Icons.event_rounded,
            message: 'Sila pilih tarikh terlebih dahulu untuk melihat ketersediaan bilik.',
          )
        else
          StreamBuilder<Map<String, Set<int>>>(
            stream: bookingSvc.streamOccupiedSlots(_selectedDate!),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snap.hasError) {
                return _emptyStateCard(
                  icon: Icons.error_outline_rounded,
                  message: 'Gagal memuatkan ketersediaan: ${snap.error}',
                );
              }

              final occupiedMap = snap.data ?? {};

              return Container(
                decoration: BoxDecoration(
                  color: EHadirTheme.card,
                  borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
                  border: Border.all(color: EHadirTheme.divider),
                ),
                // ShaderMask fades right edge to hint at horizontal scrollability
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.white, Colors.white, Colors.transparent],
                    stops: [0.0, 0.82, 1.0],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header row: period labels ──
                        _buildGridHeader(),
                        // ── Room rows ──
                        ...allRooms.map((room) => _buildRoomRow(
                              room,
                              occupiedMap[room.name] ?? const <int>{},
                            )),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

        // ── Selection summary chip ───────────────────────
        if (_isStep2Valid) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EHadirTheme.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
              border: Border.all(
                  color: EHadirTheme.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: EHadirTheme.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$_selectedRoom  ·  ${_formatTime(_startTime)} – ${_formatTime(_endTime)}  ·  ${_calcDuration()}',
                    style: const TextStyle(
                      color: EHadirTheme.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 28),
        _navButtons(canNext: _isStep2Valid, showBack: true),
      ],
    );
  }

  // ─── Grid header (periods 1–9) ──────────────────────────
  static const double _kRoomColW  = 110;
  static const double _kCellW     = 70;
  static const double _kCellH     = 52;
  static const double _kHeaderH   = 48;

  Widget _buildGridHeader() {
    return Row(
      children: [
        Container(
          width: _kRoomColW,
          height: _kHeaderH,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: EHadirTheme.surfaceLight,
            border: Border(
              bottom: BorderSide(color: EHadirTheme.divider),
              right: BorderSide(color: EHadirTheme.divider),
            ),
          ),
          child: const Text('Bilik',
              style: TextStyle(
                  color: EHadirTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
        for (final p in Period.all)
          Container(
            width: _kCellW,
            height: _kHeaderH,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: EHadirTheme.surfaceLight,
              border: Border(
                bottom: BorderSide(color: EHadirTheme.divider),
                right: BorderSide(color: EHadirTheme.divider),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('P${p.index}',
                    style: const TextStyle(
                        color: EHadirTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
                Text(
                  '${p.start.hour.toString().padLeft(2, '0')}-${p.end.hour.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      color: EHadirTheme.textSecondary, fontSize: 9),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─── Single room row ────────────────────────────────────
  Widget _buildRoomRow(Room room, Set<int> occupiedPeriods) {
    return Row(
      children: [
        // Room name column
        Container(
          width: _kRoomColW,
          height: _kCellH,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: EHadirTheme.divider),
              right: BorderSide(color: EHadirTheme.divider),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                room.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: EHadirTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                room.building,
                style: const TextStyle(
                    color: EHadirTheme.textSecondary, fontSize: 9),
              ),
            ],
          ),
        ),
        // Period cells — pass occupiedPeriods so tap logic can validate ranges
        for (final p in Period.all)
          _buildCell(room.name, p.index, occupiedPeriods.contains(p.index), occupiedPeriods),
      ],
    );
  }

  // ─── Individual grid cell ───────────────────────────────
  Widget _buildCell(
      String roomName, int period, bool isOccupied, Set<int> roomOccupied) {
    final isSelected =
        _selectedRoom == roomName && _selectedPeriods.contains(period);

    Color bgColor;
    Color borderColor;
    Widget? child;

    if (isOccupied) {
      bgColor     = const Color(0xFFFEE2E2); // red-100
      borderColor = const Color(0xFFFCA5A5); // red-300
      child = const Text('Penuh',
          style: TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 9,
              fontWeight: FontWeight.w700));
    } else if (isSelected) {
      bgColor     = EHadirTheme.accent.withValues(alpha: 0.2);
      borderColor = EHadirTheme.accent;
      child = const Icon(Icons.check_rounded,
          color: EHadirTheme.accent, size: 18);
    } else {
      bgColor     = const Color(0xFFECFDF5); // emerald-50
      borderColor = const Color(0xFFA7F3D0); // emerald-200
      child = null; // empty = available
    }

    return GestureDetector(
      onTap: isOccupied
          ? null
          : () => _onCellTapped(roomName, period, roomOccupied),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: _kCellW,
        height: _kCellH,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            bottom: BorderSide(color: EHadirTheme.divider),
            right: BorderSide(color: borderColor.withValues(alpha: 0.5)),
          ),
        ),
        child: Center(child: child),
      ),
    );
  }

  /// Handle cell tap: select a contiguous range in the same room row.
  /// Validates that NO occupied period falls within the proposed range.
  void _onCellTapped(String roomName, int period, Set<int> roomOccupied) {
    setState(() {
      if (_selectedRoom != roomName) {
        // Switching rooms → reset selection to just this cell
        _selectedRoom = roomName;
        _selectedPeriods = {period};
      } else if (_selectedPeriods.contains(period)) {
        // Deselect this period
        _selectedPeriods.remove(period);
        if (_selectedPeriods.isEmpty) {
          _selectedRoom = null;
        }
      } else {
        // Extend selection: build contiguous range from existing + new period
        final allSelected = {..._selectedPeriods, period};
        final minP = allSelected.reduce((a, b) => a < b ? a : b);
        final maxP = allSelected.reduce((a, b) => a > b ? a : b);
        final proposedRange = {for (int i = minP; i <= maxP; i++) i};

        // Guard: ensure NO occupied cell falls within the proposed range.
        final hasConflictInRange =
            proposedRange.any((p) => roomOccupied.contains(p));

        if (hasConflictInRange) {
          // Blocked — just select the single tapped cell instead.
          _selectedRoom = roomName;
          _selectedPeriods = {period};
          // Show a brief in-context message via a snackbar
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Julat ini mengandungi slot yang penuh. Pilihan dihadkan ke slot ini sahaja.',
                  ),
                  duration: Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
        } else {
          // Safe — select the full contiguous range
          _selectedPeriods = proposedRange;
        }
      }
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  STEP 3: PENGESAHAN & HANTAR (was Step 4)
  // ═══════════════════════════════════════════════════════════
  Widget _buildStep3Confirm({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Pengesahan & Hantar'),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: EHadirTheme.cardGradient,
            borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
            border: Border.all(color: EHadirTheme.divider),
          ),
          child: Column(
            children: [
              _reviewRow(
                  Icons.book_rounded, 'Subjek', _selectedClass?.subjectName ?? '—'),
              _reviewDivider(),
              _reviewRow(
                  Icons.group_rounded, 'Kelas Pelajar', _selectedClass?.studentClass ?? '—'),
              _reviewDivider(),
              _reviewRow(Icons.person_rounded, 'Pensyarah',
                  _lecturerName ?? '—'),
              _reviewDivider(),
              _reviewRow(
                  Icons.event_rounded,
                  'Tarikh',
                  _selectedDate != null
                      ? DateFormat('EEEE, dd MMM yyyy')
                          .format(_selectedDate!)
                      : '—'),
              _reviewDivider(),
              _reviewRow(Icons.schedule_rounded, 'Masa',
                  '${_formatTime(_startTime)} – ${_formatTime(_endTime)}'),
              _reviewDivider(),
              _reviewRow(Icons.schedule_rounded, 'Tempoh', _calcDuration()),
              _reviewDivider(),
              _reviewRow(
                  Icons.room_rounded, 'Bilik', _selectedRoom ?? '—'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: EHadirTheme.accent,
              disabledBackgroundColor: EHadirTheme.surfaceLight,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Hantar',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _currentStep = 0),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Kembali untuk Sunting'),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SHARED WIDGETS & HELPERS
  // ═══════════════════════════════════════════════════════════

  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(
          color: EHadirTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ));
  }

  Widget _cardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EHadirTheme.card,
        borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
        border: Border.all(color: EHadirTheme.divider),
      ),
      child: child,
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: EHadirTheme.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _emptyStateCard({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EHadirTheme.surfaceLight,
        borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
        border: Border.all(color: EHadirTheme.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: EHadirTheme.textSecondary, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: EHadirTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: EHadirTheme.accent, size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: EHadirTheme.textSecondary, fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: EHadirTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _reviewDivider() =>
      const Divider(color: EHadirTheme.divider, height: 16);

  Widget _navButtons({required bool canNext, bool showBack = false}) {
    return Row(
      children: [
        if (showBack)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Kembali'),
            ),
          ),
        if (showBack) const SizedBox(width: 12),
        Expanded(
          flex: showBack ? 2 : 1,
          child: ElevatedButton(
            onPressed:
                canNext ? () => setState(() => _currentStep++) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: EHadirTheme.accent,
              disabledBackgroundColor: EHadirTheme.surfaceLight,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Seterusnya',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _calcDuration() {
    final diff = _timeToMinutes(_endTime) - _timeToMinutes(_startTime);
    if (diff <= 0) return '0';
    final hours = diff ~/ 60;
    final mins  = diff % 60;
    if (mins == 0) return '$hours jam';
    return '${hours}j ${mins}m';
  }

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: EHadirTheme.primary),
        ),
        child: child!,
      ),
    );
    if (dt != null) {
      setState(() {
        _selectedDate = dt;
        // Reset room/period selection when date changes
        _selectedRoom = null;
        _selectedPeriods = {};
      });
    }
  }
}
