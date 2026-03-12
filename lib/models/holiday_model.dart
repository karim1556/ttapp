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

  DateTime get dateTime => DateTime.tryParse(date) ?? DateTime.now();

  bool get isToday {
    final today = DateTime.now();
    final d = dateTime;
    return d.year == today.year && d.month == today.month && d.day == today.day;
  }

  bool get isUpcoming {
    final today = DateTime.now();
    final d = dateTime;
    return d.isAfter(DateTime(today.year, today.month, today.day));
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
