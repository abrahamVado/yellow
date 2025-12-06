import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as places_sdk;
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
  final bool isOriginInputVisible;
  final bool isOriginFocused;
  final double estimatedFare;
  final List<dynamic> myTrips;
  final String? errorMessage;
  final DateTime? scheduledTime;
  final bool isManualSelectionMode;

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
    this.isOriginInputVisible = false,
    this.estimatedFare = 0.0,
    this.myTrips = const [],
    this.errorMessage,
    this.scheduledTime,
    this.isManualSelectionMode = false,
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
    bool? isOriginInputVisible,
    double? estimatedFare,
    List<dynamic>? myTrips,
    String? errorMessage,
    DateTime? scheduledTime,
    bool? isManualSelectionMode,
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
      isOriginInputVisible: isOriginInputVisible ?? this.isOriginInputVisible,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      myTrips: myTrips ?? this.myTrips,
      errorMessage: errorMessage, // Reset error if not provided (or allow passing null)
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isManualSelectionMode: isManualSelectionMode ?? this.isManualSelectionMode,
    );
  }
}

// Provider for GoogleMapsService
final googleMapsServiceProvider = Provider<GoogleMapsService>((ref) {
  final appConfig = ref.watch(appConfigProvider);
  return GoogleMapsService(Dio(), appConfig.env.googleMapsApiKey);
});

final flutterGooglePlacesSdkProvider = Provider<places_sdk.FlutterGooglePlacesSdk>((ref) {
  final appConfig = ref.watch(appConfigProvider);
  return places_sdk.FlutterGooglePlacesSdk(appConfig.env.googleMapsApiKey); 
});


// StateNotifier for Taxi Request logic
class TaxiRequestNotifier extends StateNotifier<TaxiRequestState> {
  final GoogleMapsService _googleMapsService;
  final Dio _dio;
  final places_sdk.FlutterGooglePlacesSdk _places;
  final Uuid _uuid = const Uuid();

  TaxiRequestNotifier(this._googleMapsService, this._dio, this._places)
      : super(TaxiRequestState(sessionToken: const Uuid().v4()));

  void setFocus(bool isOrigin) {
    state = state.copyWith(isOriginFocused: isOrigin, predictions: []);
  }
  
  void showOriginInput() {
    state = state.copyWith(isOriginInputVisible: true, isOriginFocused: true);
  }

  void clearOrigin() {
    state = state.copyWith(
      originAddress: '',
      predictions: [],
      isOriginInputVisible: true,
      isOriginFocused: true,
    );
  }

  void onQueryChanged(String query) async {
    // Focus logic...
    if (state.isOriginFocused) {
       if (state.originAddress.isNotEmpty && query != state.originAddress) {
          state = state.copyWith(originAddress: '');
       }
    } else {
       if (state.destinationAddress.isNotEmpty && query != state.destinationAddress) {
          state = state.copyWith(destinationAddress: '');
       }
    }

    if (query.isEmpty) {
      state = state.copyWith(predictions: []);
      return;
    }
    
    try {
      final response = await _places.findAutocompletePredictions(
        query,
        countries: ['mx'], // Restrict to Mexico using SDK
        newSessionToken: false, 
      );
      
      final preds = response.predictions.map((p) => {
        'place_id': p.placeId,
        'description': p.fullText, // or primaryText + secondaryText
        'primary_text': p.primaryText,
        'secondary_text': p.secondaryText,
      }).toList();
      
      print("SDK Autocomplete results: ${preds.length}");
      state = state.copyWith(predictions: preds);
      
    } catch (e) {
      print("SDK Autocomplete Error: $e");
    }
  }

  Future<void> onPredictionSelected(String placeId, String description) async {
    state = state.copyWith(isLoading: true, predictions: []);

    try {
      // Use SDK to fetch details (bypasses API/Dio restrictions)
      final response = await _places.fetchPlace(
        placeId,
        fields: [
          places_sdk.PlaceField.Location, 
          places_sdk.PlaceField.Address, 
          places_sdk.PlaceField.Name
        ],
      );
      
      final place = response.place;
      
      if (place != null && place.latLng != null) {
        // Convert SDK LatLng to Google Maps LatLng
        final latLng = LatLng(place.latLng!.lat, place.latLng!.lng);
        
        final address = place.address ?? description;

        if (state.isOriginFocused) {
          state = state.copyWith(
            originAddress: address,
            originLocation: latLng,
            sessionToken: _uuid.v4(), 
            isOriginFocused: false, 
          );
        } else {
          state = state.copyWith(
            destinationAddress: address,
            destinationLocation: latLng,
            sessionToken: _uuid.v4(), 
          );
        }
        
        if (state.originLocation != null && state.destinationLocation != null) {
            _calculateRoute();
        }
      }
    } catch (e) {
      print('SDK Fetch Place Error: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }


  Future<void> searchLocation(String query) async {
    print('Searching location for: $query'); 
    if (query.isEmpty) return;
    
    state = state.copyWith(isLoading: true, predictions: []);
    
    try {
      // Use native geocoding package
      List<geo.Location> locations = await geo.locationFromAddress(query);
      
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final latLng = LatLng(loc.latitude, loc.longitude);
        print('Native Search result: $latLng');
        
        // Improve formatting
        List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(loc.latitude, loc.longitude);
        String formattedAddress = query;
        if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            formattedAddress = '${p.street}, ${p.locality}, ${p.country}'; 
        }

        if (state.isOriginFocused) {
            state = state.copyWith(
              originAddress: formattedAddress,
              originLocation: latLng,
              sessionToken: _uuid.v4(),
              isOriginFocused: false, // Move focus to dest
            );
        } else {
            state = state.copyWith(
              destinationAddress: formattedAddress,
              destinationLocation: latLng,
              sessionToken: _uuid.v4(),
            );
        }
        
        if (state.originLocation != null && state.destinationLocation != null) {
          _calculateRoute();
        }
      }
    } catch (e) {
      print('Native Geocoding Error: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateOriginFromMarker(LatLng pos) async {
      state = state.copyWith(isLoading: true);
      final address = await _googleMapsService.getAddressFromCoordinates(pos);
      state = state.copyWith(
          originLocation: pos,
          originAddress: address ?? '${pos.latitude}, ${pos.longitude}',
          isLoading: false
      );
      if (state.destinationLocation != null) _calculateRoute();
  }

  Future<void> updateDestinationFromMarker(LatLng pos) async {
      state = state.copyWith(isLoading: true);
      final address = await _googleMapsService.getAddressFromCoordinates(pos);
      state = state.copyWith(
          destinationLocation: pos,
          destinationAddress: address ?? '${pos.latitude}, ${pos.longitude}',
          isLoading: false
      );
      if (state.originLocation != null) _calculateRoute();
  }

  Future<void> _calculateRoute() async {
      if (state.originLocation == null || state.destinationLocation == null) return;
      
      state = state.copyWith(isLoading: true);
      final routeStart = state.originLocation!;
      final routeEnd = state.destinationLocation!;
      
      // Check again to be safe due to async nature
      if (routeStart != state.originLocation || routeEnd != state.destinationLocation) return;
      
      final routeInfo = await _googleMapsService.getRouteCoordinates(routeStart, routeEnd);
      
      double price = 0.0;
      if (routeInfo?['distance_value'] != null && routeInfo?['duration_value'] != null) {
          double distKm = (routeInfo!['distance_value'] as int) / 1000.0;
          double durMin = (routeInfo!['duration_value'] as int) / 60.0;
          price = 35.0 + (distKm * 10.0) + (durMin * 2.0);
          // Round to 2 decimal places
          price = double.parse(price.toStringAsFixed(2));
      }

      print('Route Calculated: $routeInfo, Price: $price'); // DEBUG LOG
      state = state.copyWith(routeInfo: routeInfo, estimatedFare: price, isLoading: false);
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
        isOriginFocused: false, // Move focus away
        isOriginInputVisible: false, 
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
        'origin_address': state.originAddress,
        'dest_address': state.destinationAddress,
        'fare': state.estimatedFare, 
        'distance_meters': state.routeInfo?['distance_value'],
        'duration_seconds': state.routeInfo?['duration_value'],
        'scheduled_at': state.scheduledTime?.toUtc().toIso8601String(),
      };
      
      print('Creating Trip with Payload: $data'); // DEBUG LOG
      
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

  Future<void> fetchMyTrips() async {
    print('### STARTING FETCH MY TRIPS ###'); // DEBUG ENTRY
    state = state.copyWith(isLoading: true, errorMessage: null); // Clear previous error
    try {
      final response = await _dio.get('/trips/mine');
      print('FetchTrips Response: ${response.statusCode} - ${response.data}'); // DEBUG
      if (response.statusCode == 200 && response.data['data'] != null) {
          final List<dynamic> trips = response.data['data'];
          print('Parsed Trips count: ${trips.length}'); // DEBUG
          state = state.copyWith(myTrips: trips, isLoading: false);
      } else {
          print('No trips found or null data'); // DEBUG
          state = state.copyWith(myTrips: [], isLoading: false);
      }
    } catch (e) {
      print('Error fetching trips: $e');
      state = state.copyWith(isLoading: false, errorMessage: 'Error: $e');
    }
  }

  Future<bool> cancelTrip(int tripId) async {
      state = state.copyWith(isLoading: true);
      try {
          final response = await _dio.put('/trips/$tripId/cancel', data: {'reason': 'User cancelled'});
          if (response.statusCode == 200) {
              await fetchMyTrips(); // Refresh list
              return true;
          }
          return false;
      } catch (e) {
          print('Error cancelling trip: $e');
          state = state.copyWith(isLoading: false, errorMessage: 'Error cancelling: $e');
          return false;
      }
  }
  
  // Method to manually clear or reset state
  void reset() {
       state = TaxiRequestState(
          sessionToken: _uuid.v4(),
          scheduledTime: null,
       );
  }

  void setScheduledTime(DateTime? date) {
      state = state.copyWith(scheduledTime: date);
  }

  void setManualSelectionMode(bool enabled) {
    state = state.copyWith(isManualSelectionMode: enabled, predictions: []);
  }
}

final taxiRequestProvider = StateNotifierProvider<TaxiRequestNotifier, TaxiRequestState>((ref) {
  final botService = ref.watch(googleMapsServiceProvider);
  final dio = ref.watch(dioProvider);
  final places = ref.watch(flutterGooglePlacesSdkProvider);
  return TaxiRequestNotifier(botService, dio, places);
});
