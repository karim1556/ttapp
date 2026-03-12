class ConstraintModel {
  final int? id;
  final int facultyId;
  final int maxLecturesPerDay;
  final int totalLecturesPerWeek;
  final List<UnavailableSlot> unavailableSlots;
  final List<PreferredSlot> preferredSlots;

  ConstraintModel({
    this.id,
    required this.facultyId,
    required this.maxLecturesPerDay,
    required this.totalLecturesPerWeek,
    this.unavailableSlots = const [],
    this.preferredSlots = const [],
  });

  factory ConstraintModel.fromJson(Map<String, dynamic> json) {
    return ConstraintModel(
      id: _parseInt(json['id']),
      facultyId: _parseInt(json['faculty_id']) ?? 0,
      maxLecturesPerDay: _parseInt(json['max_lectures_per_day']) ?? 4,
      totalLecturesPerWeek: _parseInt(json['total_lectures_per_week']) ?? 16,
      unavailableSlots: (json['unavailable_slots'] as List<dynamic>?)
              ?.map((e) => UnavailableSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      preferredSlots: (json['preferred_slots'] as List<dynamic>?)
              ?.map((e) => PreferredSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'faculty_id': facultyId,
      'max_lectures_per_day': maxLecturesPerDay,
      'total_lectures_per_week': totalLecturesPerWeek,
      'unavailable_slots': unavailableSlots.map((e) => e.toJson()).toList(),
      'preferred_slots': preferredSlots.map((e) => e.toJson()).toList(),
    };
  }

  ConstraintModel copyWith({
    int? id,
    int? facultyId,
    int? maxLecturesPerDay,
    int? totalLecturesPerWeek,
    List<UnavailableSlot>? unavailableSlots,
    List<PreferredSlot>? preferredSlots,
  }) {
    return ConstraintModel(
      id: id ?? this.id,
      facultyId: facultyId ?? this.facultyId,
      maxLecturesPerDay: maxLecturesPerDay ?? this.maxLecturesPerDay,
      totalLecturesPerWeek: totalLecturesPerWeek ?? this.totalLecturesPerWeek,
      unavailableSlots: unavailableSlots ?? this.unavailableSlots,
      preferredSlots: preferredSlots ?? this.preferredSlots,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

class UnavailableSlot {
  final String day;
  final int startHour;
  final int startMinutes;
  final int endHour;
  final int endMinutes;

  UnavailableSlot({
    required this.day,
    required this.startHour,
    required this.startMinutes,
    required this.endHour,
    required this.endMinutes,
  });

  factory UnavailableSlot.fromJson(Map<String, dynamic> json) {
    return UnavailableSlot(
      day: json['day']?.toString() ?? '',
      startHour: json['start_hour'] is int ? json['start_hour'] : int.tryParse(json['start_hour'].toString()) ?? 0,
      startMinutes: json['start_minutes'] is int ? json['start_minutes'] : int.tryParse(json['start_minutes'].toString()) ?? 0,
      endHour: json['end_hour'] is int ? json['end_hour'] : int.tryParse(json['end_hour'].toString()) ?? 0,
      endMinutes: json['end_minutes'] is int ? json['end_minutes'] : int.tryParse(json['end_minutes'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'start_hour': startHour,
        'start_minutes': startMinutes,
        'end_hour': endHour,
        'end_minutes': endMinutes,
      };
}

class PreferredSlot {
  final String day;
  final int startHour;
  final int startMinutes;
  final int endHour;
  final int endMinutes;

  PreferredSlot({
    required this.day,
    required this.startHour,
    required this.startMinutes,
    required this.endHour,
    required this.endMinutes,
  });

  factory PreferredSlot.fromJson(Map<String, dynamic> json) {
    return PreferredSlot(
      day: json['day']?.toString() ?? '',
      startHour: json['start_hour'] is int ? json['start_hour'] : int.tryParse(json['start_hour'].toString()) ?? 0,
      startMinutes: json['start_minutes'] is int ? json['start_minutes'] : int.tryParse(json['start_minutes'].toString()) ?? 0,
      endHour: json['end_hour'] is int ? json['end_hour'] : int.tryParse(json['end_hour'].toString()) ?? 0,
      endMinutes: json['end_minutes'] is int ? json['end_minutes'] : int.tryParse(json['end_minutes'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'start_hour': startHour,
        'start_minutes': startMinutes,
        'end_hour': endHour,
        'end_minutes': endMinutes,
      };
}
