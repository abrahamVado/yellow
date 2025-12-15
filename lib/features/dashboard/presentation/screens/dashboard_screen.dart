import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellow/features/shared/layout/app_drawer.dart';
import 'package:yellow/features/dashboard/presentation/widgets/parallax_background.dart';
import 'package:yellow/features/dashboard/presentation/widgets/home_menu_panel.dart';
import 'package:yellow/core/network/dio_client.dart';
import 'package:go_router/go_router.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  
  @override
  void initState() {
    super.initState();
    // Check for active trips on load to restore session
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkActiveTrip());
  }

  Future<void> _checkActiveTrip() async {
    try {
      final dio = ref.read(dioProvider); 
      // Assuming GET /trips/active returns the current user's active trip
      // We might need to adjust the endpoint if it differs for passengers
      final response = await dio.get('/trips/mine');
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List<dynamic> trips = response.data['data'] ?? [];
        
        // Find first active trip
        final activeTrip = trips.firstWhere(
           (t) => ['requested', 'queued', 'matched', 'in_progress', 'picked_up'].contains(t['status']),
           orElse: () => null
        );

        if (activeTrip != null) {
           final tripId = activeTrip['id'];
           if (mounted) {
              // Use a small delay to ensure UI is ready or just pushReplacement? 
              // Push is fine, user will see dashboard then jump. 
              context.push('/dashboard/trip-tracking/$tripId');
           }
        }
      }
    } catch (e) {
      // Fail silently, user stays on dashboard
      debugPrint("Error checking active trip: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
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
