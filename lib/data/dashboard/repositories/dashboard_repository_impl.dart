import '../../../core/error/error_mapper.dart';
import '../../../domain/dashboard/entities/dashboard_summary.dart';
import '../../../domain/dashboard/entities/dashboard_item.dart';
import '../../../domain/dashboard/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../mappers/dashboard_mappers.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remote;
  final ErrorMapper errorMapper;

  DashboardRepositoryImpl({
    required this.remote,
    required this.errorMapper,
  });

  @override
  Future<DashboardSummary> loadSummary() async {
    try {
      final dto = await remote.loadSummary();
      return mapSummary(dto);
    } catch (error, stackTrace) {
      throw errorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<List<DashboardItem>> loadItems() async {
    try {
      final dtos = await remote.loadItems();
      return dtos.map(mapItem).toList();
    } catch (error, stackTrace) {
      throw errorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<DashboardData> loadDashboard() async {
    try {
      final summary = await loadSummary();
      final items = await loadItems();
      return DashboardData(summary: summary, items: items);
    } catch (error, stackTrace) {
      throw errorMapper.map(error, stackTrace);
    }
  }
}
