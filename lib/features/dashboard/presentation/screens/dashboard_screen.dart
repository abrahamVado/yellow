import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/dashboard/dashboard_providers.dart';
import '../../../../app/theme/theme_provider.dart';
import '../../../../core/config/env.dart';
import '../../../shared/layout/app_scaffold.dart';
import '../../../shared/layout/app_drawer.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_cards_grid.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardNotifierProvider);

    ref.listen(dashboardNotifierProvider, (previous, next) {
      // Trigger load on first build
      if (previous == null && !next.isLoading && next.items.isEmpty) {
        ref.read(dashboardNotifierProvider.notifier).loadDashboard();
      }
    });

    Widget body;
    if (state.isLoading && state.items.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.items.isEmpty) {
      body = const EmptyState(message: 'No items');
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(summary: state.summary),
          Expanded(
            child: DashboardCardsGrid(items: state.items),
          ),
        ],
      );
    }

    final themeConfig = ref.watch(themeConfigProvider).valueOrNull;

    return AppScaffold(
      title: 'Dashboard',
      titleWidget: themeConfig != null && themeConfig.logoUrl.isNotEmpty
          ? Image.network(
              '${Env.apiUrl}${themeConfig.logoUrl}',
              height: 40,
              errorBuilder: (context, error, stackTrace) => const Text('Dashboard'),
            )
          : null,
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: body,
      ),
    );
  }
}
