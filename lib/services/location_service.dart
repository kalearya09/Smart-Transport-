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

  /// Request location permissions and return true if granted.
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('LocationService: Location services disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('LocationService: Permission denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('LocationService: Permission permanently denied.');
      return false;
    }

    return true;
  }

  /// Get the current one-shot position.
  Future<LatLng?> getCurrentLocation() async {
    final granted = await requestPermission();
    if (!granted) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final loc = LatLng(position.latitude, position.longitude);
      _lastKnownLocation = loc;
      return loc;
    } catch (e) {
      debugPrint('LocationService: getCurrentLocation error: $e');
      return null;
    }
  }

  /// Start streaming live location updates every 5 seconds.
  Future<void> startTracking() async {
    final granted = await requestPermission();
    if (!granted) return;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // metres
    );

    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      (Position position) {
        final loc = LatLng(position.latitude, position.longitude);
        _lastKnownLocation = loc;
        _locationController.add(loc);
      },
      onError: (e) => debugPrint('LocationService: stream error: $e'),
    );
  }

  /// Stop live tracking.
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
