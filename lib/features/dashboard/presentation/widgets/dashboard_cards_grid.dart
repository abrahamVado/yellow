import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/dashboard/entities/dashboard_item.dart';

class DashboardCardsGrid extends StatelessWidget {
  final List<DashboardItem> items;

  const DashboardCardsGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            title: Text(item.title),
            subtitle: Text(item.description),
            onTap: () => context.go('/dashboard/${item.id}'),
          ),
        );
      },
    );
  }
}
