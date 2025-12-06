import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:yellow/features/dashboard/presentation/providers/taxi_request_provider.dart';
import 'package:yellow/features/dashboard/presentation/screens/mis_viajes_screen.dart';

class RequestTaxiScreen extends ConsumerStatefulWidget {
  const RequestTaxiScreen({super.key});

  @override
  ConsumerState<RequestTaxiScreen> createState() => _RequestTaxiScreenState();
}

class _RequestTaxiScreenState extends ConsumerState<RequestTaxiScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _originFocus = FocusNode();
  final FocusNode _destFocus = FocusNode();
  LatLng? _currentCameraCenter;

  static const CameraPosition _kDefaultLocation = CameraPosition(
    target: LatLng(17.9982, -94.5456), // Minatitlán, Veracruz default
    zoom: 16.0,
  );

  @override
  void initState() {
    super.initState();
    // Auto-fetch location on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taxiRequestProvider.notifier).useMyLocation();
    });
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _originFocus.dispose();
    _destFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taxiState = ref.watch(taxiRequestProvider);
    final taxiNotifier = ref.read(taxiRequestProvider.notifier);

    // Sync controllers with state
    if (_originController.text != taxiState.originAddress && taxiState.originAddress.isNotEmpty) {
      _originController.text = taxiState.originAddress;
    }
    if (_destinationController.text != taxiState.destinationAddress && taxiState.destinationAddress.isNotEmpty) {
      _destinationController.text = taxiState.destinationAddress;
    }

    // Draggable Markers
    Set<Marker> markers = {};
    if (taxiState.originLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('origin'),
        position: taxiState.originLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Blue for Origin
        draggable: true,
        onDragEnd: (newPos) => taxiNotifier.updateOriginFromMarker(newPos),
      ));
    }
    if (taxiState.destinationLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('dest'),
        position: taxiState.destinationLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), // Green for Destination
        draggable: true,
        onDragEnd: (newPos) => taxiNotifier.updateDestinationFromMarker(newPos),
      ));
    }

    Set<Polyline> polylines = {};
    if (taxiState.routeInfo != null) {
      final points = PolylinePoints().decodePolyline(taxiState.routeInfo!['polyline_points']);
      polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
        color: Colors.black,
        width: 5,
      ));
      
      // Auto-zoom logic moved to ref.listen
    }

    ref.listen(taxiRequestProvider, (previous, next) {
        // Zoom to Origin if changed
        if (previous?.originLocation != next.originLocation && next.originLocation != null) {
             _mapController?.animateCamera(CameraUpdate.newLatLngZoom(next.originLocation!, 16));
        }

        // Zoom to Route if changed
        if (previous?.routeInfo != next.routeInfo && next.routeInfo != null && next.routeInfo!['bounds'] != null) {
           final bounds = next.routeInfo!['bounds'];
           final northeast = LatLng(bounds['northeast']['lat'], bounds['northeast']['lng']);
           final southwest = LatLng(bounds['southwest']['lat'], bounds['southwest']['lng']);
           Future.delayed(const Duration(milliseconds: 100), () {
              _mapController?.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: southwest, northeast: northeast), 50));
           });
        }
    });


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
          if (taxiState.originLocation == null)
              const Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   CircularProgressIndicator(),
                   SizedBox(height: 16),
                   Text("Obteniendo tu ubicación...", style: TextStyle(color: Colors.grey)),
                ],
              ))
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: taxiState.originLocation!,
                zoom: 16.0,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: taxiState.isManualSelectionMode ? {} : markers, // Hide markers when selecting manually to avoid clutter
              polylines: polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onCameraMove: (position) {
                _currentCameraCenter = position.target;
              },
            ),

          // SCOPE SIGHT (Only in Manual Mode)
          if (taxiState.isManualSelectionMode)
             const Center(
               child: Icon(Icons.location_searching, size: 40, color: Colors.black),
             ),

          // CONFIRM BUTTON (Only in Manual Mode)
          if (taxiState.isManualSelectionMode)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                   ElevatedButton(
                    onPressed: () {
                      if (_currentCameraCenter != null) {
                        taxiNotifier.updateDestinationFromMarker(_currentCameraCenter!);
                        taxiNotifier.setManualSelectionMode(false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Confirmar Ubicación", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => taxiNotifier.setManualSelectionMode(false),
                    child: const Text("Cancelar", style: TextStyle(color: Colors.white, fontSize: 16, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                  )
                ],
              ),
            ),

          // Inputs Panel (Top) - HIDDEN if Manual Selection Mode
          if (taxiState.originLocation != null && !taxiState.isManualSelectionMode)
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
                  // Origin Selection Mode
                  if (!taxiState.isOriginInputVisible && taxiState.originAddress.isEmpty)
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start, // Align label to left
                     children: [
                       const Text("¿Dónde estás?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                       const SizedBox(height: 10),
                       Row(
                         children: [
                           Expanded(
                             child: ElevatedButton.icon(
                               onPressed: () => taxiNotifier.useMyLocation(),
                               icon: const Icon(Icons.my_location, color: Colors.white),
                               label: const Text("Usa mi ubicación"),
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: Colors.green,
                                 foregroundColor: Colors.white,
                               ),
                             ),
                           ),
                           const SizedBox(width: 10),
                           Expanded(
                             child: OutlinedButton(
                               onPressed: () => taxiNotifier.showOriginInput(),
                               child: const Text("Usar otra"),
                             ),
                           ),
                         ],
                       )
                     ],
                   )
                  else
                  // Origin Input
                  TextField(
                    controller: _originController,
                    focusNode: _originFocus,
                    textInputAction: TextInputAction.search, // Show Search button
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: '¿Dónde estás?',
                      labelStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.my_location, size: 18, color: Colors.blue),
                      border: InputBorder.none,
                    ),
                    onTap: () => taxiNotifier.setFocus(true),
                    onChanged: (val) => taxiNotifier.onQueryChanged(val),
                    onSubmitted: (val) => taxiNotifier.searchLocation(val),
                  ),
                  
                  // Action Buttons (Only when focused)
                  if (taxiState.isOriginFocused)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                 taxiNotifier.useMyLocation();
                                 FocusScope.of(context).unfocus(); // Optional: close keyboard
                              },
                              icon: const Icon(Icons.my_location, size: 16),
                              label: const Text("Usa mi ubicación"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE0F7FA), // Light Blue
                                foregroundColor: Colors.blue[700],
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_originController.text.isNotEmpty)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _originController.clear();
                                taxiNotifier.clearOrigin();
                              },
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text("Limpiar"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Continue Button
                          Expanded(
                             child: ElevatedButton.icon(
                               onPressed: () {
                                 taxiNotifier.setFocus(false); // Show destination
                                 // Focus destination after build
                                 Future.delayed(const Duration(milliseconds: 100), () {
                                   if (context.mounted) {
                                      FocusScope.of(context).requestFocus(_destFocus);
                                   }
                                 });
                               }, 
                               icon: const Icon(Icons.arrow_forward, size: 16),
                               label: const Text("Continuar"),
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: Colors.black, // Primary action
                                 foregroundColor: Colors.white,
                                 elevation: 0,
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                               ),
                             ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Destination Input (Hidden when Origin focused)
                  if (!taxiState.isOriginFocused)
                    Column(
                      children: [
                        const Divider(),
                        TextField(
                          controller: _destinationController,
                          focusNode: _destFocus,
                          textInputAction: TextInputAction.search, // Show Search button
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: '¿A dónde vas?',
                            labelStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.location_on, color: Colors.green),
                            border: InputBorder.none,
                          ),
                          onTap: () => taxiNotifier.setFocus(false),
                          onChanged: (val) => taxiNotifier.onQueryChanged(val),
                          onSubmitted: (val) => taxiNotifier.searchLocation(val),
                        ),
                        // Choose on Map Button
                        if (_destFocus.hasFocus) // Only show when focused/typing
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  taxiNotifier.setManualSelectionMode(true);
                                },
                                icon: const Icon(Icons.map, size: 16),
                                label: const Text("Seleccionar en el mapa"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  side: const BorderSide(color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Autocomplete Suggestions Overlay
          if (taxiState.predictions.isNotEmpty)
            Positioned(
              top: taxiState.isOriginFocused ? 180 : 250, // Adjust position based on visibility
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
          if (taxiState.routeInfo != null && !taxiState.isManualSelectionMode)
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
                    // Price Display
                    if (taxiState.estimatedFare > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Tarifa Estimada: ", style: TextStyle(fontSize: 18, color: Colors.grey)),
                            Text("\$${taxiState.estimatedFare}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                    
                    // Scheduled Time Display & Picker
                    if (taxiState.estimatedFare > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             if (taxiState.scheduledTime != null)
                                Text(
                                  "Programado: ${DateFormat('dd MMM HH:mm').format(taxiState.scheduledTime!)}",
                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                ),
                             const SizedBox(width: 10),
                             TextButton.icon(
                               onPressed: () => _selectDateTime(context, taxiNotifier),
                               icon: const Icon(Icons.calendar_today, size: 16),
                               label: Text(taxiState.scheduledTime != null ? "Cambiar" : "Programar"),
                             )
                          ],
                        ),
                      ),
                      
                    // Placeholder Price or "Request" Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final success = await taxiNotifier.createTrip();
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Viaje solicitado con éxito!')));
                            
                            // 1. Reset State (Clears map, route, prices)
                            taxiNotifier.reset();
                            
                            // 2. Clear Inputs
                            _originController.clear();
                            _destinationController.clear();

                            // 3. Restart Location Fetch (so it's ready when user comes back)
                            taxiNotifier.useMyLocation();

                            // 4. Navigate to Mis Viajes
                            // ignore: use_build_context_synchronously
                            Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const MisViajesScreen())
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al solicitar viaje')));
                          }
                        },
                          child: Text(
                            taxiState.scheduledTime != null ? 'Reservar Viaje' : 'Confirmar Viaje', 
                            style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Cancel / Reset Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.arrow_back, color: Colors.grey),
                        label: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontSize: 16)),
                        onPressed: () {
                           taxiNotifier.reset();
                           _originController.clear();
                           _destinationController.clear();
                           // Navigate back to menu
                           Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
           // Only show overlays loader if map is already active (avoid double loader during init)
           if (taxiState.isLoading && taxiState.originLocation != null)
             const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
  Future<void> _selectDateTime(BuildContext context, TaxiRequestNotifier notifier) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
             colorScheme: const ColorScheme.light(primary: Colors.black),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null && context.mounted) {
       final time = await showTimePicker(
         context: context,
         initialTime: TimeOfDay.now(),
         builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                 colorScheme: const ColorScheme.light(primary: Colors.black),
              ),
              child: child!,
            );
         },
       );
       
       if (time != null) {
          final scheduled = DateTime(
            date.year, date.month, date.day,
            time.hour, time.minute
          );
          notifier.setScheduledTime(scheduled);
       }
    }
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
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
