enum NotificationType {
  bookingApproved,
  bookingRejected,
  bookingSubmitted,
  absenteeismWarning5,
  absenteeismWarning10,
  absenteeismWarning20,
}

class AppNotification {
  final String id;
  final String recipientId;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedBookingId;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.relatedBookingId,
  });

  AppNotification copyWith({
    String? id,
    String? recipientId,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? relatedBookingId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      relatedBookingId: relatedBookingId ?? this.relatedBookingId,
    );
  }
}
