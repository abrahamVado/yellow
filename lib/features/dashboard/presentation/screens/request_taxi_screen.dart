import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:go_router/go_router.dart';
import 'package:yellow/features/dashboard/presentation/providers/taxi_request_provider.dart';
import 'package:yellow/app/theme/theme_provider.dart';

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

  @override
  void initState() {
    super.initState();
    // Reset state to ensure clean start (clears any previous location)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taxiRequestProvider.notifier).reset();
      // Auto-fetch location on entry
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
    final themeConfig = ref.watch(themeConfigProvider);

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
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), // Orange for Origin
        draggable: true,
        onDragEnd: (newPos) => taxiNotifier.updateOriginFromMarker(newPos),
      ));
    }
    if (taxiState.destinationLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('dest'),
        position: taxiState.destinationLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), // Red for Destination
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
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ));
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
              _mapController?.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: southwest, northeast: northeast), 80));
           });
        }
    });


    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Force dark icons
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Google Map Background
          if (taxiState.originLocation == null)
             // Initial Loading State
              const Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   CircularProgressIndicator(color: Colors.amber),
                   SizedBox(height: 16),
                   Text("Buscando tu ubicación...", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ))
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: taxiState.originLocation!,
                zoom: 16.0,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: taxiState.isManualSelectionMode ? {} : markers, // Hide markers when selecting manually
              polylines: polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              padding: const EdgeInsets.only(bottom: 200), // Push Google Logo up
              onCameraMove: (position) {
                _currentCameraCenter = position.target;
              },
            ),

          // SCOPE SIGHT (Only in Manual Mode)
          if (taxiState.isManualSelectionMode)
             const Center(
               child: Icon(Icons.center_focus_strong, size: 40, color: Colors.black),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 8,
                    ),
                    child: const Text("CONFIRMAR UBICACIÓN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => taxiNotifier.setManualSelectionMode(false),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("Cancelar", style: TextStyle(color: Colors.black, fontSize: 16)),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  // Origin Selection Mode
                  if (!taxiState.isOriginInputVisible && taxiState.originAddress.isEmpty)
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text("¿Dónde estás?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                       const SizedBox(height: 12),
                       Row(
                         children: [
                           Expanded(
                             child: ElevatedButton.icon(
                               onPressed: () => taxiNotifier.useMyLocation(),
                               icon: const Icon(Icons.my_location, color: Colors.black),
                               label: const Text("Usa mi ubicación"),
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: themeConfig.accentColor,
                                 foregroundColor: Colors.black,
                                 elevation: 0,
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                               ),
                             ),
                           ),
                           const SizedBox(width: 10),
                           Expanded(
                             child: OutlinedButton(
                               onPressed: () => taxiNotifier.showOriginInput(),
                               style: OutlinedButton.styleFrom(
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                 side: BorderSide(color: Colors.grey.shade300),
                               ),
                               child: const Text("Buscar otra", style: TextStyle(color: Colors.black)),
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
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: 'Punto de partida',
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      prefixIcon: Icon(Icons.circle, size: 14, color: themeConfig.primaryColor),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onTap: () => taxiNotifier.setFocus(true),
                    onChanged: (val) => taxiNotifier.onQueryChanged(val),
                    onSubmitted: (val) => taxiNotifier.searchLocation(val),
                  ),
                  
                  // Action Buttons (Only when focused)
                  if (taxiState.isOriginFocused)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                 taxiNotifier.useMyLocation();
                                 FocusScope.of(context).unfocus();
                              },
                              icon: const Icon(Icons.my_location, size: 16),
                              label: const Text("Usa mi ubicación"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE3F2FD),
                                foregroundColor: Colors.blue[800],
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Continue Button
                          if (_originController.text.isNotEmpty)
                          Expanded(
                             child: ElevatedButton.icon(
                               onPressed: () {
                                 taxiNotifier.setFocus(false); // Show destination
                                 Future.delayed(const Duration(milliseconds: 100), () {
                                   if (context.mounted) FocusScope.of(context).requestFocus(_destFocus);
                                 });
                               }, 
                               icon: const Icon(Icons.arrow_forward, size: 16),
                               label: const Text("Confirmar"),
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: Colors.black, 
                                 foregroundColor: Colors.white,
                                 elevation: 0,
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Icon(Icons.more_vert, size: 16, color: Colors.grey.shade300),
                        ),
                        TextField(
                          controller: _destinationController,
                          focusNode: _destFocus,
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            labelText: '¿A dónde quieres ir?',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            prefixIcon: const Icon(Icons.circle, size: 14, color: Colors.black),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onTap: () => taxiNotifier.setFocus(false),
                          onChanged: (val) => taxiNotifier.onQueryChanged(val),
                          onSubmitted: (val) => taxiNotifier.searchLocation(val),
                        ),
                        // Choose on Map Button
                        if (_destFocus.hasFocus) // Only show when focused/typing
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
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
              top: taxiState.isOriginFocused ? 200 : 300, 
              left: 20,
              right: 20,
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: taxiState.predictions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final p = taxiState.predictions[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on_outlined, color: Colors.grey),
                        title: Text(p['description'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                        onTap: () {
                           taxiNotifier.onPredictionSelected(p['place_id'], p['description']);
                           FocusScope.of(context).unfocus(); // Hide keyboard
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

          // Trip Details Card (Bottom)
          if (taxiState.routeInfo != null && !taxiState.isManualSelectionMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.only(bottom: 20),
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _TripInfoItem(
                          label: 'Distancia',
                          value: taxiState.routeInfo!['distance_text'],
                          icon: Icons.straighten,
                        ),
                        Container(height: 40, width: 1, color: Colors.grey.shade200),
                         _TripInfoItem(
                          label: 'Tiempo',
                          value: taxiState.routeInfo!['duration_text'],
                          icon: Icons.timer_outlined,
                        ),
                        Container(height: 40, width: 1, color: Colors.grey.shade200),
                         // Price Display (Compact)
                         Column(
                           children: [
                              Text("\$${taxiState.estimatedFare}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                              const Text("Estimado", style: TextStyle(fontSize: 12, color: Colors.grey)),
                           ],
                         )
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Scheduled Time Picker
                    if (taxiState.estimatedFare > 0)
                      GestureDetector(
                        onTap: () => _selectDateTime(context, taxiNotifier),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                               Icon(Icons.calendar_today, size: 20, color: themeConfig.primaryColor),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: Text(
                                   taxiState.scheduledTime != null 
                                     ? "Programado: ${DateFormat('dd MMM HH:mm').format(taxiState.scheduledTime!)}"
                                     : "Programar este viaje (Ahora)",
                                   style: const TextStyle(fontWeight: FontWeight.w600),
                                 ),
                               ),
                               const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      
                    // Payment Method Selector
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _PaymentOption(
                            label: 'Efectivo',
                            icon: Icons.money,
                            isSelected: taxiState.selectedPaymentMethod == 'cash',
                            onTap: () => taxiNotifier.setPaymentMethod('cash'),
                          ),
                          _PaymentOption(
                            label: (taxiState.selectedPaymentMethod == 'card' && taxiState.defaultPaymentMethod != null)
                                ? '${taxiState.defaultPaymentMethod['brand'] ?? 'Tarjeta'} ${taxiState.defaultPaymentMethod['last_four'] ?? ''}' 
                                : 'Tarjeta',
                            icon: Icons.credit_card,
                            isSelected: taxiState.selectedPaymentMethod == 'card',
                            onTap: () async {
                              final success = await taxiNotifier.setPaymentMethod('card');
                              if (!success && context.mounted) {
                                  // Navigate to Add Card
                                  context.push('/dashboard/add-card');
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // Request Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeConfig.buttonColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                          shadowColor: themeConfig.buttonColor.withOpacity(0.5),
                        ),
                        onPressed: () {
                          if (taxiState.scheduledTime != null) {
                             // Direct create for scheduled? Or also ask payment?
                             // Assuming payment needed for all.
                             _showPaymentSelectionModal(context, taxiNotifier);
                          } else {
                             _showPaymentSelectionModal(context, taxiNotifier);
                          }
                        },
                          child: Text(
                            taxiState.scheduledTime != null ? 'RESERVAR VIAJE' : 'SELECCIONAR PAGO', 
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Cancel
                    TextButton(
                      child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      onPressed: () {
                         taxiNotifier.reset();
                         _originController.clear();
                         _destinationController.clear();
                         context.pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
            
           // Loading Overlay
           if (taxiState.isLoading && taxiState.originLocation != null)
             Container(
               color: Colors.black12,
               child: const Center(
                 child: CircularProgressIndicator(),
               ),
             ),
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
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Colors.black)),
        child: child!,
      ),
    );
    
    if (date != null && context.mounted) {
       final time = await showTimePicker(
         context: context,
         initialTime: TimeOfDay.now(),
         builder: (context, child) => Theme(
             data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Colors.black)),
             child: child!
         ),
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

  void _showPaymentSelectionModal(BuildContext context, TaxiRequestNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PaymentSelectionSheet(
        onConfirm: (method) async {
           Navigator.pop(ctx); // Close sheet
           
           // Show Loading?
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Procesando solicitud...')));
           
           final tripId = await notifier.createTrip(paymentMethod: method);
           
           if (tripId != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Viaje solicitado con éxito!')));
              notifier.reset();
              _originController.clear();
              _destinationController.clear();
              notifier.useMyLocation();
              context.go('/dashboard/trip-tracking/$tripId');
           } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al solicitar viaje')));
           }
        },
      ),
    );
  }
}

class _PaymentSelectionSheet extends StatefulWidget {
  final Function(String) onConfirm;
  const _PaymentSelectionSheet({required this.onConfirm});

  @override
  State<_PaymentSelectionSheet> createState() => _PaymentSelectionSheetState();
}

class _PaymentSelectionSheetState extends State<_PaymentSelectionSheet> {
  String selectedMethod = 'CASH';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Center(
             child: Container(
               width: 40, height: 4, 
               decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
             )
           ),
           const SizedBox(height: 24),
           const Text("Selecciona Método de Pago", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
           const SizedBox(height: 24),
           
           _buildOption(
             id: 'CASH', 
             icon: Icons.money, 
             title: 'Efectivo', 
             subtitle: 'Paga al conductor directamente'
           ),
           const SizedBox(height: 12),
           _buildOption(
             id: 'WALLET', 
             icon: Icons.account_balance_wallet, 
             title: 'Billetera', 
             subtitle: 'Saldo disponible: \$142.50',
             isPremium: true
           ),
           const SizedBox(height: 12),
           _buildOption(
             id: 'CARD', 
             icon: Icons.credit_card, 
             title: 'Tarjeta', 
             subtitle: '**** 1234',
             isDisabled: true
           ),
           
           const SizedBox(height: 32),
           SizedBox(
             width: double.infinity,
             child: ElevatedButton(
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.black,
                 padding: const EdgeInsets.symmetric(vertical: 18),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
               ),
               onPressed: () => widget.onConfirm(selectedMethod),
               child: const Text("SOLICITAR TAXI", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
             ),
           )
        ],
      ),
    ),
    );
  }

  Widget _buildOption({
    required String id, 
    required IconData icon, 
    required String title, 
    String? subtitle, 
    bool isPremium = false,
    bool isDisabled = false
  }) {
    final isSelected = selectedMethod == id;
    return GestureDetector(
      onTap: isDisabled ? null : () => setState(() => selectedMethod = id),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black.withOpacity(0.05) : Colors.white,
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey.shade200, 
              width: isSelected ? 2 : 1
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
               Icon(icon, color: isPremium ? Colors.orange : Colors.black),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (subtitle != null)
                        Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                   ],
                 ),
               ),
               if (isSelected)
                 const Icon(Icons.check_circle, color: Colors.black),
            ],
          ),
        ),
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
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset:const Offset(0,2))] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.black : Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
