import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellow/core/config/app_config.dart';
import 'package:yellow/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:yellow/features/dashboard/presentation/providers/taxi_request_provider.dart';

class TripTrackingScreen extends ConsumerWidget {
  final int tripId;

  const TripTrackingScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripStatusStreamProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_getStatusTitle(tripAsync.value?['status'] ?? 'requested')),
        automaticallyImplyLeading: false, 
        actions: [
            if (tripAsync.value?['status'] == 'requested' || tripAsync.value?['status'] == 'matched')
               IconButton(
                 icon: const Icon(Icons.cancel),
                 onPressed: () => _confirmCancel(context, ref),
               )
        ],
      ),
      body: tripAsync.when(
        data: (data) => _buildBody(context, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading trip: $err')),
      ),
    );
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'requested': return 'Buscando Conductor...';
      case 'matched': return 'Conductor Encontrado';
      case 'in_progress': return 'En Viaje';
      case 'completed': return 'Viaje Finalizado';
      case 'cancelled': return 'Cancelado';
      default: return 'Detalles del Viaje';
    }
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> tripData) {
    final status = tripData['status'];

    if (status == 'requested') {
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             const CircularProgressIndicator(),
             const SizedBox(height: 20),
             const Text("Buscando el mejor conductor para ti...", style: TextStyle(fontSize: 16)),
             const SizedBox(height: 10),
             Text("Viaje #$tripId", style: const TextStyle(color: Colors.grey)),
           ],
         ),
       );
    }

    if (status == 'matched' || status == 'in_progress') {
       return Column(
         children: [
            if (tripData['driver'] != null)
              _buildDriverCard(tripData['driver']),
            
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(tripData['origin_lat'], tripData['origin_lng']),
                  zoom: 15,
                ),
                markers: _getMarkers(tripData, status),
              ),
            ),
         ],
       );
    }
    
    if (status == 'completed') {
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             const Icon(Icons.check_circle, color: Colors.green, size: 80),
             const SizedBox(height: 20),
             const Text("¡Has llegado a tu destino!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
             const SizedBox(height: 10),
             Text("Costo Final: \$${tripData['fare'] ?? '0.00'}", style: const TextStyle(fontSize: 18)),
             const SizedBox(height: 30),
             ElevatedButton(
               onPressed: () => Navigator.of(context).pop(), 
               child: const Text("Finalizar"),
             )
           ],
         ),
       );
    }

    return Center(child: Text("Estado: $status"));
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: ListTile(
        leading: const CircleAvatar(
           backgroundColor: Colors.black,
           child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text("${driver['first_name']} ${driver['last_name']}"),
        subtitle: Text("Toyota Prius • ${driver['license_plate'] ?? 'ABC-123'}"), 
        trailing: Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
             child: const Text("4.9 ★", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Set<Marker> _getMarkers(Map<String, dynamic> tripData, String status) {
    Set<Marker> markers = {};

    markers.add(Marker(
      markerId: const MarkerId('origin'),
      position: LatLng(tripData['origin_lat'], tripData['origin_lng']),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ));

    if (status == 'matched' && tripData['driver'] != null) {
       final driver = tripData['driver'];
       if (driver['current_location_lat'] != null && driver['current_location_lng'] != null) {
          markers.add(Marker(
            markerId: const MarkerId('driver'),
            position: LatLng(driver['current_location_lat'], driver['current_location_lng']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow), 
          ));
       }
    }
    
    return markers;
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
     showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text("¿Cancelar viaje?"),
        content: const Text("¿Estás seguro que deseas cancelar?"),
        actions: [
           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("No")),
           TextButton(
             onPressed: () async {
                 Navigator.pop(ctx);
                 _cancelTrip(context, ref);
             }, 
             child: const Text("Sí, cancelar"),
           ),
        ],
     ));
  }

  Future<void> _cancelTrip(BuildContext context, WidgetRef ref) async {
      try {
        final dio = ref.read(dioProvider);
        await dio.put('/trips/$tripId/cancel', data: {'reason': 'Client cancelled'});
        if (context.mounted) Navigator.of(context).pop(); 
      } catch (e) {
         if (context.mounted)
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cancelar')));
      }
  }
}
