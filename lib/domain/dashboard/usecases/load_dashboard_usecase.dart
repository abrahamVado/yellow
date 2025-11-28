import '../entities/dashboard_summary.dart';
import '../entities/dashboard_item.dart';
import '../repositories/dashboard_repository.dart';

class DashboardData {
  final DashboardSummary summary;
  final List<DashboardItem> items;

  const DashboardData({
    required this.summary,
    required this.items,
  });
}

class LoadDashboardUseCase {
  final DashboardRepository _repository;

  LoadDashboardUseCase(this._repository);

  Future<DashboardData> call() => _repository.loadDashboard();
}
