import '../../../domain/auth/entities/user.dart';

class UserProfileModel extends User {
  const UserProfileModel({
    required super.id,
    required super.email,
    super.name,
    super.phoneNumber,
    super.role,
    super.driverId,
    super.licenseNumber,
    super.status,
    super.rating,
    super.photoUrl,
    super.documents,
    super.taxiPlate,
    super.taxiModel,
    super.tripCount,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      name: '${json['first_name']} ${json['last_name']}'.trim(),
      phoneNumber: json['phone_number'],
      role: json['role'],
      driverId: json['driver_id']?.toString(),
      licenseNumber: json['license_number'],
      status: json['status'],
      rating: (json['rating'] as num?)?.toDouble(),
      photoUrl: json['photo_url'],
      documents: (json['documents'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      taxiPlate: json['taxi_plate'],
      taxiModel: json['taxi_model'],
      tripCount: json['trip_count'],
    );
  }
}
