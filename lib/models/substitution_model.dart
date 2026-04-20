class SubstitutionRecordModel {
  final int id;
  final int lectureId;
  final int slotId;
  final String date; // yyyy-MM-dd
  final String dayName;
  final int? originalFacultyId;
  final String? originalFacultyName;
  final int substituteFacultyId;
  final String? substituteFacultyName;
  final String? subjectCode;
  final String? subjectName;
  final String? roomNumber;
  final String? batch;
  final String? lectureType;
  final String status; // pending | approved | rejected | cancelled
  final String? reason;
  final int? approvedBy;
  final String? createdAt;
  final String? approvedAt;
  final bool temporaryOnly;

  const SubstitutionRecordModel({
    required this.id,
    required this.lectureId,
    required this.slotId,
    required this.date,
    required this.dayName,
    required this.substituteFacultyId,
    this.originalFacultyId,
    this.originalFacultyName,
    this.substituteFacultyName,
    this.subjectCode,
    this.subjectName,
    this.roomNumber,
    this.batch,
    this.lectureType,
    this.status = 'pending',
    this.reason,
    this.approvedBy,
    this.createdAt,
    this.approvedAt,
    this.temporaryOnly = true,
  });

  String get normalizedStatus => status.trim().toLowerCase();
  bool get isApproved => normalizedStatus == 'approved';
  bool get isPending => normalizedStatus == 'pending';

  DateTime? get parsedDate {
    if (date.trim().isEmpty) return null;
    return DateTime.tryParse(date.trim());
  }

  bool matchesDate(DateTime target) {
    final d = parsedDate;
    if (d == null) return false;
    return d.year == target.year && d.month == target.month && d.day == target.day;
  }

  SubstitutionRecordModel copyWith({
    int? id,
    int? lectureId,
    int? slotId,
    String? date,
    String? dayName,
    int? originalFacultyId,
    String? originalFacultyName,
    int? substituteFacultyId,
    String? substituteFacultyName,
    String? subjectCode,
    String? subjectName,
    String? roomNumber,
    String? batch,
    String? lectureType,
    String? status,
    String? reason,
    int? approvedBy,
    String? createdAt,
    String? approvedAt,
    bool? temporaryOnly,
  }) {
    return SubstitutionRecordModel(
      id: id ?? this.id,
      lectureId: lectureId ?? this.lectureId,
      slotId: slotId ?? this.slotId,
      date: date ?? this.date,
      dayName: dayName ?? this.dayName,
      originalFacultyId: originalFacultyId ?? this.originalFacultyId,
      originalFacultyName: originalFacultyName ?? this.originalFacultyName,
      substituteFacultyId: substituteFacultyId ?? this.substituteFacultyId,
      substituteFacultyName: substituteFacultyName ?? this.substituteFacultyName,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      roomNumber: roomNumber ?? this.roomNumber,
      batch: batch ?? this.batch,
      lectureType: lectureType ?? this.lectureType,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      temporaryOnly: temporaryOnly ?? this.temporaryOnly,
    );
  }

  factory SubstitutionRecordModel.fromJson(Map<String, dynamic> json) {
    return SubstitutionRecordModel(
      id: _parseInt(json['id']) ?? 0,
      lectureId: _parseInt(json['lectureId']) ?? _parseInt(json['lecture_id']) ?? 0,
      slotId: _parseInt(json['slotId']) ?? _parseInt(json['slot_id']) ?? 0,
      date: json['date']?.toString() ?? '',
      dayName: json['dayName']?.toString() ?? json['day_name']?.toString() ?? '',
      originalFacultyId: _parseInt(json['originalFacultyId']) ?? _parseInt(json['original_faculty_id']),
      originalFacultyName: json['originalFacultyName']?.toString() ?? json['original_faculty_name']?.toString(),
      substituteFacultyId:
          _parseInt(json['substituteFacultyId']) ?? _parseInt(json['substitute_faculty_id']) ?? 0,
      substituteFacultyName: json['substituteFacultyName']?.toString() ?? json['substitute_faculty_name']?.toString(),
      subjectCode: json['subjectCode']?.toString() ?? json['subject_code']?.toString(),
      subjectName: json['subjectName']?.toString() ?? json['subject_name']?.toString(),
      roomNumber: json['roomNumber']?.toString() ?? json['room_number']?.toString(),
      batch: json['batch']?.toString(),
      lectureType: json['lectureType']?.toString() ?? json['lecture_type']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      reason: json['reason']?.toString(),
      approvedBy: _parseInt(json['approvedBy']) ?? _parseInt(json['approved_by']),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
      approvedAt: json['approvedAt']?.toString() ?? json['approved_at']?.toString(),
      temporaryOnly: _parseBool(json['temporaryOnly']) ?? _parseBool(json['temporary_only']) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lectureId': lectureId,
      'slotId': slotId,
      'date': date,
      'dayName': dayName,
      'originalFacultyId': originalFacultyId,
      'originalFacultyName': originalFacultyName,
      'substituteFacultyId': substituteFacultyId,
      'substituteFacultyName': substituteFacultyName,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'roomNumber': roomNumber,
      'batch': batch,
      'lectureType': lectureType,
      'status': status,
      'reason': reason,
      'approvedBy': approvedBy,
      'createdAt': createdAt,
      'approvedAt': approvedAt,
      'temporaryOnly': temporaryOnly,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
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

class SubstitutionCandidateModel {
  final int facultyId;
  final String facultyName;
  final double score;
  final bool hasConflict;
  final int weeklyLoad;
  final String summary;

  const SubstitutionCandidateModel({
    required this.facultyId,
    required this.facultyName,
    required this.score,
    required this.hasConflict,
    required this.weeklyLoad,
    required this.summary,
  });

  bool get isRecommended => !hasConflict;

  factory SubstitutionCandidateModel.fromJson(Map<String, dynamic> json) {
    return SubstitutionCandidateModel(
      facultyId: _parseInt(json['facultyId']) ?? _parseInt(json['faculty_id']) ?? 0,
      facultyName: json['facultyName']?.toString() ?? json['faculty_name']?.toString() ?? 'Faculty',
      score: _parseDouble(json['score']) ?? 0,
      hasConflict: _parseBool(json['hasConflict']) ?? _parseBool(json['has_conflict']) ?? false,
      weeklyLoad: _parseInt(json['weeklyLoad']) ?? _parseInt(json['weekly_load']) ?? 0,
      summary: json['summary']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'facultyId': facultyId,
      'facultyName': facultyName,
      'score': score,
      'hasConflict': hasConflict,
      'weeklyLoad': weeklyLoad,
      'summary': summary,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
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
