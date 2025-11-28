import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/dashboard/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardNotifier(this._repository) : super(DashboardState.initial());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _repository.loadDashboard();
      state = state.copyWith(
        isLoading: false,
        summary: data.summary,
        items: data.items,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }
}
