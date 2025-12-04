class User {
  final String id;
  final String email;
  final String? name;
  final String? phoneNumber;
  final String? role;
  
  // Driver specific
  final String? driverId;
  final String? licenseNumber;
  final String? status;
  final double? rating;
  final String? photoUrl;
  final List<String>? documents;
  
  // Taxi specific
  final String? taxiPlate;
  final String? taxiModel;
  
  // Stats
  final int? tripCount;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    this.role,
    this.driverId,
    this.licenseNumber,
    this.status,
    this.rating,
    this.photoUrl,
    this.documents,
    this.taxiPlate,
    this.taxiModel,
    this.tripCount,
  });
}
