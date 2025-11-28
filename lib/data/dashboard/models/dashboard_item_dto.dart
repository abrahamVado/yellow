class DashboardItemDto {
  final String id;
  final String title;
  final String description;

  const DashboardItemDto({
    required this.id,
    required this.title,
    required this.description,
  });

  factory DashboardItemDto.fromJson(Map<String, dynamic> json) {
    return DashboardItemDto(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
    );
  }
}
