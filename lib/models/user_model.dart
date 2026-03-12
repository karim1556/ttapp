class UserModel {
  final int uid;
  final String email;
  final int userType;
  String? token;

  UserModel({
    required this.uid,
    required this.email,
    required this.userType,
    this.token,
  });

  bool get isAdmin => userType == 1;
  bool get isFaculty => userType == 2;
  bool get isStudent => userType == 3;

  String get userTypeLabel {
    switch (userType) {
      case 1:
        return 'Admin';
      case 2:
        return 'Faculty';
      case 3:
        return 'Student';
      default:
        return 'Unknown';
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] is int ? json['uid'] : int.tryParse(json['uid'].toString()) ?? 0,
      email: json['email']?.toString() ?? '',
      userType: json['user_type'] is int
          ? json['user_type']
          : int.tryParse(json['user_type'].toString()) ?? 3,
      token: json['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'user_type': userType,
      'token': token,
    };
  }

  UserModel copyWith({
    int? uid,
    String? email,
    int? userType,
    String? token,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      token: token ?? this.token,
    );
  }
}
