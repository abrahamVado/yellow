import 'package:flutter/material.dart';

class RequestTaxiScreen extends StatelessWidget {
  const RequestTaxiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedir un taxi')),
      body: const Center(child: Text('Pedir un taxi Screen')),
    );
  }
}
