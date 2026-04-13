import 'package:cloud_firestore/cloud_firestore.dart';

// ── User ─────────────────────────────────────────────────────────
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final List<String> favoriteRoutes;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.favoriteRoutes = const [],
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
    uid: m['uid'] ?? '',
    name: m['name'] ?? '',
    email: m['email'] ?? '',
    phone: m['phone'] ?? '',
    photoUrl: m['photoUrl'],
    favoriteRoutes: List<String>.from(m['favoriteRoutes'] ?? []),
    createdAt: (m['createdAt'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toMap() => {
    'uid': uid, 'name': name, 'email': email,
    'phone': phone, 'photoUrl': photoUrl,
    'favoriteRoutes': favoriteRoutes,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  UserModel copyWith({String? name, String? phone, String? photoUrl, List<String>? favoriteRoutes}) =>
      UserModel(uid: uid, name: name ?? this.name, email: email,
          phone: phone ?? this.phone, photoUrl: photoUrl ?? this.photoUrl,
          favoriteRoutes: favoriteRoutes ?? this.favoriteRoutes, createdAt: createdAt);
}

// ── Vehicle ───────────────────────────────────────────────────────
class VehicleModel {
  final String id;
  final String routeNumber;
  final String routeName;
  final String type;
  final String driverId;
  final double lat;
  final double lng;
  final double speed;
  final String status;
  final int capacity;
  final int currentPassengers;

  VehicleModel({
    required this.id, required this.routeNumber, required this.routeName,
    required this.type, required this.driverId, required this.lat,
    required this.lng, required this.speed, required this.status,
    required this.capacity, required this.currentPassengers,
  });

  factory VehicleModel.fromMap(String id, Map<dynamic, dynamic> m) => VehicleModel(
    id: id,
    routeNumber: m['routeNumber'] ?? '',
    routeName: m['routeName'] ?? '',
    type: m['type'] ?? 'bus',
    driverId: m['driverId'] ?? '',
    lat: (m['lat'] ?? 0.0).toDouble(),
    lng: (m['lng'] ?? 0.0).toDouble(),
    speed: (m['speed'] ?? 0.0).toDouble(),
    status: m['status'] ?? 'on_time',
    capacity: (m['capacity'] ?? 50) as int,
    currentPassengers: (m['currentPassengers'] ?? 0) as int,
  );

  double get occupancy => capacity > 0 ? currentPassengers / capacity : 0;
  bool get isCrowded => occupancy > 0.8;
}

// ── Driver ────────────────────────────────────────────────────────
class DriverModel {
  final String id;
  final String name;
  final String phone;
  final String licenseNumber;
  final String photoUrl;
  final double rating;
  final int totalTrips;
  final String vehicleId;
  final bool isOnDuty;

  DriverModel({
    required this.id, required this.name, required this.phone,
    required this.licenseNumber, required this.photoUrl,
    required this.rating, required this.totalTrips,
    required this.vehicleId, required this.isOnDuty,
  });

  factory DriverModel.fromMap(Map<String, dynamic> m) => DriverModel(
    id: m['id'] ?? '', name: m['name'] ?? '', phone: m['phone'] ?? '',
    licenseNumber: m['licenseNumber'] ?? '', photoUrl: m['photoUrl'] ?? '',
    rating: (m['rating'] ?? 4.0).toDouble(), totalTrips: (m['totalTrips'] ?? 0) as int,
    vehicleId: m['vehicleId'] ?? '', isOnDuty: m['isOnDuty'] ?? false,
  );
}

// ── Route ─────────────────────────────────────────────────────────
class RouteModel {
  final String id;
  final String name;
  final String number;
  final List<RouteStop> stops;
  final int durationMinutes;
  final double distanceKm;
  final String type;
  // GeoJSON [[lng, lat], ...] from Mapbox
  final List<List<double>> polylinePoints;

  RouteModel({
    required this.id, required this.name, required this.number,
    required this.stops, required this.durationMinutes,
    required this.distanceKm, required this.type, required this.polylinePoints,
  });
}

class RouteStop {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int etaMinutes;
  final bool isTerminus;

  RouteStop({
    required this.id, required this.name, required this.lat,
    required this.lng, required this.etaMinutes, required this.isTerminus,
  });
}

// ── Notification ──────────────────────────────────────────────────
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id, required this.title, required this.body,
    required this.type, required this.timestamp, this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id, title: title, body: body, type: type,
    timestamp: timestamp, isRead: isRead ?? this.isRead,
  );
}

// ── Geocoding Result ──────────────────────────────────────────────
class GeocodingResult {
  final String name;
  final double lat;
  final double lng;
  GeocodingResult({required this.name, required this.lat, required this.lng});
}