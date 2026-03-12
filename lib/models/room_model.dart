class RoomModel {
  final int id;
  final String roomNumber;
  final String? name;
  final int? capacity;
  final String? roomType;
  final int? branchId;
  final String? floor;
  final int? isActive;

  RoomModel({
    required this.id,
    required this.roomNumber,
    this.name,
    this.capacity,
    this.roomType,
    this.branchId,
    this.floor,
    this.isActive,
  });

  bool get active => isActive == 1;

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: _parseInt(json['id']) ?? 0,
      roomNumber: json['room_number']?.toString() ?? '',
      name: json['name']?.toString(),
      capacity: _parseInt(json['capacity']),
      roomType: json['room_type']?.toString(),
      branchId: _parseInt(json['branch_id']),
      floor: json['floor']?.toString(),
      isActive: _parseInt(json['is_active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_number': roomNumber,
      'name': name,
      'capacity': capacity,
      'room_type': roomType,
      'branch_id': branchId,
      'floor': floor,
      'is_active': isActive,
    };
  }

  RoomModel copyWith({
    int? id,
    String? roomNumber,
    String? name,
    int? capacity,
    String? roomType,
    int? branchId,
    String? floor,
    int? isActive,
  }) {
    return RoomModel(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      roomType: roomType ?? this.roomType,
      branchId: branchId ?? this.branchId,
      floor: floor ?? this.floor,
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
