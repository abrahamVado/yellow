import '../entities/dashboard_summary.dart';
import '../entities/dashboard_item.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> loadSummary();
  Future<List<DashboardItem>> loadItems();

  Future<DashboardData> loadDashboard() async {
    final summary = await loadSummary();
    final items = await loadItems();
    return DashboardData(summary: summary, items: items);
  }
}

class DashboardData {
  final DashboardSummary summary;
  final List<DashboardItem> items;

  const DashboardData({
    required this.summary,
    required this.items,
  });
}
