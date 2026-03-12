class TimetableModel {
  final int id;
  final String dateOfWeek;
  final String? fromDate;
  final String? toDate;
  final int? branchId;
  final int? sem;
  final String? division;
  final int? academicId;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  TimetableModel({
    required this.id,
    required this.dateOfWeek,
    this.fromDate,
    this.toDate,
    this.branchId,
    this.sem,
    this.division,
    this.academicId,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    return TimetableModel(
      id: _parseInt(json['id']) ?? 0,
      dateOfWeek: json['dateOfWeek']?.toString() ?? '',
      fromDate: json['fromDate']?.toString(),
      toDate: json['toDate']?.toString(),
      branchId: _parseInt(json['branch_id']),
      sem: _parseInt(json['sem']),
      division: json['division']?.toString(),
      academicId: _parseInt(json['academic_id']),
      createdBy: _parseInt(json['createdBy']),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateOfWeek': dateOfWeek,
      'fromDate': fromDate,
      'toDate': toDate,
      'branch_id': branchId,
      'sem': sem,
      'division': division,
      'academic_id': academicId,
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
