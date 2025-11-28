import '../entities/auth_token.dart';
import '../repositories/auth_repository.dart';

class RefreshTokenUseCase {
  final AuthRepository _repository;

  RefreshTokenUseCase(this._repository);

  Future<AuthToken> call(String refreshToken) {
    return _repository.refreshToken(refreshToken);
  }
}
