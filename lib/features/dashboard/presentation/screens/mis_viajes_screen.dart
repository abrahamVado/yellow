import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yellow/features/dashboard/presentation/providers/taxi_request_provider.dart';
import 'package:yellow/app/theme/theme_provider.dart';
import 'package:yellow/app/theme/app_theme.dart';

class MisViajesScreen extends ConsumerStatefulWidget {
  const MisViajesScreen({super.key});

  @override
  ConsumerState<MisViajesScreen> createState() => _MisViajesScreenState();
}

class _MisViajesScreenState extends ConsumerState<MisViajesScreen> {
  
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
    // Fetch trips when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taxiRequestProvider.notifier).fetchMyTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taxiState = ref.watch(taxiRequestProvider);
    final themeConfig = ref.watch(themeConfigProvider);
    final myTrips = taxiState.myTrips;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Mis Viajes", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: taxiState.isLoading 
          ? Center(child: CircularProgressIndicator(color: themeConfig.primaryColor))
          : RefreshIndicator(
              color: themeConfig.primaryColor,
              onRefresh: () => ref.read(taxiRequestProvider.notifier).fetchMyTrips(),
              child: Stack(
                children: [
                   if (taxiState.errorMessage != null)
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          color: Colors.redAccent,
                          child: Text(
                            taxiState.errorMessage!,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                   
                   myTrips.isEmpty
                    ? ListView(
                        children: [
                           const SizedBox(height: 100),
                           Center(
                             child: Column(
                               children: [
                                 Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                                 const SizedBox(height: 16),
                                 Text("Aún no tienes viajes", style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                               ],
                             ),
                           ),
                        ],
                      )
                    : ListView.builder( 
                        padding: EdgeInsets.only(top: taxiState.errorMessage != null ? 40 : 16, left: 20, right: 20, bottom: 20),
                        itemCount: myTrips.length,
                        itemBuilder: (context, index) {
                          final trip = myTrips[index];
                          return TripCard(trip: trip, theme: themeConfig);
                        },
                      ),
                ],
              ),
            ),
    );
  }
}

class TripCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> trip;
  final AppThemeConfig theme;
  
  const TripCard({super.key, required this.trip, required this.theme});

  @override
  ConsumerState<TripCard> createState() => _TripCardState();
}

class _TripCardState extends ConsumerState<TripCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Extract Data
    final trip = widget.trip;
    final createdAt = trip['created_at'] ?? '';
    final status = trip['status'] ?? 'pending';
    final fare = _parseDouble(trip['fare']);
    
    // Addresses - Prefer human readable, fallback to coords
    final originAddress = trip['origin_address']?['String'] ?? trip['origin_address'] ?? 
                         "${_parseDouble(trip['origin_lat']).toStringAsFixed(5)}, ${_parseDouble(trip['origin_lng']).toStringAsFixed(5)}";
    
    final destAddress = trip['dest_address']?['String'] ?? trip['dest_address'] ?? 
                       "${_parseDouble(trip['dest_lat']).toStringAsFixed(5)}, ${_parseDouble(trip['dest_lng']).toStringAsFixed(5)}";

    final distanceText = _formatDistance(trip['distance_meters']);
    
    Color statusColor = Colors.grey;
    String statusText = status;
    
    if (status == 'requested' || status == 'queued' || status == 'pending') {
        statusColor = Colors.orange;
        statusText = 'Solicitado';
    } else if (status == 'matched') {
        statusColor = Colors.blue;
        statusText = 'En Camino';
    } else if (status == 'in_progress') {
        statusColor = widget.theme.primaryColor;
        statusText = 'En Viaje';
    } else if (status == 'completed') {
        statusColor = Colors.green;
        statusText = 'Completado';
    } else if (status == 'cancelled') {
        statusColor = Colors.red;
        statusText = 'Cancelado';
    } else {
        statusText = status; // Fallback
    }

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Destination, Price, Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on, size: 24, color: Colors.black),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destAddress,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(createdAt), 
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                       Text("\$${fare.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                       const SizedBox(height: 6),
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),

              // Expanded Details: Origin, Distance, Date, Cancel
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Colors.grey),
                    const SizedBox(height: 16),
                    
                    // Origin
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 12),
                         Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Origen", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(
                                originAddress,
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Metadata Row
                    if (distanceText.isNotEmpty)
                    Row(children: [
                        const Icon(Icons.straighten, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text("Distancia: $distanceText", style: const TextStyle(color: Colors.grey)),
                    ]),

                    // Cancel Action
                    if (status == 'requested')
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _confirmCancel(context, trip['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text("CANCELAR SOLICITUD", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                  ],
                ),
                crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is Map && value.containsKey('Float64')) {
         return _parseDouble(value['Float64']);
    }
    return 0.0;
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEE d MMM, hh:mm a', 'es').format(date.toLocal());
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDistance(dynamic dist) {
    int meters = 0;
    if (dist is int) meters = dist;
    else if (dist is double) meters = dist.toInt();
    else if (dist is Map && (dist['Valid'] == true || dist['valid'] == true)) {
         meters = (dist['Int64'] ?? dist['int64'] ?? 0).toInt();
    }
    
    if (meters == 0) return '';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  void _confirmCancel(BuildContext context, dynamic tripIdPrimitive) {
     int tripId = 0;
     if (tripIdPrimitive is int) tripId = tripIdPrimitive;
     if (tripId == 0) return;

     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
         backgroundColor: Colors.white,
         title: const Text("Cancelar Viaje", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
         content: const Text("¿Estás seguro que deseas cancelar este viaje?", style: TextStyle(color: Colors.black)),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(ctx),
             child: const Text("No", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
           ),
           TextButton(
             onPressed: () {
               Navigator.pop(ctx);
               ref.read(taxiRequestProvider.notifier).cancelTrip(tripId);
             },
             child: const Text("Sí, Cancelar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
           ),
         ],
       ),
     );
  }
}
