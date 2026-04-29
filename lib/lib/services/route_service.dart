import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteService {
  final String accessToken;

  RouteService({required this.accessToken});

  Uri _directionsUri({
    required LatLng origin,
    required LatLng destination,
    String profile = 'driving',
  }) {
    return Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/$profile/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?geometries=geojson'
          '&overview=full'
          '&steps=true'
          '&alternatives=false'
          '&continue_straight=true'
          '&access_token=$accessToken',
    );
  }

  /// 🔥 MAIN FUNCTION (with better validation + debug)
  Future<Map<String, dynamic>?> getRoute({
    required LatLng origin,
    required LatLng destination,
    String profile = 'driving',
  }) async {
    try {
      debugPrint('📡 Fetching route...');
      debugPrint('➡️ Origin: ${origin.latitude}, ${origin.longitude}');
      debugPrint('➡️ Destination: ${destination.latitude}, ${destination.longitude}');

      final response = await http
          .get(_directionsUri(
        origin: origin,
        destination: destination,
        profile: profile,
      ))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('❌ API ERROR ${response.statusCode}');
        debugPrint(response.body);
        return null;
      }

      final data = jsonDecode(response.body);

      if (data['routes'] == null || (data['routes'] as List).isEmpty) {
        debugPrint('❌ No routes found');
        return null;
      }

      final route = data['routes'][0];

      final geometry = route['geometry'];
      if (geometry == null || geometry['coordinates'] == null) {
        debugPrint('❌ No geometry found');
        return null;
      }

      final List coordinates = geometry['coordinates'];

      // 🔥 Convert to LatLng list (IMPORTANT)
      final List<LatLng> routePoints = coordinates.map<LatLng>((coord) {
        return LatLng(coord[1], coord[0]);
      }).toList();

      // 🔥 Smooth route (remove jitter)
      final List<LatLng> smoothPoints = _smoothPolyline(routePoints);

      debugPrint('✅ Route points: ${smoothPoints.length}');

      return {
        'points': smoothPoints,
        'distance': (route['distance'] as num).toDouble() / 1000, // km
        'duration': (route['duration'] as num).toDouble() / 60,   // minutes
      };
    } catch (e) {
      debugPrint('❌ Route error: $e');
      return null;
    }
  }

  /// 🔥 Smoothing algorithm (makes route look professional)
  List<LatLng> _smoothPolyline(List<LatLng> points) {
    if (points.length < 3) return points;

    List<LatLng> smooth = [];
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      smooth.add(p1);

      // interpolate mid point
      final mid = LatLng(
        (p1.latitude + p2.latitude) / 2,
        (p1.longitude + p2.longitude) / 2,
      );

      smooth.add(mid);
    }

    smooth.add(points.last);
    return smooth;
  }

  /// 🛣️ Only route points
  Future<List<LatLng>> getRouteCoordinates({
    required LatLng origin,
    required LatLng destination,
    String profile = 'driving',
  }) async {
    final route = await getRoute(
      origin: origin,
      destination: destination,
      profile: profile,
    );

    return (route?['points'] as List<LatLng>?) ?? [];
  }

  /// 📊 Distance + duration
  Future<Map<String, dynamic>?> getRouteInfo({
    required LatLng origin,
    required LatLng destination,
    String profile = 'driving',
  }) async {
    final route = await getRoute(
      origin: origin,
      destination: destination,
      profile: profile,
    );

    if (route == null) return null;

    return {
      'distance': route['distance'],
      'duration': route['duration'],
    };
  }
}