class TemporaryTimeSlot {
  final int id;
  final int branchId;
  final int semester;
  final String division;
  final DateTime date;
  final int startTimeHr;
  final int startTimeMinutes;
  final int endTimeHr;
  final int endTimeMinutes;
  final String? subjectCode;
  final int? facultyId;
  final String? roomNumber;
  final String? typeOfLecture;
  final String? eventName;
  final String? description;

  TemporaryTimeSlot({
    required this.id,
    required this.branchId,
    required this.semester,
    required this.division,
    required this.date,
    required this.startTimeHr,
    required this.startTimeMinutes,
    required this.endTimeHr,
    required this.endTimeMinutes,
    this.subjectCode,
    this.facultyId,
    this.roomNumber,
    this.typeOfLecture,
    this.eventName,
    this.description,
  });

  factory TemporaryTimeSlot.fromJson(Map<String, dynamic> json) {
    return TemporaryTimeSlot(
      id: json['id'] as int,
      branchId: json['branch_id'] as int,
      semester: json['semester'] as int,
      division: json['division'] as String,
      date: DateTime.parse(json['date'] as String),
      startTimeHr: json['startTimeHr'] as int,
      startTimeMinutes: json['startTimeMinutes'] as int,
      endTimeHr: json['endTimeHr'] as int,
      endTimeMinutes: json['endTimeMinutes'] as int,
      subjectCode: json['subjectCode'] as String?,
      facultyId: json['facultyid'] as int?,
      roomNumber: json['room_number'] as String?,
      typeOfLecture: json['typeOfLecture'] as String?,
      eventName: json['eventName'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_id': branchId,
      'semester': semester,
      'division': division,
      'date': date.toIso8601String(),
      'startTimeHr': startTimeHr,
      'startTimeMinutes': startTimeMinutes,
      'endTimeHr': endTimeHr,
      'endTimeMinutes': endTimeMinutes,
      'subjectCode': subjectCode,
      'facultyid': facultyId,
      'room_number': roomNumber,
      'typeOfLecture': typeOfLecture,
      'eventName': eventName,
      'description': description,
    };
  }
}
