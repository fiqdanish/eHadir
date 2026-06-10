import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../services/auth_service.dart';
import '../../services/discipline_service.dart';
import '../../services/mock_db_service.dart';
import '../../models/discipline_report_model.dart';
import '../../models/student_model.dart';
import '../../theme.dart';

class LaporDisiplinScreen extends ConsumerStatefulWidget {
  /// When non-null, the form opens in edit mode and updates this report
  /// instead of creating a new one. Only allowed while [existing.status]
  /// is still `pending`.
  final DisciplineReportModel? existing;

  const LaporDisiplinScreen({super.key, this.existing});

  @override
  ConsumerState<LaporDisiplinScreen> createState() => _LaporDisiplinScreenState();
}

class _LaporDisiplinScreenState extends ConsumerState<LaporDisiplinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _uuid = const Uuid();
  bool _isSubmitting = false;

  String? _selectedStudentId;
  String? _selectedStudentName;
  String _selectedStudentClass = '';
  SeverityLevel _selectedSeverity = SeverityLevel.ringan;

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _selectedStudentId = e.studentId;
      _selectedStudentName = e.studentName;
      _selectedStudentClass = e.studentClass;
      _selectedSeverity = e.severityLevel;
      _descCtrl.text = e.issueDescription;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  /// Returns student IDs in [program] with 3+ Tidak Hadir ('T') marks
  /// across any subject. Pulled from the local StudentModel seed which
  /// mirrors what M1 writes.
  Set<String> _frequentAbsenteeIds(List<StudentModel> students) {
    const threshold = 3;
    final out = <String>{};
    for (final s in students) {
      int absences = 0;
      for (final weeks in s.attendanceBySubject.values) {
        absences += weeks.where((w) => w == 'T').length;
      }
      if (absences >= threshold) out.add(s.id);
    }
    return out;
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) {
      _showSnack('Sila pilih pelajar', EHadirTheme.rejected);
      return;
    }

    setState(() => _isSubmitting = true);

    final service = ref.read(disciplineServiceProvider);
    final auth = ref.read(authProvider);
    final current = auth.currentUser!;

    try {
      if (_isEditMode) {
        final updated = widget.existing!.copyWith(
          studentName: _selectedStudentName,
          studentId: _selectedStudentId,
          studentClass: _selectedStudentClass,
          issueDescription: _descCtrl.text.trim(),
          severityLevel: _selectedSeverity,
        );
        await service.updateReport(updated);
        if (!mounted) return;
        _showSnack('Laporan dikemaskini.', EHadirTheme.approved);
        Navigator.of(context).pop(true);
        return;
      }

      final report = DisciplineReportModel(
        id: _uuid.v4(),
        studentName: _selectedStudentName!,
        studentId: _selectedStudentId!,
        studentClass: _selectedStudentClass,
        issueDescription: _descCtrl.text.trim(),
        severityLevel: _selectedSeverity,
        program: current.program,
        reportedBy: current.id,
        reportedByName: current.name,
        reportedAt: DateTime.now(),
      );
      await service.submitReport(report);

      if (!mounted) return;
      setState(() {
        _descCtrl.clear();
        _selectedStudentId = null;
        _selectedStudentName = null;
        _selectedStudentClass = '';
        _selectedSeverity = SeverityLevel.ringan;
      });
      _showSnack(
        'Laporan disiplin berjaya dihantar ke Ketua Program & Ketua Jabatan.',
        EHadirTheme.approved,
      );
    } catch (e) {
      if (mounted) _showSnack('Ralat: $e', EHadirTheme.rejected);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(mockDbProvider);
    final auth = ref.watch(authProvider);
    final current = auth.currentUser!;
    final students = db.getStudentsForProgram(current.program);
    final flagged = _frequentAbsenteeIds(students);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Kemaskini Laporan' : 'Lapor Disiplin'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: EHadirTheme.pending.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
                  border: Border.all(color: EHadirTheme.pending.withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: EHadirTheme.pending),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEditMode
                            ? 'Anda sedang mengubah laporan yang belum disemak. Sebaik sahaja Ketua Program menyemaknya, perubahan tidak lagi dibenarkan.'
                            : 'Laporan ini akan terus dihantar kepada Ketua Program (${current.program}) dan Ketua Jabatan untuk tindakan lanjut.',
                        style: const TextStyle(
                          color: EHadirTheme.textPrimary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Frequent-absence suggestion strip (M1 → M2 link)
              if (flagged.isNotEmpty && !_isEditMode) ...[
                _label('Pelajar dengan kehadiran rendah (3+ Tidak Hadir)'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: students.where((s) => flagged.contains(s.id)).length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final s = students
                          .where((s) => flagged.contains(s.id))
                          .toList()[i];
                      final selected = _selectedStudentId == s.id;
                      return ActionChip(
                        avatar: const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: EHadirTheme.rejected,
                        ),
                        label: Text(s.name),
                        backgroundColor: selected
                            ? EHadirTheme.primary.withValues(alpha: 0.15)
                            : EHadirTheme.surfaceLight,
                        side: BorderSide(
                          color: selected
                              ? EHadirTheme.primary
                              : EHadirTheme.divider,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedStudentId = s.id;
                            _selectedStudentName = s.name;
                            _selectedStudentClass = s.studentClass;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Student
              _label('Pelajar'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: EHadirTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStudentId,
                    isExpanded: true,
                    hint: const Text(
                      'Pilih pelajar',
                      style: TextStyle(color: EHadirTheme.textSecondary),
                    ),
                    dropdownColor: EHadirTheme.card,
                    style: const TextStyle(color: EHadirTheme.textPrimary, fontSize: 15),
                    items: students.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          s.studentClass.isEmpty
                              ? s.name
                              : '${s.name}  ·  ${s.studentClass}',
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      final stu = students.firstWhere((s) => s.id == v);
                      setState(() {
                        _selectedStudentId = v;
                        _selectedStudentName = stu.name;
                        _selectedStudentClass = stu.studentClass;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Severity
              _label('Tahap Keterukan'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: EHadirTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(EHadirTheme.radiusMd),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SeverityLevel>(
                    value: _selectedSeverity,
                    isExpanded: true,
                    dropdownColor: EHadirTheme.card,
                    style: const TextStyle(color: EHadirTheme.textPrimary, fontSize: 15),
                    items: SeverityLevel.values.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: s.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(s.label),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedSeverity = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Description
              _label('Keterangan Isu'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 5,
                style: const TextStyle(color: EHadirTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Terangkan salah laku pelajar secara terperinci...',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Sila masukkan keterangan' : null,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReport,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_isEditMode ? Icons.save_rounded : Icons.send_rounded),
                  label: Text(
                    _isSubmitting
                        ? (_isEditMode ? 'Menyimpan...' : 'Menghantar...')
                        : (_isEditMode ? 'Kemaskini Laporan' : 'Hantar Laporan'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EHadirTheme.rejected,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: EHadirTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
