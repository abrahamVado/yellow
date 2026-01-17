import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_provider.dart';
import '../../data/legal/datasources/legal_remote_datasource.dart';
import '../../data/legal/repositories/legal_repository_impl.dart';
import '../../domain/legal/repositories/legal_repository.dart';

// DataSource Provider
final legalRemoteDataSourceProvider = Provider<LegalRemoteDataSource>((ref) {
  return LegalRemoteDataSource(dio: ref.watch(dioProvider));
});

// Repository Provider
final legalRepositoryProvider = Provider<LegalRepository>((ref) {
  return LegalRepositoryImpl(remote: ref.watch(legalRemoteDataSourceProvider));
});

// Future Providers for UI
final termsProvider = FutureProvider<String>((ref) async {
  return await ref.watch(legalRepositoryProvider).getTerms();
});

final privacyPolicyProvider = FutureProvider<String>((ref) async {
  return await ref.watch(legalRepositoryProvider).getPrivacyPolicy();
});
