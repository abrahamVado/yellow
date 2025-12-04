class UserNotFoundException implements Exception {
  final String? email;
  final String? name;
  UserNotFoundException({this.email, this.name});
}

class PendingVerificationException implements Exception {
  final String? phone;
  PendingVerificationException({this.phone});
}
