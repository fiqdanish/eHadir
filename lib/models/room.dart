enum RoomType { lab, lectureHall, tutorialRoom, auditorium }

class Room {
  final String id;
  final String name;
  final String building;
  final int capacity;
  final RoomType type;
  final List<String> facilities; // e.g., ['projector', 'whiteboard', 'computers']

  Room({
    required this.id,
    required this.name,
    required this.building,
    required this.capacity,
    required this.type,
    this.facilities = const [],
  });

  String get displayName => '$name ($building)';

  String get typeLabel {
    switch (type) {
      case RoomType.lab:
        return 'Lab';
      case RoomType.lectureHall:
        return 'Lecture Hall';
      case RoomType.tutorialRoom:
        return 'Tutorial Room';
      case RoomType.auditorium:
        return 'Auditorium';
    }
  }
}
