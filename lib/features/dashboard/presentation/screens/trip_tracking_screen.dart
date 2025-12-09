import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellow/core/config/app_config.dart';
import 'package:yellow/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripTrackingScreen extends ConsumerStatefulWidget {
  final int tripId;

  const TripTrackingScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends ConsumerState<TripTrackingScreen> {
  Timer? _pollingTimer;
  Map<String, dynamic>? _tripData;
  String _status = 'requested'; // requested, matched, in_progress, completed, cancelled
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Poll immediately
    _fetchTripStatus();
    // Then every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchTripStatus();
    });
  }

  Future<void> _fetchTripStatus() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/trips/${widget.tripId}');

      if (response.statusCode == 200 && response.data['data'] != null) {
        final data = response.data['data'];
        setState(() {
          _tripData = data;
          _status = data['status'];
          _isLoading = false;
        });

        // Loop management
        if (['completed', 'cancelled', 'expired'].contains(_status)) {
           _pollingTimer?.cancel();
        }
      }
    } catch (e) {
      print('Error polling trip: $e');
      // Don't stop polling on transient errors, but maybe show snackbar?
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getStatusTitle()),
        automaticallyImplyLeading: false, // Don't allow back to request
        actions: [
            if (_status == 'requested' || _status == 'matched')
               IconButton(
                 icon: const Icon(Icons.cancel),
                 onPressed: () => _confirmCancel(),
               )
        ],
      ),
      body: _buildBody(),
    );
  }

  String _getStatusTitle() {
    switch (_status) {
      case 'requested': return 'Buscando Conductor...';
      case 'matched': return 'Conductor Encontrado';
      case 'in_progress': return 'En Viaje';
      case 'completed': return 'Viaje Finalizado';
      case 'cancelled': return 'Cancelado';
      default: return 'Detalles del Viaje';
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_status == 'requested') {
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             const CircularProgressIndicator(),
             const SizedBox(height: 20),
             const Text("Buscando el mejor conductor para ti...", style: TextStyle(fontSize: 16)),
             const SizedBox(height: 10),
             Text("Viaje #${widget.tripId}", style: const TextStyle(color: Colors.grey)),
           ],
         ),
       );
    }

    if (_status == 'matched' || _status == 'in_progress') {
       return Column(
         children: [
            // Driver Info Card
            if (_tripData?['driver'] != null)
              _buildDriverCard(_tripData!['driver']),
            
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(_tripData!['origin_lat'], _tripData!['origin_lng']),
                  zoom: 15,
                ),
                markers: _getMarkers(),
                // TODO: Polylines & Live Driver Location
              ),
            ),
         ],
       );
    }
    
    if (_status == 'completed') {
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             const Icon(Icons.check_circle, color: Colors.green, size: 80),
             const SizedBox(height: 20),
             const Text("¡Has llegado a tu destino!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
             const SizedBox(height: 10),
             Text("Costo Final: \$${_tripData?['fare'] ?? '0.00'}", style: const TextStyle(fontSize: 18)),
             const SizedBox(height: 30),
             ElevatedButton(
               onPressed: () => Navigator.of(context).pop(), // Go back home
               child: const Text("Finalizar"),
             )
           ],
         ),
       );
    }

    return Center(child: Text("Estado: $_status"));
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
        subtitle: Text("Toyota Prius • ${driver['license_plate'] ?? 'ABC-123'}"), // Placeholder plate
        trailing: Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
             child: const Text("4.9 ★", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Set<Marker> _getMarkers() {
    Set<Marker> markers = {};
    if (_tripData == null) return markers;

    markers.add(Marker(
      markerId: const MarkerId('origin'),
      position: LatLng(_tripData!['origin_lat'], _tripData!['origin_lng']),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ));

    if (_status == 'matched' && _tripData!['driver'] != null) {
       // Driver location (simulated or from data)
       // Usually 'driver' object in trip response should have 'lat'/'lng' updated?
       // Currently backend might not nest driver location in 'driver' object of trip response.
       // We might need a separate call or structure. 
       // For now, assuming driver location IS NOT in the trip object yet (need to verify API).
    }
    
    return markers;
  }

  void _confirmCancel() {
     showDialog(context: context, builder: (context) => AlertDialog(
        title: const Text("¿Cancelar viaje?"),
        content: const Text("¿Estás seguro que deseas cancelar?"),
        actions: [
           TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
           TextButton(
             onPressed: () async {
                 Navigator.pop(context);
                 _cancelTrip();
             }, 
             child: const Text("Sí, cancelar"),
           ),
        ],
     ));
  }

  Future<void> _cancelTrip() async {
      try {
        final dio = ref.read(dioProvider);
        await dio.put('/trips/${widget.tripId}/cancel', data: {'reason': 'Client cancelled'});
        // Go back
        if (mounted) Navigator.of(context).pop(); 
      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cancelar')));
      }
  }
}
