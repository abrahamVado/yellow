import 'package:dio/dio.dart';

import '../models/dashboard_summary_dto.dart';
import '../models/dashboard_item_dto.dart';

class DashboardRemoteDataSource {
  final Dio dio;

  DashboardRemoteDataSource({required this.dio});

  Future<DashboardSummaryDto> loadSummary() async {
    final response = await dio.get<Map<String, dynamic>>('/dashboard/summary');
    final data = response.data!;
    return DashboardSummaryDto.fromJson(data);
  }

  Future<List<DashboardItemDto>> loadItems() async {
    final response = await dio.get<List<dynamic>>('/dashboard/items');
    final data = response.data ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(DashboardItemDto.fromJson)
        .toList();
  }
}
