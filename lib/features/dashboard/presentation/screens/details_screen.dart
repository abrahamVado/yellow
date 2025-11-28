import 'package:flutter/material.dart';

class DashboardDetailsScreen extends StatelessWidget {
  final String id;

  const DashboardDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Details $id'),
      ),
      body: Center(
        child: Text('Details for item $id'),
      ),
    );
  }
}
