import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
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

  Future<void> useMyLocation() async {
    state = state.copyWith(isLoading: true);
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
            // Permissions are denied
            state = state.copyWith(isLoading: false);
            return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever
        state = state.copyWith(isLoading: false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      // Reverse Geocode
      final address = await _googleMapsService.getAddressFromCoordinates(latLng);

      state = state.copyWith(
        originLocation: latLng,
        originAddress: address ?? '${latLng.latitude}, ${latLng.longitude}',
        isOriginFocused: false, // Move focus away or keep it, user preference
        isLoading: false,
        sessionToken: _uuid.v4(),
      );
      
      // Calculate route if destination is already set
      if (state.destinationLocation != null) {
          _calculateRoute();
      }

    } catch (e) {
      print('Error getting location: $e');
      state = state.copyWith(isLoading: false);
    }
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
       // Minatitlán, Veracruz default location
       // 17.9982, -94.5456
       state = TaxiRequestState(
          sessionToken: _uuid.v4(),
          originLocation: const LatLng(17.9982, -94.5456), 
          // Not setting address text to avoid overwriting user intent if they want to type, 
          // but map will center here initially if we use originLocation for map camera.
          // Wait, if originLocation is set, the map and markers will show it.
          // The requirement says "by default the map should load in minatitlan", 
          // usually this means Camera Position, not necessarily "Origin Selected".
          // But if we want the map to start there, we can pass this to the GoogleMap widget.
          // For now, let's just make sure reset clears things properly.
       );
  }
}

final taxiRequestProvider = StateNotifierProvider<TaxiRequestNotifier, TaxiRequestState>((ref) {
  final botService = ref.watch(googleMapsServiceProvider);
  final dio = ref.watch(dioProvider);
  return TaxiRequestNotifier(botService, dio);
});
