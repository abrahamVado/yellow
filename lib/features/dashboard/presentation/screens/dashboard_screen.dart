import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellow/features/shared/layout/app_drawer.dart';
import 'package:yellow/features/dashboard/presentation/widgets/parallax_background.dart';
import 'package:yellow/features/dashboard/presentation/widgets/home_menu_panel.dart';


class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allow background to go behind AppBar
      appBar: AppBar(
        title: const Text('Mathey Pasajero'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      drawer: const AppDrawer(),
      body: const Stack(
        children: [
          ParallaxBackground(),
           HomeMenuPanel(),
        ],
      ),
    );
  }
}    
