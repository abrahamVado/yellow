import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/error/error_mapper_provider.dart';
import '../../data/dashboard/datasources/dashboard_remote_datasource.dart';
import '../../data/dashboard/repositories/dashboard_repository_impl.dart';
import '../../domain/dashboard/repositories/dashboard_repository.dart';
import 'dashboard_notifier.dart';
import 'dashboard_state.dart';

final dashboardRemoteDataSourceProvider =
    Provider<DashboardRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return DashboardRemoteDataSource(dio: dio);
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final remote = ref.watch(dashboardRemoteDataSourceProvider);
  final errorMapper = ref.watch(errorMapperProvider);
  return DashboardRepositoryImpl(
    remote: remote,
    errorMapper: errorMapper,
  );
});

final dashboardNotifierProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return DashboardNotifier(repo);
});
