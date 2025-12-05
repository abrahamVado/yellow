import 'package:flutter/material.dart';

class AccountStatementScreen extends StatelessWidget {
  const AccountStatementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estado de cuenta')),
      body: const Center(child: Text('Estado de cuenta Screen')),
    );
  }
}
