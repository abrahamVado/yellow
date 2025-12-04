import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/fcm_service.dart';

import '../../core/network/dio_client.dart';
import '../../core/storage/token_storage.dart';
import '../../core/error/error_mapper_provider.dart';
import '../../data/auth/datasources/auth_remote_datasource.dart';
import '../../data/auth/repositories/auth_repository_impl.dart';
import '../../domain/auth/repositories/auth_repository.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSource(dio: dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final errorMapper = ref.watch(errorMapperProvider);

  return AuthRepositoryImpl(
    remote: remote,
    tokenStorage: tokenStorage,
    errorMapper: errorMapper,
  );
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final fcmService = ref.watch(fcmServiceProvider);
  return AuthNotifier(repo, fcmService);
});
