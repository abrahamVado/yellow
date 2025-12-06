import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
              child: myTrips.isEmpty
                ? Stack(
                    children: [
                      ListView(), // Needed for RefreshIndicator to work on empty list
                      const Center(child: Text("No tienes viajes recientes")),
                    ],
                  )
                : ListView.builder( 
                    padding: const EdgeInsets.all(16),
                    itemCount: myTrips.length,
                    itemBuilder: (context, index) {
                      final trip = myTrips[index];
                      return _buildTripCard(trip);
                    },
                  ),
            ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    // Format date if needed
    final createdAt = trip['created_at'] ?? '';
    final status = trip['status'] ?? 'pending';
    final fare = _parseDouble(trip['fare']);
    final originLat = _parseDouble(trip['origin_lat']);
    final originLng = _parseDouble(trip['origin_lng']);
    final destLat = _parseDouble(trip['dest_lat']);
    final destLng = _parseDouble(trip['dest_lng']);
    
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(createdAt, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                 const Icon(Icons.location_on, size: 16, color: Colors.blue),
                 const SizedBox(width: 4),
                 Expanded(
                   child: Text(
                     "Origen: ${originLat.toStringAsFixed(5)}, ${originLng.toStringAsFixed(5)}",
                     style: const TextStyle(fontSize: 14, color: Colors.black),
                     overflow: TextOverflow.ellipsis,
                   ),
                 ),
              ],
            ),
            const SizedBox(height: 8),
             // Destination
             if (destLat != 0.0)
             Row(
              children: [
                 const Icon(Icons.location_on, size: 16, color: Colors.green),
                 const SizedBox(width: 4),
                 Expanded(
                   child: Text(
                     "Destino: ${destLat.toStringAsFixed(5)}, ${destLng.toStringAsFixed(5)}",
                     style: const TextStyle(fontSize: 14, color: Colors.black),
                     overflow: TextOverflow.ellipsis,
                   ),
                 ),
              ],
            ),
             
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("\$${fare.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
          ],
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
}
