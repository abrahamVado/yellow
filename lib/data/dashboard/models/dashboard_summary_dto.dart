class DashboardSummaryDto {
  final int totalItems;

  const DashboardSummaryDto({required this.totalItems});

  factory DashboardSummaryDto.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryDto(
      totalItems: json['total_items'] as int? ?? 0,
    );
  }
}
