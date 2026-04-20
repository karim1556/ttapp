class HolidayModel {
  final int id;
  final String date;
  final String name;
  final String? type;
  final String? description;

  HolidayModel({
    required this.id,
    required this.date,
    required this.name,
    this.type,
    this.description,
  });

  /// Parsed as a date-only value in local time (time portion removed).
  DateTime? get parsedDate {
    final trimmed = date.trim();
    if (trimmed.isEmpty) return null;

    final iso = DateTime.tryParse(trimmed);
    if (iso != null) {
      final local = iso.toLocal();
      return DateTime(local.year, local.month, local.day);
    }

    final parts = trimmed.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  DateTime get dateTime => parsedDate ?? DateTime.fromMillisecondsSinceEpoch(0);

  bool get isToday {
    final d = parsedDate;
    if (d == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return d.year == today.year && d.month == today.month && d.day == today.day;
  }

  bool get isUpcoming {
    final d = parsedDate;
    if (d == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !d.isBefore(today);
  }

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      id: _parseInt(json['id']) ?? 0,
      date: json['date']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'name': name,
      'type': type,
      'description': description,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
