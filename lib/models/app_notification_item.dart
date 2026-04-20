class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final String? payload;
  final String source; // push | local | system
  final String receivedAt;
  final bool isRead;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.payload,
    this.source = 'push',
    this.isRead = false,
  });

  DateTime? get receivedDateTime => DateTime.tryParse(receivedAt);

  AppNotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    String? payload,
    String? source,
    String? receivedAt,
    bool? isRead,
  }) {
    return AppNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      payload: payload ?? this.payload,
      source: source ?? this.source,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      payload: json['payload']?.toString(),
      source: json['source']?.toString() ?? 'push',
      receivedAt: json['receivedAt']?.toString() ?? json['received_at']?.toString() ?? DateTime.now().toIso8601String(),
      isRead: _parseBool(json['isRead']) ?? _parseBool(json['is_read']) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
      'source': source,
      'receivedAt': receivedAt,
      'isRead': isRead,
    };
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return null;
  }
}
