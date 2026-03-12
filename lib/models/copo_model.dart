class CopoUserCourseModel {
  final int usercourseId;
  final int? courseId;
  final int? semester;
  final String? academicYear;
  final int? branch;
  final int? coCount;
  final String? createdAt;

  // Enriched from server join
  final String? subjectName;
  final String? subjectCode;
  final int? enrolledCount;

  CopoUserCourseModel({
    required this.usercourseId,
    this.courseId,
    this.semester,
    this.academicYear,
    this.branch,
    this.coCount,
    this.createdAt,
    this.subjectName,
    this.subjectCode,
    this.enrolledCount,
  });

  factory CopoUserCourseModel.fromJson(Map<String, dynamic> json) {
    return CopoUserCourseModel(
      usercourseId: _parseInt(json['usercourse_id']) ?? 0,
      courseId:     _parseInt(json['course_id']),
      semester:     _parseInt(json['semester']),
      academicYear: json['academic_year']?.toString(),
      branch:       _parseInt(json['branch']),
      coCount:      _parseInt(json['co_count']),
      createdAt:    json['created_at']?.toString(),
      subjectName:  json['subject_name']?.toString(),
      subjectCode:  json['subject_code']?.toString(),
      enrolledCount: _parseInt(json['enrolled_count']),
    );
  }

  Map<String, dynamic> toJson() => {
    'usercourse_id': usercourseId,
    'course_id':     courseId,
    'semester':      semester,
    'academic_year': academicYear,
    'branch':        branch,
    'co_count':      coCount,
  };

  String get branchLabel {
    switch (branch) {
      case 1: return 'CS';
      case 2: return 'IT';
      case 3: return 'EXTC';
      case 4: return 'Mech';
      default: return branch != null ? 'Branch $branch' : '—';
    }
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}

class CopoEnrollmentModel {
  final int id;
  final int usercourseId;
  final int userId;
  final String? userEmail;
  final int?    userType;

  CopoEnrollmentModel({
    required this.id,
    required this.usercourseId,
    required this.userId,
    this.userEmail,
    this.userType,
  });

  factory CopoEnrollmentModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return CopoEnrollmentModel(
      id:            _parseInt(json['id_usercourse_users']) ?? 0,
      usercourseId:  _parseInt(json['usercourse_id']) ?? 0,
      userId:        _parseInt(json['user_id']) ?? 0,
      userEmail:     user?['email']?.toString(),
      userType:      _parseInt(user?['user_type']),
    );
  }

  String get userTypeLabel {
    switch (userType) {
      case 1: return 'Admin';
      case 2: return 'Faculty';
      case 3: return 'Student';
      default: return 'User';
    }
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
