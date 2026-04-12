enum NotificationType { order, promo, delivery, general }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime receivedAt;
  final bool isRead;
  final Map<String, dynamic> data;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.receivedAt,
    this.isRead = false,
    this.data = const {},
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        receivedAt: receivedAt,
        isRead: isRead ?? this.isRead,
        data: data,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.name,
        'receivedAt': receivedAt.toIso8601String(),
        'isRead': isRead,
        'data': data,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: NotificationType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => NotificationType.general,
        ),
        receivedAt: DateTime.parse(json['receivedAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
        data: (json['data'] as Map<String, dynamic>?) ?? {},
      );

  static NotificationType typeFromData(Map<String, dynamic> data) {
    final type = (data['type'] ?? data['notificationType'] ?? '').toString().toLowerCase();
    if (type.contains('order')) return NotificationType.order;
    if (type.contains('delivery') || type.contains('ship')) return NotificationType.delivery;
    if (type.contains('promo') || type.contains('offer') || type.contains('discount')) {
      return NotificationType.promo;
    }
    return NotificationType.general;
  }
}
