enum ConflictType { room, lecturer, cohort }

class ConflictDetail {
  final ConflictType type;
  final String description;
  final bool isHard; // hard = absolute block, soft = warning only
  final String? conflictingEntity; // e.g., room name, lecturer name, cohort code

  ConflictDetail({
    required this.type,
    required this.description,
    required this.isHard,
    this.conflictingEntity,
  });

  String get typeLabel {
    switch (type) {
      case ConflictType.room:
        return 'Room Conflict';
      case ConflictType.lecturer:
        return 'Schedule Conflict';
      case ConflictType.cohort:
        return 'Cohort Conflict';
    }
  }

  String get icon {
    switch (type) {
      case ConflictType.room:
        return '🏫';
      case ConflictType.lecturer:
        return '👨‍🏫';
      case ConflictType.cohort:
        return '👥';
    }
  }
}

class ConflictResult {
  final List<ConflictDetail> conflicts;

  ConflictResult({required this.conflicts});

  bool get hasConflicts => conflicts.isNotEmpty;
  bool get hasHardConflicts => conflicts.any((c) => c.isHard);
  bool get hasSoftConflictsOnly =>
      hasConflicts && !hasHardConflicts;

  List<ConflictDetail> get hardConflicts =>
      conflicts.where((c) => c.isHard).toList();
  List<ConflictDetail> get softConflicts =>
      conflicts.where((c) => !c.isHard).toList();

  static ConflictResult noConflicts() => ConflictResult(conflicts: []);
}
