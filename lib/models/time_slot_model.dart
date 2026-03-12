import 'lecture_assignment_model.dart';

class TimeSlotModel {
  final int id;
  final int timetableId;
  final int startTimeHr;
  final int startTimeMinutes;
  final int endTimeHr;
  final int endTimeMinutes;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  // Populated from join
  List<LectureAssignmentModel> lectures;

  TimeSlotModel({
    required this.id,
    required this.timetableId,
    required this.startTimeHr,
    required this.startTimeMinutes,
    required this.endTimeHr,
    required this.endTimeMinutes,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.lectures = const [],
  });

  String get startTimeDisplay {
    final h = startTimeHr.toString().padLeft(2, '0');
    final m = startTimeMinutes.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get endTimeDisplay {
    final h = endTimeHr.toString().padLeft(2, '0');
    final m = endTimeMinutes.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get timeRangeDisplay => '$startTimeDisplay – $endTimeDisplay';

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: _parseInt(json['id']) ?? 0,
      timetableId: _parseInt(json['timetable_id']) ?? 0,
      startTimeHr: _parseInt(json['startTimeHr']) ?? 0,
      startTimeMinutes: _parseInt(json['startTimeMinutes']) ?? 0,
      endTimeHr: _parseInt(json['endTimeHr']) ?? 0,
      endTimeMinutes: _parseInt(json['endTimeMinutes']) ?? 0,
      createdBy: _parseInt(json['createdBy']),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      lectures: (json['lectures'] as List<dynamic>?)
              ?.map((e) => LectureAssignmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timetable_id': timetableId,
      'startTimeHr': startTimeHr,
      'startTimeMinutes': startTimeMinutes,
      'endTimeHr': endTimeHr,
      'endTimeMinutes': endTimeMinutes,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
