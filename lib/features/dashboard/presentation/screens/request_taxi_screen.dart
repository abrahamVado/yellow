import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:go_router/go_router.dart';
import 'package:yellow/features/dashboard/presentation/providers/taxi_request_provider.dart';
import 'package:yellow/features/payment/data/repositories/payment_repository.dart';
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
                      
                    // Payment Method Selector REMOVED (Redundant)

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
                          // Always show modal for final confirmation
                           _showPaymentSelectionModal(context, taxiNotifier);
                        },
                          child: Text(
                            taxiState.scheduledTime != null ? 'PROGRAMAR VIAJE' : 'SOLICITAR VIAJE', 
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)
                          ),
                        ),
                      ),
// ... (skip down to modal)

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

  Future<String?> _showCvvDialog(BuildContext context) async {
    String cvv = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Confirmación de Seguridad', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
               'Ingresa el CVV de tu tarjeta para autorizar el cobro al finalizar el viaje.',
               style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 16),
             TextField(
              autofocus: true,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              cursorColor: Colors.black,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                labelText: 'CVV',
                labelStyle: TextStyle(color: Colors.black54),
                hintText: '123',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black26)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                counterText: "",
                prefixIcon: Icon(Icons.lock_outline, color: Colors.black54),
                filled: true,
                fillColor: Colors.white,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (val) => cvv = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
               if (cvv.length >= 3) {
                  Navigator.pop(context, cvv);
               }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showPaymentSelectionModal(BuildContext context, TaxiRequestNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PaymentSelectionSheet(
        onConfirm: (method, cardId) async {
           Navigator.pop(ctx); // Close sheet
           
           String? token;
           
           // CVV Prompt for Cards
           if (method == 'card' && cardId != null) {
               final cvv = await _showCvvDialog(context);
               if (cvv == null) return; // Cancelled
               
               // Show processing
               if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verificando tarjeta...')));
               
               try {
                  final repo = ref.read(paymentRepositoryProvider);
                  final publicKey = await repo.getPublicKey();
                  if (publicKey == null) throw Exception("Error de configuración");
                  
                  // Find the MP Card ID (Token) from the provider list
                  final methods = ref.read(taxiRequestProvider).paymentMethods;
                  final selectedMethod = methods.firstWhere(
                      (m) => m['id'] == cardId, 
                      orElse: () => null
                  );
                  
                  if (selectedMethod == null) throw Exception("Tarjeta no encontrada");
                  
                  // Use the MP Card Token (stored in 'token' field)
                  final mpCardId = selectedMethod['token']?.toString() ?? '';
                  if (mpCardId.isEmpty) throw Exception("Datos de tarjeta inválidos");

                  token = await repo.tokenizeSavedCard(mpCardId, cvv, publicKey);
               } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  return;
               }
           }

           // Show Loading
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitando viaje...'))); // Consider using a better loader
           
           final tripId = await notifier.createTrip(paymentMethod: method, cardId: cardId, token: token);
           
           if (tripId != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Viaje solicitado con éxito!')));
              notifier.reset();
              _originController.clear();
              _destinationController.clear();
              notifier.useMyLocation();
              context.go('/dashboard/trip-tracking/$tripId');
           } else if (context.mounted) {
              // Error is usually handled/printed by provider but lets show generic error
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al solicitar viaje. Intente nuevamente.')));
           }
        },

      ),
    );
  }
}

class _PaymentSelectionSheet extends ConsumerStatefulWidget {
  final Function(String, int?) onConfirm;
  const _PaymentSelectionSheet({required this.onConfirm});

  @override
  ConsumerState<_PaymentSelectionSheet> createState() => _PaymentSelectionSheetState();
}

class _PaymentSelectionSheetState extends ConsumerState<_PaymentSelectionSheet> {
  String selectedMethod = 'CASH';

  @override
  void initState() {
    super.initState();
    // Fetch payment methods when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
       ref.read(taxiRequestProvider.notifier).fetchPaymentMethods();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taxiState = ref.watch(taxiRequestProvider);
    final paymentMethods = taxiState.paymentMethods;
    final defaultCard = taxiState.defaultPaymentMethod;
    // Set initial selection if not set (could use widget.initialSelection if added)
    
    // Determine the active card ID for UI highlighting
    // If selectedMethod is 'card', we need a sub-selection. 
    // For now, we assume if method is 'card', we track specific card ID externally or use default.
    // Let's rely on local state `selectedMethod` (which we might overload or add a new var).
    
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
               ),
             ),
             const SizedBox(height: 24),
             const Text("Selecciona Método de Pago", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
             const SizedBox(height: 24),
             
             // Options
             _buildOption(
               id: 'CASH',
               icon: Icons.money_off,
               title: 'Efectivo',
               subtitle: 'Paga al conductor directamente',
             ),
             const SizedBox(height: 16),
             
             // Wallet (Disabled for now)
             _buildOption(
               id: 'WALLET',
               icon: Icons.account_balance_wallet,
               title: 'Billetera',
               subtitle: 'Saldo disponible: \$0.00',
               isDisabled: true, 
             ),
             const SizedBox(height: 24),
             
             const Text("Mis Tarjetas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
             const SizedBox(height: 12),

             if (paymentMethods.isEmpty)
                _buildAddCardOption(),
             
             ...paymentMethods.map((pm) {
                 final brand = pm['brand']?.toString().toUpperCase() ?? 'TARJETA';
                 final last4 = pm['last_four'] ?? pm['card_number']?.toString().substring(pm['card_number'].toString().length - 4) ?? '****';
                 // Use a composite ID or just check equality if we store object
                 final cardId = pm['id'];
                 // We use 'card:$id' as the unique ID for selection logic in this sheet
                 final selectionId = 'card:$cardId'; 
                 
                 return Padding(
                   padding: const EdgeInsets.only(bottom: 12.0),
                   child: _buildOption(
                     id: selectionId,
                     icon: Icons.credit_card,
                     title: '$brand  •••• $last4',
                     subtitle: pm['card_holder_name'] ?? 'Personal',
                     // If this matches, we are selecting 'card' method with this ID
                   ),
                 );
             }).toList(),
             
             if (paymentMethods.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: () async {
                       await context.push('/dashboard/add-card');
                       ref.read(taxiRequestProvider.notifier).fetchPaymentMethods();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Agregar nueva tarjeta"),
                  ),
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
                 onPressed: () {
                    // Start with generic CASH
                    String method = 'CASH';
                    int? cardId;

                    if (selectedMethod.startsWith('card:')) {
                       method = 'card';
                       cardId = int.tryParse(selectedMethod.split(':')[1]);
                    } else {
                       method = selectedMethod;
                    }
                    widget.onConfirm(method, cardId); // Pass BOTH
                 },
                 child: const Text("SOLICITAR VIAJE", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
               ),
             )
          ],
        ),
      ),
    );
  }

  Widget _buildAddCardOption() {
      return GestureDetector(
        onTap: () async {
           await context.push('/dashboard/add-card');
           ref.read(taxiRequestProvider.notifier).fetchPaymentMethods();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
          ),
          child: const Row(
            children: [
               Icon(Icons.add_circle_outline, color: Colors.blue),
               SizedBox(width: 16),
               Text("Agregar tarjeta débito / crédito", style: TextStyle(fontWeight: FontWeight.w600)),
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
    bool isDisabled = false,
    VoidCallback? onTapOverride,
  }) {
    final isSelected = selectedMethod == id;
    
    // Auto-select card if it was tapped effectively
    // But logic calls setState anyway.

    return GestureDetector(
      onTap: isDisabled ? null : (onTapOverride ?? () => setState(() => selectedMethod = id)),
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
            borderRadius: BorderRadius.circular(16)
          ),
          child: Row(
            children: [
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: isSelected ? Colors.black : Colors.grey.shade100,
                   borderRadius: BorderRadius.circular(12)
                 ),
                 child: Icon(icon, color: isSelected ? Colors.white : Colors.black, size: 24),
               ),
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
