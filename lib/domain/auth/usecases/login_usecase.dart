import '../repositories/auth_repository.dart';
import '../entities/auth_token.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<AuthToken> call({
    required String username,
    required String password,
  }) {
    return _repository.login(username: username, password: password);
  }
}
