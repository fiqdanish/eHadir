import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/mock_db_service.dart';
import '../../services/booking_service.dart';
import '../../models/booking.dart';
import '../../models/room.dart';
import '../../models/conflict_result.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  ConsumerState<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen>
    with SingleTickerProviderStateMixin {
  // ─── Form state ───────────────────────────────────────────
  int _currentStep = 0;
  DateTime? _selectedDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  String? _selectedRoom;
  String? _selectedSubject;
  String? _selectedCohort;
  String _remarks = '';
  BookingType _bookingType = BookingType.replacement;

  // ─── Conflict state ───────────────────────────────────────
  ConflictResult? _conflictResult;
  bool _isSubmitting = false;
  bool _submitted = false;
  String _successMessage = '';

  // ─── Animation ────────────────────────────────────────────
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _isStep1Valid => _selectedDate != null;
  bool get _isStep2Valid => _selectedRoom != null;
  bool get _isStep3Valid => _selectedSubject != null && _selectedCohort != null;

  void _runConflictCheck() {
    if (!_isStep1Valid || !_isStep2Valid || !_isStep3Valid) return;

    final bookingService = ref.read(bookingProvider);
    final proposed = _buildBooking();
    setState(() {
      _conflictResult = bookingService.checkAllConflicts(proposed);
    });
  }

  Booking _buildBooking() {
    final authState = ref.read(authProvider);
    return Booking(
      id: '',
      lecturerId: authState.currentUser?.id ?? '',
      type: _bookingType,
      subject: _selectedSubject!,
      cohort: _selectedCohort!,
      room: _selectedRoom!,
      date: _selectedDate!,
      startTime: _startTime,
      endTime: _endTime,
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
      remarks: _remarks.isNotEmpty ? _remarks : null,
    );
  }

  Future<void> _submitBooking({bool forceSubmit = false}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final bookingService = ref.read(bookingProvider);
    try {
      final saved = await bookingService.submitBooking(
        _buildBooking(),
        forceSubmit: forceSubmit,
      );
      setState(() {
        _submitted = true;
        _isSubmitting = false;
        _successMessage = saved.status == BookingStatus.approved
            ? 'Booking auto-approved! No conflicts detected. ✅'
            : 'Booking submitted for admin review. ⏳';
      });
    } on BookingConflictException catch (e) {
      setState(() {
        _conflictResult = e.conflicts;
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: EHadirTheme.rejected,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: EHadirTheme.rejected),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _selectedDate = null;
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 11, minute: 0);
      _selectedRoom = null;
      _selectedSubject = null;
      _selectedCohort = null;
      _remarks = '';
      _conflictResult = null;
      _submitted = false;
      _successMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccessView();

    return FadeTransition(
      opacity: _fadeIn,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          _buildPageHeader(),
          const SizedBox(height: 20),
          _buildProgressIndicator(),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStep(),
          ),
        ],
      ),
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
            child: const Icon(Icons.add_business_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Booking Request',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Request a replacement or rescheduled class',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final steps = ['Date & Time', 'Room', 'Details', 'Review'];
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i == _currentStep;
        final isDone = i < _currentStep;
        final color = isDone
            ? EHadirTheme.approved
            : isActive
                ? EHadirTheme.accent
                : EHadirTheme.divider;

        return Expanded(
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone || isActive ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : EHadirTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
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
      case 0:
        return _buildStep1DateAndTime(key: const ValueKey(0));
      case 1:
        return _buildStep2RoomSelection(key: const ValueKey(1));
      case 2:
        return _buildStep3Details(key: const ValueKey(2));
      case 3:
        return _buildStep4Review(key: const ValueKey(3));
      default:
        return const SizedBox.shrink();
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  STEP 1: DATE & TIME
  // ═══════════════════════════════════════════════════════════
  Widget _buildStep1DateAndTime({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Select Date & Time'),
        const SizedBox(height: 16),

        // Booking type
        _cardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Booking Type', style: TextStyle(color: EHadirTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _typeChip('Replacement', BookingType.replacement),
                  const SizedBox(width: 10),
                  _typeChip('Reschedule', BookingType.reschedule),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Date picker
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
                  child: const Icon(Icons.calendar_today_rounded, color: EHadirTheme.accent, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date', style: TextStyle(color: EHadirTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(
                        _selectedDate != null
                            ? DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate!)
                            : 'Tap to select date',
                        style: TextStyle(
                          color: _selectedDate != null ? EHadirTheme.textPrimary : EHadirTheme.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: EHadirTheme.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Time range
        Row(
          children: [
            Expanded(
              child: _cardContainer(
                child: InkWell(
                  onTap: () => _pickTime(isStart: true),
                  borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
                  child: Column(
                    children: [
                      const Text('Start Time', style: TextStyle(color: EHadirTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(
                        _formatTimeOfDay(_startTime),
                        style: const TextStyle(
                          color: EHadirTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward_rounded, color: EHadirTheme.textSecondary),
            ),
            Expanded(
              child: _cardContainer(
                child: InkWell(
                  onTap: () => _pickTime(isStart: false),
                  borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
                  child: Column(
                    children: [
                      const Text('End Time', style: TextStyle(color: EHadirTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(
                        _formatTimeOfDay(_endTime),
                        style: const TextStyle(
                          color: EHadirTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Duration display
        if (_endTime.hour * 60 + _endTime.minute > _startTime.hour * 60 + _startTime.minute)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: EHadirTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
              ),
              child: Text(
                'Duration: ${_calculateDuration()} hours',
                style: const TextStyle(color: EHadirTheme.accent, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        const SizedBox(height: 24),
        _navigationButtons(canNext: _isStep1Valid),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  STEP 2: ROOM SELECTION
  // ═══════════════════════════════════════════════════════════
  Widget _buildStep2RoomSelection({Key? key}) {
    final db = ref.read(mockDbProvider);
    final availableRooms = _selectedDate != null
        ? db.getAvailableRooms(_selectedDate!, _startTime, _endTime)
        : <Room>[];
    final allRooms = db.rooms;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Select Room'),
        const SizedBox(height: 8),
        Text(
          'Showing availability for ${_selectedDate != null ? DateFormat('dd MMM').format(_selectedDate!) : '—'}, '
          '${_formatTimeOfDay(_startTime)}–${_formatTimeOfDay(_endTime)}',
          style: const TextStyle(color: EHadirTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ...allRooms.map((room) {
          final isAvailable = availableRooms.any((r) => r.id == room.id);
          final isSelected = _selectedRoom == room.name;

          return GestureDetector(
            onTap: isAvailable ? () => setState(() => _selectedRoom = room.name) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? EHadirTheme.accent.withValues(alpha: 0.15)
                    : EHadirTheme.card,
                borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
                border: Border.all(
                  color: isSelected
                      ? EHadirTheme.accent
                      : isAvailable
                          ? EHadirTheme.divider
                          : EHadirTheme.rejected.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Availability indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAvailable ? EHadirTheme.approved : EHadirTheme.rejected,
                      boxShadow: [
                        BoxShadow(
                          color: (isAvailable ? EHadirTheme.approved : EHadirTheme.rejected)
                              .withValues(alpha: 0.4),
                          blurRadius: 6,
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
                          room.name,
                          style: TextStyle(
                            color: isAvailable ? EHadirTheme.textPrimary : EHadirTheme.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${room.building} · ${room.typeLabel} · ${room.capacity} pax',
                          style: TextStyle(
                            color: isAvailable
                                ? EHadirTheme.textSecondary
                                : EHadirTheme.textSecondary.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAvailable)
                    const Text('Available', style: TextStyle(color: EHadirTheme.approved, fontSize: 12, fontWeight: FontWeight.w600))
                  else
                    const Text('Occupied', style: TextStyle(color: EHadirTheme.rejected, fontSize: 12, fontWeight: FontWeight.w600)),
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.check_circle_rounded, color: EHadirTheme.accent, size: 22),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        _navigationButtons(canNext: _isStep2Valid, showBack: true),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  STEP 3: DETAILS
  // ═══════════════════════════════════════════════════════════
  Widget _buildStep3Details({Key? key}) {
    final db = ref.read(mockDbProvider);
    final user = ref.read(authProvider).currentUser;
    final subjects = db.getSubjectsForLecturer(user?.id ?? '');
    final cohorts = db.getCohortsForLecturer(user?.id ?? '');

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Class Details'),
        const SizedBox(height: 16),

        // Subject dropdown
        _cardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Subject', style: TextStyle(color: EHadirTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subjects.map((s) {
                  final selected = _selectedSubject == s;
                  return ChoiceChip(
                    label: Text(s),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedSubject = s),
                    selectedColor: EHadirTheme.accent.withValues(alpha: 0.3),
                    checkmarkColor: EHadirTheme.accent,
                    labelStyle: TextStyle(
                      color: selected ? EHadirTheme.accent : EHadirTheme.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Cohort dropdown
        _cardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cohort', style: TextStyle(color: EHadirTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cohorts.map((c) {
                  final selected = _selectedCohort == c;
                  return ChoiceChip(
                    label: Text(c),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCohort = c),
                    selectedColor: EHadirTheme.accent.withValues(alpha: 0.3),
                    checkmarkColor: EHadirTheme.accent,
                    labelStyle: TextStyle(
                      color: selected ? EHadirTheme.accent : EHadirTheme.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Remarks
        _cardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Remarks (Optional)', style: TextStyle(color: EHadirTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 10),
              TextField(
                onChanged: (v) => _remarks = v,
                maxLines: 3,
                style: const TextStyle(color: EHadirTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Add any notes about this booking...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _navigationButtons(canNext: _isStep3Valid, showBack: true),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  STEP 4: REVIEW & SUBMIT
  // ═══════════════════════════════════════════════════════════
  Widget _buildStep4Review({Key? key}) {
    // Run conflict check when entering review step
    if (_conflictResult == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runConflictCheck());
    }

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Review & Submit'),
        const SizedBox(height: 16),

        // Summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: EHadirTheme.cardGradient,
            borderRadius: BorderRadius.circular(EHadirTheme.radiusLg),
            border: Border.all(color: EHadirTheme.divider),
          ),
          child: Column(
            children: [
              _reviewRow(Icons.event_rounded, 'Date',
                  _selectedDate != null ? DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate!) : '—'),
              _reviewDivider(),
              _reviewRow(Icons.schedule_rounded, 'Time',
                  '${_formatTimeOfDay(_startTime)} – ${_formatTimeOfDay(_endTime)}'),
              _reviewDivider(),
              _reviewRow(Icons.room_rounded, 'Room', _selectedRoom ?? '—'),
              _reviewDivider(),
              _reviewRow(Icons.book_rounded, 'Subject', _selectedSubject ?? '—'),
              _reviewDivider(),
              _reviewRow(Icons.group_rounded, 'Cohort', _selectedCohort ?? '—'),
              _reviewDivider(),
              _reviewRow(Icons.swap_horiz_rounded, 'Type',
                  _bookingType == BookingType.replacement ? 'Replacement Class' : 'Rescheduled Class'),
              if (_remarks.isNotEmpty) ...[
                _reviewDivider(),
                _reviewRow(Icons.notes_rounded, 'Remarks', _remarks),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Conflict analysis
        if (_conflictResult != null) _buildConflictPanel(),
        const SizedBox(height: 24),

        // Submit buttons
        if (_conflictResult == null || !_conflictResult!.hasHardConflicts) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () => _submitBooking(
                        forceSubmit: _conflictResult?.hasConflicts ?? false,
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _conflictResult?.hasConflicts == true
                    ? EHadirTheme.pending
                    : EHadirTheme.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _conflictResult?.hasConflicts == true
                          ? 'Submit for Admin Review'
                          : 'Submit Booking',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EHadirTheme.rejected.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
              border: Border.all(color: EHadirTheme.rejected.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.block_rounded, color: EHadirTheme.rejected),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cannot submit — hard conflicts detected. Please go back and choose a different room or time.',
                    style: TextStyle(color: EHadirTheme.rejected, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() {
              _currentStep = 0;
              _conflictResult = null;
            }),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Go Back to Edit'),
          ),
        ),
      ],
    );
  }

  Widget _buildConflictPanel() {
    final result = _conflictResult!;
    if (!result.hasConflicts) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EHadirTheme.approved.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
          border: Border.all(color: EHadirTheme.approved.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: EHadirTheme.approved, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No Conflicts Detected',
                      style: TextStyle(color: EHadirTheme.approved, fontSize: 15, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('This booking will be auto-approved immediately.',
                      style: TextStyle(color: EHadirTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (result.hasHardConflicts ? EHadirTheme.rejected : EHadirTheme.pending)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
            border: Border.all(
              color: (result.hasHardConflicts ? EHadirTheme.rejected : EHadirTheme.pending)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                result.hasHardConflicts ? Icons.error_rounded : Icons.warning_amber_rounded,
                color: result.hasHardConflicts ? EHadirTheme.rejected : EHadirTheme.pending,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.hasHardConflicts
                      ? '${result.conflicts.length} conflict(s) found — submission blocked'
                      : '${result.conflicts.length} warning(s) — you can still submit for review',
                  style: TextStyle(
                    color: result.hasHardConflicts ? EHadirTheme.rejected : EHadirTheme.pending,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...result.conflicts.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EHadirTheme.surfaceLight,
                borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
                border: Border(
                  left: BorderSide(
                    color: c.isHard ? EHadirTheme.rejected : EHadirTheme.pending,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(c.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.typeLabel,
                          style: TextStyle(
                            color: c.isHard ? EHadirTheme.rejected : EHadirTheme.pending,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(c.description,
                            style: const TextStyle(color: EHadirTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (c.isHard ? EHadirTheme.rejected : EHadirTheme.pending)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      c.isHard ? 'BLOCKED' : 'WARNING',
                      style: TextStyle(
                        color: c.isHard ? EHadirTheme.rejected : EHadirTheme.pending,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SUCCESS VIEW
  // ═══════════════════════════════════════════════════════════
  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: child,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EHadirTheme.approved.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.check_circle_rounded, color: EHadirTheme.approved, size: 72),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _successMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: EHadirTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Booking for ${_selectedSubject ?? ''} in ${_selectedRoom ?? ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: EHadirTheme.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              onPressed: _resetForm,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Another Booking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EHadirTheme.accent,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  HELPERS & SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: EHadirTheme.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    );
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

  Widget _typeChip(String label, BookingType type) {
    final selected = _bookingType == type;
    return GestureDetector(
      onTap: () => setState(() => _bookingType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? EHadirTheme.accent.withValues(alpha: 0.2) : EHadirTheme.surfaceLight,
          borderRadius: BorderRadius.circular(EHadirTheme.radiusSm),
          border: Border.all(
            color: selected ? EHadirTheme.accent : EHadirTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? EHadirTheme.accent : EHadirTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _reviewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: EHadirTheme.accent, size: 20),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: EHadirTheme.textSecondary, fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: EHadirTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _reviewDivider() {
    return const Divider(color: EHadirTheme.divider, height: 16);
  }

  Widget _navigationButtons({required bool canNext, bool showBack = false}) {
    return Row(
      children: [
        if (showBack)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _currentStep--;
                _conflictResult = null;
              }),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back'),
            ),
          ),
        if (showBack) const SizedBox(width: 12),
        Expanded(
          flex: showBack ? 2 : 1,
          child: ElevatedButton(
            onPressed: canNext
                ? () => setState(() => _currentStep++)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: EHadirTheme.accent,
              disabledBackgroundColor: EHadirTheme.surfaceLight,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _calculateDuration() {
    final diff = (_endTime.hour * 60 + _endTime.minute) - (_startTime.hour * 60 + _startTime.minute);
    if (diff <= 0) return '0';
    final hours = diff ~/ 60;
    final mins = diff % 60;
    if (mins == 0) return '$hours';
    return '${hours}h ${mins}m';
  }

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) => Theme(
        data: EHadirTheme.darkTheme.copyWith(
          colorScheme: EHadirTheme.darkTheme.colorScheme.copyWith(
            primary: EHadirTheme.accent,
          ),
        ),
        child: child!,
      ),
    );
    if (dt != null) {
      setState(() {
        _selectedDate = dt;
        _selectedRoom = null; // Reset room on date change
        _conflictResult = null;
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) => Theme(
        data: EHadirTheme.darkTheme.copyWith(
          colorScheme: EHadirTheme.darkTheme.colorScheme.copyWith(
            primary: EHadirTheme.accent,
          ),
        ),
        child: child!,
      ),
    );
    if (t != null) {
      setState(() {
        if (isStart) {
          _startTime = t;
        } else {
          _endTime = t;
        }
        _selectedRoom = null; // Reset room on time change
        _conflictResult = null;
      });
    }
  }
}
