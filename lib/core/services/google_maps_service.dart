import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:yellow/core/config/app_config.dart';

class GoogleMapsService {
  final Dio _dio;
  final String _apiKey;

  GoogleMapsService(this._dio, this._apiKey);

  static const String _placesBaseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String _directionsBaseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Fetches place predictions using Session Token for cost optimization.
  /// [sessionToken] must be generated using Uuid().v4() and reused until a selection is made.
  Future<List<Map<String, dynamic>>> getPlacePredictions(String query, String sessionToken) async {
    if (query.isEmpty) return [];

    try {
      final response = await _dio.get(
        '$_placesBaseUrl/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': _apiKey,
          'sessiontoken': sessionToken,
          // 'components': 'country:us', // Optional: restrict to country
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(data['predictions']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching place predictions: $e');
      return [];
    }
  }

  /// Fetches place details (LatLng) using Place ID and Session Token.
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId, String sessionToken) async {
    try {
      final response = await _dio.get(
        '$_placesBaseUrl/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'sessiontoken': sessionToken,
          'fields': 'geometry,formatted_address,name', // Only fetch needed fields
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching place details: $e');
      return null;
    }
  }

  /// Calculates route between origin and destination.
  Future<Map<String, dynamic>?> getRouteCoordinates(LatLng origin, LatLng destination) async {
    try {
      final response = await _dio.get(
        _directionsBaseUrl,
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'key': _apiKey,
          'mode': 'driving',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK' && (data['routes'] as List).isNotEmpty) {
           final route = data['routes'][0];
           final legs = route['legs'][0];
           
           return {
             'polyline_points': route['overview_polyline']['points'],
             'distance_text': legs['distance']['text'],
             'distance_value': legs['distance']['value'], // meters
             'duration_text': legs['duration']['text'],
             'duration_value': legs['duration']['value'], // seconds
             'bounds': route['bounds'],
           };
        }
      }
      return null;
    } catch (e) {
      print('Error fetching route: $e');
      return null;
    }
  }
}
