import '../../../domain/legal/repositories/legal_repository.dart';
import '../datasources/legal_remote_datasource.dart';

class LegalRepositoryImpl implements LegalRepository {
  final LegalRemoteDataSource remote;

  LegalRepositoryImpl({required this.remote});

  @override
  Future<String> getTerms() async {
    return await remote.getTerms();
  }

  @override
  Future<String> getPrivacyPolicy() async {
    return await remote.getPrivacyPolicy();
  }
}
