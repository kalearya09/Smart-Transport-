import 'journey_leg.dart';

enum JourneyType { busMetro, cabMetro, directBus, directCab, directMetro }

class JourneyModel {
  final JourneyType type;
  final String title;
  final List<JourneyLeg> legs;
  final double totalCost;
  final double totalDurationMin;
  final double totalDistanceKm;
  final String summary;

  const JourneyModel({
    required this.type,
    required this.title,
    required this.legs,
    required this.totalCost,
    required this.totalDurationMin,
    required this.totalDistanceKm,
    required this.summary,
  });

  String get typeLabel {
    switch (type) {
      case JourneyType.busMetro:
        return 'Bus + Metro';
      case JourneyType.cabMetro:
        return 'Cab + Metro';
      case JourneyType.directBus:
        return 'Bus Only';
      case JourneyType.directCab:
        return 'Cab Only';
      case JourneyType.directMetro:
        return 'Metro Only';
    }
  }

  String get typeEmoji {
    switch (type) {
      case JourneyType.busMetro:
        return '🚌🚇';
      case JourneyType.cabMetro:
        return '🚕🚇';
      case JourneyType.directBus:
        return '🚌';
      case JourneyType.directCab:
        return '🚕';
      case JourneyType.directMetro:
        return '🚇';
    }
  }
}
