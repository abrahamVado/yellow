import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? drawer;
  final Widget? titleWidget;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.drawer,
    this.titleWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: titleWidget ?? Text(title)),
      drawer: drawer,
      body: body,
    );
  }
}
