import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationProvider extends ChangeNotifier {
  Position? _pos;
  StreamSubscription<Position>? _sub;
  bool _tracking = false;
  String? _error;

  Position? get position   => _pos;
  String?   get error      => _error;
  bool      get isTracking => _tracking;

  /// {lat, lng} or null
  Map<String, double>? get coords => _pos == null
      ? null
      : {'lat': _pos!.latitude, 'lng': _pos!.longitude};

  Future<bool> _ensurePermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }

  Future<void> fetchOnce() async {
    if (!await _ensurePermission()) {
      _error = 'Location permission denied'; notifyListeners(); return;
    }
    try {
      _pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      notifyListeners();
    } catch (e) {
      _error = 'Could not get location'; notifyListeners();
    }
  }

  void startTracking() {
    if (_tracking) return;
    _tracking = true;
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((p) { _pos = p; notifyListeners(); });
  }

  void stopTracking() {
    _sub?.cancel(); _tracking = false; notifyListeners();
  }

  double distanceTo(double lat, double lng) {
    if (_pos == null) return 0;
    return Geolocator.distanceBetween(_pos!.latitude, _pos!.longitude, lat, lng);
  }

  @override
  void dispose() { stopTracking(); super.dispose(); }
}