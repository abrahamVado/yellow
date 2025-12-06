import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yellow/features/dashboard/presentation/providers/taxi_request_provider.dart';

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
    final myTrips = taxiState.myTrips;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Mis Viajes", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: taxiState.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
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
                        children: const [
                          SizedBox(height: 100),
                           Center(child: Text("No tienes viajes recientes")),
                        ],
                      )
                    : ListView.builder( 
                        padding: EdgeInsets.only(top: taxiState.errorMessage != null ? 40 : 16, left: 16, right: 16, bottom: 16),
                        itemCount: myTrips.length,
                        itemBuilder: (context, index) {
                          final trip = myTrips[index];
                          return TripCard(trip: trip);
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
  const TripCard({super.key, required this.trip});

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
    
    if (status == 'requested') {
        statusColor = Colors.orange;
        statusText = 'Solicitado';
    } else if (status == 'completed') {
        statusColor = Colors.green;
        statusText = 'Completado';
    } else if (status == 'cancelled') {
        statusColor = Colors.red;
        statusText = 'Cancelado';
    }

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Destination, Price, Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Destino", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          destAddress,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                       Text("\$${fare.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                       const SizedBox(height: 4),
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    const Divider(height: 24),
                    
                    // Origin
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.my_location, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
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
                    const SizedBox(height: 12),
                    
                    // Metadata Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         if (distanceText.isNotEmpty)
                           Row(children: [
                              const Icon(Icons.straighten, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(distanceText, style: const TextStyle(color: Colors.grey)),
                           ]),
                         Row(children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(_formatDate(createdAt), style: const TextStyle(color: Colors.grey)),
                         ]),
                      ],
                    ),

                    // Cancel Action
                    if (status == 'requested')
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _confirmCancel(context, trip['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700], // Red Blood
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text("CANCELAR VIAJE", style: TextStyle(fontWeight: FontWeight.bold)),
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
