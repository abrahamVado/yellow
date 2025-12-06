import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:yellow/features/dashboard/presentation/providers/taxi_request_provider.dart';

class RequestTaxiScreen extends ConsumerStatefulWidget {
  const RequestTaxiScreen({super.key});

  @override
  ConsumerState<RequestTaxiScreen> createState() => _RequestTaxiScreenState();
}

class _RequestTaxiScreenState extends ConsumerState<RequestTaxiScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  static const CameraPosition _kDefaultLocation = CameraPosition(
    target: LatLng(19.4326, -99.1332), // CDMX default
    zoom: 14.4746,
  );

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taxiState = ref.watch(taxiRequestProvider);
    final taxiNotifier = ref.read(taxiRequestProvider.notifier);

    // Sync controllers with state if needed, or just use onChange
    if (_originController.text != taxiState.originAddress && taxiState.originAddress.isNotEmpty) {
      _originController.text = taxiState.originAddress;
    }
    if (_destinationController.text != taxiState.destinationAddress && taxiState.destinationAddress.isNotEmpty) {
      _destinationController.text = taxiState.destinationAddress;
    }

    Set<Marker> markers = {};
    if (taxiState.originLocation != null) {
      markers.add(Marker(markerId: const MarkerId('origin'), position: taxiState.originLocation!, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)));
    }
    if (taxiState.destinationLocation != null) {
      markers.add(Marker(markerId: const MarkerId('dest'), position: taxiState.destinationLocation!, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)));
    }

    Set<Polyline> polylines = {};
    if (taxiState.routeInfo != null) {
      final points = PolylinePoints().decodePolyline(taxiState.routeInfo!['polyline_points']);
      polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
        color: Colors.blue,
        width: 5,
      ));
      
      // Auto-zoom to fit bounds if route changes
      if (_mapController != null && taxiState.routeInfo!['bounds'] != null) {
         final bounds = taxiState.routeInfo!['bounds'];
         final northeast = LatLng(bounds['northeast']['lat'], bounds['northeast']['lng']);
         final southwest = LatLng(bounds['southwest']['lat'], bounds['southwest']['lng']);
         // Adding a small delay to ensure map is ready
         Future.delayed(const Duration(milliseconds: 500), () {
             _mapController?.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: southwest, northeast: northeast), 50));
         });
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // Google Map Background
          GoogleMap(
            initialCameraPosition: _kDefaultLocation,
            onMapCreated: (controller) => _mapController = controller,
            markers: markers,
            polylines: polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Inputs Panel (Top)
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                ],
              ),
              child: Column(
                children: [
                  // Origin Input
                  TextField(
                    controller: _originController,
                    decoration: const InputDecoration(
                      labelText: '¿Dónde estás?',
                      prefixIcon: Icon(Icons.my_location, color: Colors.green),
                      border: InputBorder.none,
                    ),
                    onTap: () => taxiNotifier.setFocus(true),
                    onChanged: (val) => taxiNotifier.onQueryChanged(val),
                  ),
                  const Divider(),
                  // Destination Input
                  TextField(
                    controller: _destinationController,
                    decoration: const InputDecoration(
                      labelText: '¿A dónde vas?',
                      prefixIcon: Icon(Icons.location_on, color: Colors.red),
                      border: InputBorder.none,
                    ),
                    onTap: () => taxiNotifier.setFocus(false),
                    onChanged: (val) => taxiNotifier.onQueryChanged(val),
                  ),
                ],
              ),
            ),
          ),

          // Autocomplete Suggestions Overlay
          if (taxiState.predictions.isNotEmpty)
            Positioned(
              top: 230, // Just below the inputs card
              left: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                   boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: taxiState.predictions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = taxiState.predictions[index];
                    return ListTile(
                      title: Text(p['description'] ?? ''),
                      onTap: () {
                         taxiNotifier.onPredictionSelected(p['place_id'], p['description']);
                         FocusScope.of(context).unfocus(); // Hide keyboard
                      },
                    );
                  },
                ),
              ),
            ),

          // Trip Details Card (Bottom)
          if (taxiState.routeInfo != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _TripInfoItem(
                          label: 'Distancia',
                          value: taxiState.routeInfo!['distance_text'],
                          icon: Icons.straighten,
                        ),
                         _TripInfoItem(
                          label: 'Tiempo',
                          value: taxiState.routeInfo!['duration_text'],
                          icon: Icons.timer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Placeholder Price or "Request" Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          // TODO: Proceed to booking
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Procesando solicitud...')));
                        },
                        child: const Text('Confirmar Viaje', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
           if (taxiState.isLoading)
             const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _TripInfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TripInfoItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
