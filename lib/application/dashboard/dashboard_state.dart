import '../../domain/dashboard/entities/dashboard_item.dart';
import '../../domain/dashboard/entities/dashboard_summary.dart';

class DashboardState {
  final bool isLoading;
  final DashboardSummary? summary;
  final List<DashboardItem> items;
  final String? errorMessage;

  const DashboardState({
    required this.isLoading,
    required this.summary,
    required this.items,
    this.errorMessage,
  });

  factory DashboardState.initial() {
    return const DashboardState(
      isLoading: false,
      summary: null,
      items: [],
      errorMessage: null,
    );
  }

  DashboardState copyWith({
    bool? isLoading,
    DashboardSummary? summary,
    List<DashboardItem>? items,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }
}
