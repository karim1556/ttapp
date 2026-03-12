class TimeSlotTemplateModel {
  final int id;
  final String? label;
  final int startTimeHr;
  final int startTimeMinutes;
  final int endTimeHr;
  final int endTimeMinutes;
  final int? isBreak;
  final int? sortOrder;
  final int? isActive;

  TimeSlotTemplateModel({
    required this.id,
    this.label,
    required this.startTimeHr,
    this.startTimeMinutes = 0,
    required this.endTimeHr,
    this.endTimeMinutes = 0,
    this.isBreak,
    this.sortOrder,
    this.isActive,
  });

  bool get active => isActive != 0;
  bool get breakSlot => isBreak == 1;

  /// Human-readable time range, e.g. "08:00 – 09:00"
  String get timeRange {
    final s = '${startTimeHr.toString().padLeft(2, '0')}:${startTimeMinutes.toString().padLeft(2, '0')}';
    final e = '${endTimeHr.toString().padLeft(2, '0')}:${endTimeMinutes.toString().padLeft(2, '0')}';
    return '$s – $e';
  }

  factory TimeSlotTemplateModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotTemplateModel(
      id: _parseInt(json['id']) ?? 0,
      label: json['label']?.toString(),
      startTimeHr: _parseInt(json['startTimeHr']) ?? _parseInt(json['start_time_hr']) ?? 8,
      startTimeMinutes: _parseInt(json['startTimeMinutes']) ?? _parseInt(json['start_time_minutes']) ?? 0,
      endTimeHr: _parseInt(json['endTimeHr']) ?? _parseInt(json['end_time_hr']) ?? 9,
      endTimeMinutes: _parseInt(json['endTimeMinutes']) ?? _parseInt(json['end_time_minutes']) ?? 0,
      isBreak: _parseInt(json['is_break']),
      sortOrder: _parseInt(json['sort_order']),
      isActive: _parseInt(json['is_active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'startTimeHr': startTimeHr,
      'startTimeMinutes': startTimeMinutes,
      'endTimeHr': endTimeHr,
      'endTimeMinutes': endTimeMinutes,
      'is_break': isBreak,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  TimeSlotTemplateModel copyWith({
    int? id,
    String? label,
    int? startTimeHr,
    int? startTimeMinutes,
    int? endTimeHr,
    int? endTimeMinutes,
    int? isBreak,
    int? sortOrder,
    int? isActive,
  }) {
    return TimeSlotTemplateModel(
      id: id ?? this.id,
      label: label ?? this.label,
      startTimeHr: startTimeHr ?? this.startTimeHr,
      startTimeMinutes: startTimeMinutes ?? this.startTimeMinutes,
      endTimeHr: endTimeHr ?? this.endTimeHr,
      endTimeMinutes: endTimeMinutes ?? this.endTimeMinutes,
      isBreak: isBreak ?? this.isBreak,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }
}
