class LectureAssignmentModel {
  final int id;
  final int timeTableDetailedId;
  final String? typeOfLecture;
  final String? subjectCode;
  final int? facultyId;
  final String? batch;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;
  final int? isExtra;
  final int? lectOnBehalf;
  final String? reason;
  final String? roomNumber;

  // Populated from joins
  final String? subjectName;
  final String? facultyName;

  LectureAssignmentModel({
    required this.id,
    required this.timeTableDetailedId,
    this.typeOfLecture,
    this.subjectCode,
    this.facultyId,
    this.batch,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.isExtra,
    this.lectOnBehalf,
    this.reason,
    this.roomNumber,
    this.subjectName,
    this.facultyName,
  });

  bool get isLabLecture => typeOfLecture?.toLowerCase() == 'lab' || typeOfLecture?.toLowerCase() == 'practical';
  bool get isExtraLecture => isExtra == 1;
  bool get isSubstitution => lectOnBehalf == 1;

  factory LectureAssignmentModel.fromJson(Map<String, dynamic> json) {
    return LectureAssignmentModel(
      id: _parseInt(json['id']) ?? 0,
      timeTableDetailedId: _parseInt(json['time_table_detailed_id']) ?? 0,
      typeOfLecture: json['typeOfLecture']?.toString(),
      subjectCode: json['subjectCode']?.toString(),
      facultyId: _parseInt(json['facultyid']),
      batch: json['batch']?.toString(),
      createdBy: _parseInt(json['createdBy']),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      isExtra: _parseInt(json['is_extra']),
      lectOnBehalf: _parseInt(json['lect_on_dehalf']),
      reason: json['reason']?.toString(),
      roomNumber: json['room_number']?.toString(),
      subjectName: json['subject_name']?.toString(),
      facultyName: json['faculty_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time_table_detailed_id': timeTableDetailedId,
      'typeOfLecture': typeOfLecture,
      'subjectCode': subjectCode,
      'facultyid': facultyId,
      'batch': batch,
      'is_extra': isExtra,
      'lect_on_dehalf': lectOnBehalf,
      'reason': reason,
      'room_number': roomNumber,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
