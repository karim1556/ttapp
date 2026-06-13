class SubjectModel {
  final int id;
  final String subjectCode;
  final String subjectName;
  final int? semester;
  final int? branchId;
  final String? acadYear;
  final String? experiments;  // text in DB
  final int? numExperiments;
  final int? numAssignments;
  final String? theory;       // text in DB
  final int? numModules;
  final String? professorAssign;
  final int totalCredits;
  final int? weeklyHours;
  final int? semesterHours;
  final int? maxMarks;
  final int? isPractical;
  final int? isOral;
  final int? oralMarks;
  final int? practicalMarks;
  final int? passingMarks;
  /// For lab subjects: the specific room number this subject must use during generation.
  final String? preferredRoomNumber;

  SubjectModel({
    required this.id,
    required this.subjectCode,
    required this.subjectName,
    this.semester,
    this.branchId,
    this.acadYear,
    this.experiments,
    this.numExperiments,
    this.numAssignments,
    this.theory,
    this.numModules,

    this.professorAssign,
    required this.totalCredits,
    this.weeklyHours,
    this.semesterHours,
    this.maxMarks,
    this.isOral,
    this.isPractical,
    this.oralMarks,
    this.practicalMarks,
    this.passingMarks,
    this.preferredRoomNumber,
  });

  /// totalCredits = lectures per week
  int get lecturesPerWeek => totalCredits;

  /// isPractical = 1 means it's a lab session
  bool get isLabSubject => isPractical == 1;

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: _parseInt(json['id']) ?? 0,
      subjectCode: json['subject_code']?.toString() ?? '',
      subjectName: json['subject_name']?.toString() ?? '',
      semester: _parseInt(json['semester']),
      branchId: _parseInt(json['branch_id']),
      acadYear: json['acad_year']?.toString(),
      experiments: json['experiments']?.toString(),
      numExperiments: _parseInt(json['num_experiments']),
      numAssignments: _parseInt(json['num_assignments']),
      theory: json['theory']?.toString(),
      numModules: _parseInt(json['num_modules']),
      professorAssign: json['professorAssign']?.toString() ??
          json['professor_assign']?.toString(),
      totalCredits: _parseInt(json['totalcredits']) ?? _parseInt(json['totalCredits']) ?? 0,
        weeklyHours: _parseInt(json['weekly_hours']) ?? _parseInt(json['weeklyHours']) ?? _parseInt(json['totalcredits']),
        semesterHours: _parseInt(json['semester_hours']) ?? _parseInt(json['semesterHours']),
      maxMarks: _parseInt(json['max_marks']) ?? _parseInt(json['maxMarks']),
      isOral: _parseInt(json['isoral']) ?? _parseInt(json['isOral']),
      isPractical: _parseInt(json['ispractical']) ?? _parseInt(json['isPractical']),
      oralMarks: _parseInt(json['oral_marks']) ?? _parseInt(json['oralMarks']),
      practicalMarks: _parseInt(json['practical_marks']) ?? _parseInt(json['practicalMarks']),
      passingMarks: _parseInt(json['passing_marks']) ?? _parseInt(json['passingMarks']),
      preferredRoomNumber: json['preferred_room']?.toString() ?? json['preferredRoom']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'semester': semester,
      'branch_id': branchId,
      'acad_year': acadYear,
      'experiments': experiments,
      'num_experiments': numExperiments,
      'num_assignments': numAssignments,
      'theory': theory,
      'num_modules': numModules,
      'professor_assign': professorAssign,
      'totalcredits': totalCredits,
      'weekly_hours': weeklyHours,
      'semester_hours': semesterHours,
      'max_marks': maxMarks,
      'isoral': isOral,
      'ispractical': isPractical,
      'oral_marks': oralMarks,
      'practical_marks': practicalMarks,
      'passing_marks': passingMarks,
      'preferred_room': preferredRoomNumber,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
