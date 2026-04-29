import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionSubscription;

  final StreamController<LatLng> _locationController =
  StreamController<LatLng>.broadcast();

  Stream<LatLng> get locationStream => _locationController.stream;

  LatLng? _lastKnownLocation;
  LatLng? get lastKnownLocation => _lastKnownLocation;

  /// 🔐 Request permission + ensure GPS is ON
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      debugPrint('❌ GPS is OFF');
      await Geolocator.openLocationSettings(); // 🔥 auto open settings
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      debugPrint('❌ Permission denied');
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Permission permanently denied');
      await Geolocator.openAppSettings(); // 🔥 open app settings
      return false;
    }

    return true;
  }

  /// 📍 Get accurate current location
  Future<LatLng?> getCurrentLocation() async {
    final granted = await requestPermission();
    if (!granted) return null;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation, // 🔥 better accuracy
      ).timeout(const Duration(seconds: 10));

      final loc = LatLng(position.latitude, position.longitude);
      _lastKnownLocation = loc;

      return loc;
    } catch (e) {
      debugPrint('⚠️ GPS slow, using last known location');
      return await getLastKnownLocation();
    }
  }

  /// 📌 Fallback location
  Future<LatLng?> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();

      if (position != null) {
        final loc = LatLng(position.latitude, position.longitude);
        _lastKnownLocation = loc;
        return loc;
      }
    } catch (e) {
      debugPrint('⚠️ Last known location error: $e');
    }

    return _lastKnownLocation;
  }

  /// 🚗 Live tracking (smooth movement)
  Future<void> startTracking() async {
    final granted = await requestPermission();
    if (!granted) return;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3, // 🔥 smoother updates
    );

    _positionSubscription?.cancel();

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
              (Position position) {
            final loc = LatLng(position.latitude, position.longitude);

            _lastKnownLocation = loc;

            if (!_locationController.isClosed) {
              _locationController.add(loc);
            }
          },
          onError: (e) {
            debugPrint('❌ Location stream error: $e');
          },
        );
  }

  /// ⛔ Stop tracking
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    stopTracking();
    _locationController.close();
  }
}