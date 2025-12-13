import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yellow/core/config/app_config.dart';
import 'package:yellow/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:yellow/app/theme/theme_provider.dart';
import 'package:yellow/app/theme/app_theme.dart';
import 'package:yellow/features/dashboard/presentation/providers/taxi_request_provider.dart';

class TripTrackingScreen extends ConsumerWidget {
  final int tripId;

  const TripTrackingScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripStatusStreamProvider(tripId));
    final themeConfig = ref.watch(themeConfigProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _getStatusTitle(tripAsync.value?['status'] ?? 'requested'),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        automaticallyImplyLeading: false, 
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
            if (tripAsync.value?['status'] == 'requested' || tripAsync.value?['status'] == 'matched')
               Padding(
                 padding: const EdgeInsets.only(right: 8.0),
                 child: IconButton(
                   icon: const Icon(Icons.cancel, color: Colors.grey),
                   onPressed: () => _confirmCancel(context, ref),
                 ),
               )
        ],
      ),
      body: tripAsync.when(
        data: (data) => _buildBody(context, ref, data, themeConfig),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (err, stack) => Center(child: Text('Error loading trip: $err')),
      ),
    );
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'requested': 
      case 'queued':
      case 'pending':
        return 'Buscando Conductor...';
      case 'matched': return 'Conductor En Camino';
      case 'in_progress': return 'Viaje en Curso';
      case 'completed': return 'Llegaste';
      case 'cancelled': return 'Cancelado';
      default: return 'Detalles del Viaje';
    }
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, Map<String, dynamic> tripData, AppThemeConfig theme) {
    final status = tripData['status'];

    if (status == 'requested' || status == 'queued' || status == 'pending') {
       return Center(
         child: Padding(
           padding: const EdgeInsets.symmetric(horizontal: 24.0),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Container(
                 padding: const EdgeInsets.all(30),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   shape: BoxShape.circle,
                   boxShadow: [
                     BoxShadow(
                       color: theme.primaryColor.withOpacity(0.3),
                       blurRadius: 40,
                       spreadRadius: 5,
                     )
                   ]
                 ),
                 child: CircularProgressIndicator(strokeWidth: 4, color: theme.primaryColor),
               ),
               const SizedBox(height: 40),
               const Text(
                 "Buscando conductores cercanos...",
                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                 textAlign: TextAlign.center,
               ),
               const SizedBox(height: 12),
               Text(
                 "Estamos notificando a los conductores en tu zona. Por favor espera un momento.",
                 style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                 textAlign: TextAlign.center,
               ),
               const SizedBox(height: 10),
               Text("Viaje #$tripId", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
               
               const SizedBox(height: 48),
               
               // Back Button to allow user to use other app features while waiting
               OutlinedButton.icon(
                 onPressed: () => Navigator.of(context).pop(),
                 style: OutlinedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   side: BorderSide(color: Colors.grey.shade300),
                 ),
                 icon: const Icon(Icons.arrow_back, color: Colors.black),
                 label: const Text("Regresar al Menú", style: TextStyle(color: Colors.black)),
               ),
             ],
           ),
         ),
       );
    }

    if (status == 'matched' || status == 'in_progress') {
       return Stack(
         children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(tripData['origin_lat'], tripData['origin_lng']),
                zoom: 15,
              ),
              markers: _getMarkers(tripData, status),
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              padding: const EdgeInsets.only(top: 100, bottom: 250),
            ),
            
            // Driver Card (Bottom Sheet Style)
            if (tripData['driver'] != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
                    ],
                  ),
                  child: SafeArea(
                    top: false, 
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.primaryColor, width: 2),
                            ),
                            child: const CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, color: Colors.white, size: 35),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${tripData['driver']['first_name']} ${tripData['driver']['last_name']}",
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    const Text("4.9", style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Text(
                                      "•  ${tripData['driver']['brand'] != null ? "${tripData['driver']['brand']} ${tripData['driver']['model']} • " : ""}${tripData['driver']['license_plate'] ?? 'Placas Pendientes'}", 
                                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                               Icon(Icons.local_taxi, size: 30, color: theme.primaryColor),
                               Text("Taxi", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      ),

                      const SizedBox(height: 16),
                      // Safety Code / OTP Display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shield, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Código de seguridad: ${tripData['otp'] ?? tripId.toString().padLeft(4, '0')}",
                              style: const TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.orange
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Status Bar
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  status == 'matched' ? 'El conductor está en camino' : 'Viaje en progreso',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            if (status == 'matched')
                              const Text('~ 5 min', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
         ],
       );
    }
    
    if (status == 'completed') {
       return Center(
         child: Padding(
           padding: const EdgeInsets.all(32),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   color: Colors.green.shade50,
                   shape: BoxShape.circle,
                 ),
                 child: Icon(Icons.check_rounded, color: Colors.green.shade600, size: 80),
               ),
               const SizedBox(height: 32),
               const Text("¡Llegaste!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
               const SizedBox(height: 12),
               const Text("Esperamos que hayas disfrutado tu viaje.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
               const SizedBox(height: 40),
               Text("\$${tripData['fare'] ?? '0.00'}", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black)),
               const Text("Total a pagar", style: TextStyle(color: Colors.grey)),
               const SizedBox(height: 48),
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: () => Navigator.of(context).pop(), 
                   style: ElevatedButton.styleFrom(
                     backgroundColor: theme.buttonColor,
                     foregroundColor: theme.buttonTextColor,
                     padding: const EdgeInsets.symmetric(vertical: 20),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                   ),
                   child: const Text("CONTINUAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                 ),
               )
             ],
           ),
         ),
       );
    }
    
    if (status == 'cancelled') {
       final cancellationReason = tripData['cancellation_reason'] ?? '';
       final isNoDrivers = cancellationReason == 'no_drivers_available';
       
       return Center(
         child: Padding(
           padding: const EdgeInsets.all(24.0),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(
                 isNoDrivers ? Icons.search_off_rounded : Icons.cancel_outlined,
                 color: isNoDrivers ? Colors.orange : Colors.red,
                 size: 100,
               ),
               const SizedBox(height: 24),
               Text(
                 isNoDrivers ? "Sin conductores cercanos" : "Viaje Cancelado",
                 style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                 textAlign: TextAlign.center,
               ),
               const SizedBox(height: 12),
               Text(
                 isNoDrivers 
                   ? "Lo sentimos, no encontramos conductores disponibles en tu zona."
                   : "El viaje ha sido cancelado.",
                 style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                 textAlign: TextAlign.center,
               ),
               const SizedBox(height: 40),
               if (isNoDrivers) ...[
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton.icon(
                     icon: const Icon(Icons.refresh),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.black,
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 18),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     ),
                     onPressed: () {
                       Navigator.of(context).pop();
                     },
                     label: const Text("INTENTAR DE NUEVO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                   ),
                 ),
                 const SizedBox(height: 16),
               ],
               SizedBox(
                 width: double.infinity,
                 child: OutlinedButton(
                   onPressed: () => Navigator.of(context).pop(),
                   style: OutlinedButton.styleFrom(
                     padding: const EdgeInsets.symmetric(vertical: 18),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     side: BorderSide(color: Colors.grey.shade300),
                   ),
                   child: const Text("Ir al Inicio", style: TextStyle(fontSize: 16, color: Colors.black)),
                 ),
               ),
             ],
           ),
         ),
       );
    }

    return Center(child: Text("Estado Desconocido: $status"));
  }

  Set<Marker> _getMarkers(Map<String, dynamic> tripData, String status) {
    Set<Marker> markers = {};

    markers.add(Marker(
      markerId: const MarkerId('origin'),
      position: LatLng(tripData['origin_lat'], tripData['origin_lng']),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    ));

    if (status == 'matched' && tripData['driver'] != null) {
       final driver = tripData['driver'];
       if (driver['current_location_lat'] != null && driver['current_location_lng'] != null) {
          markers.add(Marker(
            markerId: const MarkerId('driver'),
            position: LatLng(
                (driver['current_location_lat'] as num).toDouble(),
                (driver['current_location_lng'] as num).toDouble()
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow), 
          ));
       }
    }
    
    return markers;
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Cancelar",
      pageBuilder: (ctx, anim1, anim2) {
        return Container();
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeInOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 40),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "¿Cancelar Viaje?",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Si cancelas ahora, podrías perder tu lugar en la fila de espera.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("No, mantener viaje", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _cancelTrip(context, ref);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Sí, cancelar viaje", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
