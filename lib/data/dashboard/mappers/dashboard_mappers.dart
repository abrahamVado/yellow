import '../../../domain/dashboard/entities/dashboard_summary.dart';
import '../../../domain/dashboard/entities/dashboard_item.dart';
import '../models/dashboard_summary_dto.dart';
import '../models/dashboard_item_dto.dart';

DashboardSummary mapSummary(DashboardSummaryDto dto) {
  return DashboardSummary(totalItems: dto.totalItems);
}

DashboardItem mapItem(DashboardItemDto dto) {
  return DashboardItem(
    id: dto.id,
    title: dto.title,
    description: dto.description,
  );
}
