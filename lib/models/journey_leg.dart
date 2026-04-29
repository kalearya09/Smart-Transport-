import 'package:latlong2/latlong.dart';

enum TransportMode { walk, bus, metro, cab }

class JourneyLeg {
  final TransportMode mode;
  final String fromName;
  final String toName;
  final LatLng fromLatLng;
  final LatLng toLatLng;
  final double distanceKm;
  final double durationMin;
  final double cost;
  final String instruction;

  const JourneyLeg({
    required this.mode,
    required this.fromName,
    required this.toName,
    required this.fromLatLng,
    required this.toLatLng,
    required this.distanceKm,
    required this.durationMin,
    required this.cost,
    required this.instruction,
  });

  String get modeLabel {
    switch (mode) {
      case TransportMode.walk:
        return 'Walk';
      case TransportMode.bus:
        return 'Bus';
      case TransportMode.metro:
        return 'Metro';
      case TransportMode.cab:
        return 'Cab';
    }
  }

  String get modeEmoji {
    switch (mode) {
      case TransportMode.walk:
        return '🚶';
      case TransportMode.bus:
        return '🚌';
      case TransportMode.metro:
        return '🚇';
      case TransportMode.cab:
        return '🚕';
    }
  }
}
