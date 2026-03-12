class FacultyModel {
  final int facultyId;
  final int? uid;
  final String? facultyClgId;
  final String name;
  final String? contact;
  final int? ftypeId;
  final String? role;
  final int? departId;
  final int? privilege;
  final String? joiningDate;
  final int? shiftId;
  final String? gender;
  final String? dob;
  final String? qualification;
  final String? panNo;
  final String? aadharCard;
  final String? bloodGroup;
  final String? permanentAddress;
  final String? currentAddress;
  final String? alternateMobile;
  final String? experienceDetails;
  final String? photo;
  final String? signature;
  final String? cv;
  final String email;
  final int? branchId;
  final int? status;

  FacultyModel({
    required this.facultyId,
    this.uid,
    this.facultyClgId,
    required this.name,
    this.contact,
    this.ftypeId,
    this.role,
    this.departId,
    this.privilege,
    this.joiningDate,
    this.shiftId,
    this.gender,
    this.dob,
    this.qualification,
    this.panNo,
    this.aadharCard,
    this.bloodGroup,
    this.permanentAddress,
    this.currentAddress,
    this.alternateMobile,
    this.experienceDetails,
    this.photo,
    this.signature,
    this.cv,
    required this.email,
    this.branchId,
    this.status,
  });

  bool get isActive => status == 1;

  factory FacultyModel.fromJson(Map<String, dynamic> json) {
    return FacultyModel(
      facultyId: _parseInt(json['faculty_id']) ?? 0,
      uid: _parseInt(json['uid']),
      facultyClgId: json['faculty_clg_id']?.toString(),
      name: json['name']?.toString() ?? '',
      contact: json['contact']?.toString(),
      ftypeId: _parseInt(json['ftype_id']),
      role: json['role']?.toString(),
      departId: _parseInt(json['depart_id']),
      privilege: _parseInt(json['previlage']),
      joiningDate: json['joining_date']?.toString(),
      shiftId: _parseInt(json['shift_id']),
      gender: json['gender']?.toString(),
      dob: json['dob']?.toString(),
      qualification: json['qualification']?.toString(),
      panNo: json['pan_no']?.toString(),
      aadharCard: json['aadhar_card']?.toString(),
      bloodGroup: json['blood_group']?.toString(),
      permanentAddress: json['permanent_address']?.toString(),
      currentAddress: json['current_address']?.toString(),
      alternateMobile: json['alternate_mobile']?.toString(),
      experienceDetails: json['experience_details']?.toString(),
      photo: json['photo']?.toString(),
      signature: json['signature']?.toString(),
      cv: json['cv']?.toString(),
      email: json['email']?.toString() ?? '',
      branchId: _parseInt(json['branch_id']),
      status: _parseInt(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'faculty_id': facultyId,
      'uid': uid,
      'faculty_clg_id': facultyClgId,
      'name': name,
      'contact': contact,
      'ftype_id': ftypeId,
      'role': role,
      'depart_id': departId,
      'previlage': privilege,
      'joining_date': joiningDate,
      'shift_id': shiftId,
      'gender': gender,
      'dob': dob,
      'qualification': qualification,
      'pan_no': panNo,
      'aadhar_card': aadharCard,
      'blood_group': bloodGroup,
      'permanent_address': permanentAddress,
      'current_address': currentAddress,
      'alternate_mobile': alternateMobile,
      'experience_details': experienceDetails,
      'photo': photo,
      'signature': signature,
      'cv': cv,
      'email': email,
      'branch_id': branchId,
      'status': status,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
