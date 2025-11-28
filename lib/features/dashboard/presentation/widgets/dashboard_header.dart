import 'package:flutter/material.dart';

import '../../../../domain/dashboard/entities/dashboard_summary.dart';

class DashboardHeader extends StatelessWidget {
  final DashboardSummary? summary;

  const DashboardHeader({super.key, this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary?.totalItems ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        'Total items: $total',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
