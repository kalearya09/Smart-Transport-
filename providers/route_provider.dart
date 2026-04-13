import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/models.dart';
import '../core/constants/app_constants.dart';

enum PlanStatus { idle, loading, loaded, error }

class RouteProvider extends ChangeNotifier {
  final _dio = Dio();

  List<RouteModel>  _routes   = [];
  RouteModel?       _selected;
  PlanStatus        _status   = PlanStatus.idle;
  String?           _error;

  List<double>? _originCoords;  // [lng, lat]
  List<double>? _destCoords;    // [lng, lat]
  String _originName = '';
  String _destName   = '';

  // Decoded GeoJSON coords of selected route for drawing
  List<List<double>> _geometry = [];

  List<RouteModel>   get routes    => _routes;
  RouteModel?        get selected  => _selected;
  PlanStatus         get status    => _status;
  String?            get error     => _error;
  List<double>?      get originCoords => _originCoords;
  List<double>?      get destCoords   => _destCoords;
  String             get originName   => _originName;
  String             get destName     => _destName;
  List<List<double>> get geometry     => _geometry;

  // ── Set origin / destination ───────────────────────────────────
  void setOrigin(double lat, double lng, String name) {
    _originCoords = [lng, lat];
    _originName   = name;
    notifyListeners();
  }

  void setDestination(double lat, double lng, String name) {
    _destCoords = [lng, lat];
    _destName   = name;
    notifyListeners();
  }

  // ── Mapbox Geocoding ───────────────────────────────────────────
  Future<List<GeocodingResult>> geocode(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final url =
          '${AppConstants.mapboxGeocodingBase}/${Uri.encodeComponent(query)}.json'
          '?access_token=${AppConstants.mapboxPublicToken}'
          '&autocomplete=true&limit=5&types=place,address,poi';
      final res = await _dio.get(url);
      final features = res.data['features'] as List;
      return features.map((f) {
        final c = f['geometry']['coordinates'] as List;
        return GeocodingResult(
          name: f['place_name'] ?? '',
          lng: (c[0] as num).toDouble(),
          lat: (c[1] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Geocode error: $e');
      return [];
    }
  }

  // ── Mapbox Directions ──────────────────────────────────────────
  Future<void> planRoute() async {
    if (_originCoords == null || _destCoords == null) return;
    _status = PlanStatus.loading; _error = null; notifyListeners();

    try {
      final results = await _callDirections('driving-traffic') +
          await _callDirections('walking');

      if (results.isEmpty) throw Exception('No routes found');

      _routes   = results;
      _selected = results.first;
      _geometry = results.first.polylinePoints;
      _status   = PlanStatus.loaded;
    } catch (e) {
      debugPrint('Directions error: $e');
      // Fallback mock so UI still shows something
      _routes   = _mockRoutes();
      _selected = _routes.first;
      _geometry = _routes.first.polylinePoints;
      _error    = 'Using offline data. Add Mapbox token for live routes.';
      _status   = PlanStatus.loaded;
    }
    notifyListeners();
  }

  Future<List<RouteModel>> _callDirections(String profile) async {
    final coords =
        '${_originCoords![0]},${_originCoords![1]};'
        '${_destCoords![0]},${_destCoords![1]}';
    final url =
        '${AppConstants.mapboxDirectionsBase}/$profile/$coords'
        '?access_token=${AppConstants.mapboxPublicToken}'
        '&alternatives=true&geometries=geojson&steps=true&overview=full';

    final res  = await _dio.get(url);
    final data = res.data;
    if (data['code'] != 'Ok') return [];

    final List rawRoutes = data['routes'];
    final List<RouteModel> out = [];

    for (int i = 0; i < rawRoutes.length; i++) {
      final r    = rawRoutes[i];
      final geo  = r['geometry']['coordinates'] as List;
      final pts  = geo.map<List<double>>(
              (c) => [(c[0] as num).toDouble(), (c[1] as num).toDouble()]).toList();
      final leg  = (r['legs'] as List).first;
      final steps = leg['steps'] as List;

      final stops = <RouteStop>[];
      int cum = 0;
      for (int s = 0; s < steps.length; s++) {
        final step = steps[s];
        final loc  = step['maneuver']['location'] as List;
        cum += ((step['duration'] as num) / 60).round();
        stops.add(RouteStop(
          id: '${profile}_${i}_$s',
          name: (step['name'] as String).isEmpty ? 'Step ${s + 1}' : step['name'],
          lat: (loc[1] as num).toDouble(),
          lng: (loc[0] as num).toDouble(),
          etaMinutes: cum,
          isTerminus: s == 0 || s == steps.length - 1,
        ));
      }

      String type;
      String name;
      if (profile == 'walking') {
        type = 'walking'; name = 'Walking Route';
      } else {
        type = i == 0 ? 'fastest' : 'alternate';
        name = i == 0 ? 'Fastest Drive' : 'Alternate Drive';
      }

      out.add(RouteModel(
        id: '${profile}_$i',
        name: name, number: '${out.length + 1}',
        stops: stops,
        durationMinutes: ((r['duration'] as num) / 60).round(),
        distanceKm: ((r['distance'] as num) / 1000),
        type: type, polylinePoints: pts,
      ));
    }
    return out;
  }

  void selectRoute(RouteModel r) {
    _selected = r;
    _geometry = r.polylinePoints;
    notifyListeners();
  }

  void clear() {
    _routes = []; _selected = null; _originCoords = null;
    _destCoords = null; _originName = ''; _destName = '';
    _geometry = []; _status = PlanStatus.idle; _error = null;
    notifyListeners();
  }

  // ── Mock fallback ──────────────────────────────────────────────
  List<RouteModel> _mockRoutes() {
    final oLng = _originCoords![0]; final oLat = _originCoords![1];
    final dLng = _destCoords![0];  final dLat = _destCoords![1];
    return [
      RouteModel(
        id: 'mock_1', name: 'Fastest Route', number: '1',
        stops: [
          RouteStop(id:'s1', name:_originName, lat:oLat, lng:oLng, etaMinutes:0, isTerminus:true),
          RouteStop(id:'s2', name:_destName,   lat:dLat, lng:dLng, etaMinutes:22, isTerminus:true),
        ],
        durationMinutes: 22, distanceKm: 4.2, type: 'fastest',
        polylinePoints: [[oLng,oLat],[oLng+(dLng-oLng)*0.5, oLat+(dLat-oLat)*0.4],[dLng,dLat]],
      ),
      RouteModel(
        id: 'mock_2', name: 'Alternate Route', number: '2',
        stops: [], durationMinutes: 35, distanceKm: 3.8, type: 'alternate',
        polylinePoints: [[oLng,oLat],[dLng,dLat]],
      ),
    ];
  }
}