import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:yellow/core/config/app_config.dart';
import 'package:yellow/core/services/google_maps_service.dart';
import 'package:dio/dio.dart';
import 'package:yellow/core/network/dio_client.dart';

// State class for Taxi Request
class TaxiRequestState {
  final String originAddress;
  final LatLng? originLocation;
  final String destinationAddress;
  final LatLng? destinationLocation;
  final List<Map<String, dynamic>> predictions;
  final String sessionToken;
  final Map<String, dynamic>? routeInfo;
  final bool isLoading;
  final bool isOriginFocused; // Track which input is focused

  TaxiRequestState({
    this.originAddress = '',
    this.originLocation,
    this.destinationAddress = '',
    this.destinationLocation,
    this.predictions = const [],
    required this.sessionToken,
    this.routeInfo,
    this.isLoading = false,
    this.isOriginFocused = true,
  });

  TaxiRequestState copyWith({
    String? originAddress,
    LatLng? originLocation,
    String? destinationAddress,
    LatLng? destinationLocation,
    List<Map<String, dynamic>>? predictions,
    String? sessionToken,
    Map<String, dynamic>? routeInfo,
    bool? isLoading,
    bool? isOriginFocused,
  }) {
    return TaxiRequestState(
      originAddress: originAddress ?? this.originAddress,
      originLocation: originLocation ?? this.originLocation,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      predictions: predictions ?? this.predictions,
      sessionToken: sessionToken ?? this.sessionToken,
      routeInfo: routeInfo ?? this.routeInfo,
      isLoading: isLoading ?? this.isLoading,
      isOriginFocused: isOriginFocused ?? this.isOriginFocused,
    );
  }
}

// Provider for GoogleMapsService
final googleMapsServiceProvider = Provider<GoogleMapsService>((ref) {
  final appConfig = ref.watch(appConfigProvider);
  return GoogleMapsService(Dio(), appConfig.env.googleMapsApiKey);
});



// StateNotifier for Taxi Request logic
class TaxiRequestNotifier extends StateNotifier<TaxiRequestState> {
  final GoogleMapsService _googleMapsService;
  final Dio _dio;
  final Uuid _uuid = const Uuid();

  TaxiRequestNotifier(this._googleMapsService, this._dio)
      : super(TaxiRequestState(sessionToken: const Uuid().v4()));

  void setFocus(bool isOrigin) {
    state = state.copyWith(isOriginFocused: isOrigin, predictions: []);
  }

  void onQueryChanged(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(predictions: []);
      return;
    }
    
    // Simple debounce could be added here in UI or via RxDart, keeping it simple for now
    final predictions = await _googleMapsService.getPlacePredictions(query, state.sessionToken);
    state = state.copyWith(predictions: predictions);
  }

  Future<void> onPredictionSelected(String placeId, String description) async {
    state = state.copyWith(isLoading: true, predictions: []);

    try {
      final details = await _googleMapsService.getPlaceDetails(placeId, state.sessionToken);
      
      if (details != null) {
        final location = details['geometry']['location'];
        final latLng = LatLng(location['lat'], location['lng']);

        if (state.isOriginFocused) {
          state = state.copyWith(
            originAddress: description,
            originLocation: latLng,
            sessionToken: _uuid.v4(), // Regenerate token after selection
          );
        } else {
          state = state.copyWith(
            destinationAddress: description,
            destinationLocation: latLng,
            sessionToken: _uuid.v4(), // Regenerate token after selection
          );
        }
        
        // Calculate Route if both points are set
        if (state.originLocation != null && state.destinationLocation != null) {
            _calculateRoute();
        }
      }
    } catch (e) {
      print('Error selecting place: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _calculateRoute() async {
      if (state.originLocation == null || state.destinationLocation == null) return;
      
      state = state.copyWith(isLoading: true);
      final routeStart = state.originLocation!;
      final routeEnd = state.destinationLocation!;
      
      // Check again to be safe due to async nature
      if (routeStart != state.originLocation || routeEnd != state.destinationLocation) return;
      
      final routeInfo = await _googleMapsService.getRouteCoordinates(routeStart, routeEnd);
      state = state.copyWith(routeInfo: routeInfo, isLoading: false);
  }

  Future<bool> createTrip() async {
    if (state.originLocation == null) return false;

    state = state.copyWith(isLoading: true);
    try {
      final data = {
        'origin_lat': state.originLocation!.latitude,
        'origin_lng': state.originLocation!.longitude,
        'dest_lat': state.destinationLocation?.latitude,
        'dest_lng': state.destinationLocation?.longitude,
        'fare': 0.0, // Placeholder
        'distance_meters': state.routeInfo?['distance_value'],
        'duration_seconds': state.routeInfo?['duration_value'],
      };

      // Assuming the endpoint is mounted at /auth/trips or /trips depending on router.
      // Based on flutter.go, it was mounted at /trips inside registerFlutterRoutes.
      // Flutter routes are usually /api/something if checking web.go but let's assume /trips matches the group.
      // Wait, web.go mounts registerFlutterRoutes at root router. 
      // And auth routes are /auth.
      // So trips routes are /trips.
      
      final response = await _dio.post('/trips', data: data);
      
      if (response.statusCode == 201) {
          // Success
          return true;
      }
      return false;
    } catch (e) {
      print('Error creating trip: $e');
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
  
  // Method to manually clear or reset if needed
  void reset() {
       state = TaxiRequestState(sessionToken: _uuid.v4());
  }
}

final taxiRequestProvider = StateNotifierProvider<TaxiRequestNotifier, TaxiRequestState>((ref) {
  final botService = ref.watch(googleMapsServiceProvider);
  final dio = ref.watch(dioProvider);
  return TaxiRequestNotifier(botService, dio);
});
