import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class VehicleProvider extends ChangeNotifier {
  final _rtdb      = FirebaseDatabase.instance;
  final _firestore = FirebaseFirestore.instance;

  List<VehicleModel>  _vehicles = [];
  List<VehicleModel>  _nearby   = [];
  VehicleModel?       _selected;
  DriverModel?        _driver;
  StreamSubscription? _stream;
  bool _loading = false;

  List<VehicleModel> get vehicles => _vehicles;
  List<VehicleModel> get nearby   => _nearby;
  VehicleModel?      get selected => _selected;
  DriverModel?       get driver   => _driver;
  bool               get loading  => _loading;

  void startTracking() {
    _seedMockIfEmpty();
    _stream = _rtdb.ref('vehicle_locations').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final raw = event.snapshot.value as Map<dynamic, dynamic>;
        _vehicles = raw.entries
            .map((e) => VehicleModel.fromMap(e.key.toString(), e.value as Map))
            .toList();
        notifyListeners();
      }
    });
  }

  void _seedMockIfEmpty() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _rtdb.ref('vehicle_locations').get().then((snap) {
      if (!snap.exists) {
        _rtdb.ref('vehicle_locations').set({
          'v001': {'routeNumber':'101','routeName':'Station → City Center',
            'type':'bus','driverId':'d001','lat':18.5204,'lng':73.8567,
            'speed':42.0,'status':'on_time','capacity':50,'currentPassengers':32,'lastUpdated':now},
          'v002': {'routeNumber':'202','routeName':'Airport → Downtown',
            'type':'bus','driverId':'d002','lat':18.5304,'lng':73.8467,
            'speed':28.0,'status':'delayed','capacity':45,'currentPassengers':40,'lastUpdated':now},
          'v003': {'routeNumber':'M1','routeName':'Metro Line 1',
            'type':'metro','driverId':'d003','lat':18.5104,'lng':73.8667,
            'speed':65.0,'status':'on_time','capacity':200,'currentPassengers':120,'lastUpdated':now},
          'v004': {'routeNumber':'305','routeName':'University → Market',
            'type':'bus','driverId':'d004','lat':18.5150,'lng':73.8520,
            'speed':35.0,'status':'on_time','capacity':40,'currentPassengers':18,'lastUpdated':now},
        });
      }
    });
  }

  void filterNearby(double userLat, double userLng, double radiusKm) {
    _nearby = _vehicles.where((v) {
      final d = _haversine(userLat, userLng, v.lat, v.lng);
      return d <= radiusKm;
    }).toList();
    notifyListeners();
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat/2)*sin(dLat/2) +
        cos(_rad(lat1))*cos(_rad(lat2))*sin(dLng/2)*sin(dLng/2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double d) => d * pi / 180;

  Future<void> selectVehicle(VehicleModel v) async {
    _selected = v;
    await _fetchDriver(v.driverId);
    notifyListeners();
  }

  Future<void> _fetchDriver(String id) async {
    _loading = true; notifyListeners();
    try {
      final doc = await _firestore.collection('drivers').doc(id).get();
      if (doc.exists) {
        _driver = DriverModel.fromMap(doc.data()!);
      } else {
        // Mock driver for demo
        _driver = DriverModel(
          id: id, name: 'Rajesh Kumar', phone: '+91 98765 43210',
          licenseNumber: 'MH12-2019-012345',
          photoUrl: 'https://i.pravatar.cc/150?img=12',
          rating: 4.7, totalTrips: 1248,
          vehicleId: _selected?.id ?? '', isOnDuty: true,
        );
      }
    } catch (_) {
      _driver = DriverModel(
        id: id, name: 'Driver', phone: '', licenseNumber: '',
        photoUrl: '', rating: 4.0, totalTrips: 0,
        vehicleId: _selected?.id ?? '', isOnDuty: true,
      );
    }
    _loading = false; notifyListeners();
  }

  void clearSelection() {
    _selected = null; _driver = null; notifyListeners();
  }

  @override
  void dispose() { _stream?.cancel(); super.dispose(); }
}