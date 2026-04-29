import 'package:latlong2/latlong.dart';
import '../models/journey_model.dart';
import '../models/journey_leg.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PUNE METRO TOPOLOGY — Rule-Based Model
// ═══════════════════════════════════════════════════════════════════════════════
//
// LINE 1 — Purple Line (North↔South): PCMC → Swargate
//   PCMC, Sant Tukaram Nagar, Bhosari, Kasarwadi, Phugewadi, Dapodi,
//   Bopodi, Khadki, Range Hill, Shivajinagar, Civil Court, Mandai, Swargate
//
// LINE 2 — Aqua Line (West↔East): Vanaz → Ramwadi
//   Vanaz, Anand Nagar, Ideal Colony, Nal Stop, Garware College,
//   Deccan Gymkhana, Sambhaji Udyan, Civil Court, Pune Railway Station,
//   Ruby Hall Clinic, Bund Garden, Yerawada, Kalyani Nagar, Ramwadi
//
// INTERCHANGE: Civil Court (connects both lines)
//
// RULES — Metro is suggested ONLY when ALL of these are true:
//   1. Nearest board station ≠ nearest alight station (different stations)
//   2. Board & alight stations are connected on the network
//   3. Metro leg covers ≥ MIN_METRO_USEFUL_KM (avoids silly same-station rides)
//   4. Origin is within MAX_WALK_TO_METRO_KM of any metro station
// ═══════════════════════════════════════════════════════════════════════════════

enum MetroLine { line1Purple, line2Aqua, interchange }

class _MetroStation {
  final String name;
  final double lat;
  final double lng;
  final MetroLine line;

  const _MetroStation({
    required this.name,
    required this.lat,
    required this.lng,
    required this.line,
  });

  LatLng get latLng => LatLng(lat, lng);
}

class _MetroPair {
  final _MetroStation board;
  final _MetroStation alight;
  final bool viaInterchange;
  final _MetroStation? interchange;

  _MetroPair({
    required this.board,
    required this.alight,
    required this.viaInterchange,
    this.interchange,
  });
}

class MultimodalRouteService {
  static const double _walkSpeedKmh  = 4.5;
  static const double _busSpeedKmh   = 20.0;
  static const double _metroSpeedKmh = 35.0;
  static const double _cabSpeedKmh   = 25.0;

  /// Metro is only worth including if the metro leg itself covers this much
  static const double _minMetroUsefulKm   = 1.5;

  /// Do not suggest metro if origin is farther than this from any station
  static const double _maxWalkToMetroKm   = 3.0;

  // Pricing
  static const double _cabBase       = 17.0;
  static const double _cabPerKm      = 11.65;
  static const double _cabMinKm      = 1.5;
  static const double _metroPerTwoKm = 10.0;
  static const double _busPerTwoKm   = 8.0;

  // ─── Real Pune Metro Network ─────────────────────────────────────────────────

  static const List<_MetroStation> _network = [
    // LINE 1 — Purple Line
    _MetroStation(name: 'PCMC',                 lat: 18.6298, lng: 73.7997, line: MetroLine.line1Purple),
    _MetroStation(name: 'Sant Tukaram Nagar',   lat: 18.6166, lng: 73.8037, line: MetroLine.line1Purple),
    _MetroStation(name: 'Bhosari',              lat: 18.6040, lng: 73.8075, line: MetroLine.line1Purple),
    _MetroStation(name: 'Kasarwadi',            lat: 18.5933, lng: 73.8095, line: MetroLine.line1Purple),
    _MetroStation(name: 'Phugewadi',            lat: 18.5805, lng: 73.8130, line: MetroLine.line1Purple),
    _MetroStation(name: 'Dapodi',               lat: 18.5700, lng: 73.8157, line: MetroLine.line1Purple),
    _MetroStation(name: 'Bopodi',               lat: 18.5610, lng: 73.8175, line: MetroLine.line1Purple),
    _MetroStation(name: 'Khadki',               lat: 18.5520, lng: 73.8200, line: MetroLine.line1Purple),
    _MetroStation(name: 'Range Hill',           lat: 18.5450, lng: 73.8235, line: MetroLine.line1Purple),
    _MetroStation(name: 'Shivajinagar',         lat: 18.5308, lng: 73.8470, line: MetroLine.line1Purple),
    _MetroStation(name: 'Mandai',               lat: 18.5135, lng: 73.8558, line: MetroLine.line1Purple),
    _MetroStation(name: 'Swargate',             lat: 18.5010, lng: 73.8630, line: MetroLine.line1Purple),

    // INTERCHANGE
    _MetroStation(name: 'Civil Court',          lat: 18.5203, lng: 73.8567, line: MetroLine.interchange),

    // LINE 2 — Aqua Line
    _MetroStation(name: 'Vanaz',                lat: 18.5074, lng: 73.8077, line: MetroLine.line2Aqua),
    _MetroStation(name: 'Anand Nagar',          lat: 18.5088, lng: 73.8000, line: MetroLine.line2Aqua),
    _MetroStation(name: 'Ideal Colony',         lat: 18.5105, lng: 73.8120, line: MetroLine.line2Aqua),
    _MetroStation(name: 'Nal Stop',             lat: 18.5125, lng: 73.8225, line: MetroLine.line2Aqua),
    _MetroStation(name: 'Garware College',      lat: 18.5155, lng: 73.8350, line: MetroLine.line2Aqua),
    _MetroStation(name: 'Deccan Gymkhana',      lat: 18.5180, lng: 73.8400, line: MetroLine.line2Aqua),
    _MetroStation(name: 'Sambhaji Udyan',       lat: 18.5195, lng: 73.8455, line: MetroLine.line2Aqua),
    _MetroStation(name: 'Pune Railway Station', lat: 18.5286, lng: 73.8740, line: MetroLine.line2Aqua),
    _MetroStation(name: 'Ruby Hall Clinic',     lat: 18.5315, lng: 73.8770, line: MetroLine.line2Aqua),
    _MetroStation(name: 'Bund Garden',          lat: 18.5365, lng: 73.8845, line: MetroLine.line2Aqua),
    _MetroStation(name: 'Yerawada',             lat: 18.5510, lng: 73.8870, line: MetroLine.line2Aqua),
    _MetroStation(name: 'Kalyani Nagar',        lat: 18.5485, lng: 73.9020, line: MetroLine.line2Aqua),
    _MetroStation(name: 'Ramwadi',              lat: 18.5620, lng: 73.9120, line: MetroLine.line2Aqua),
  ];

  static const _MetroStation _civilCourt = _MetroStation(
    name: 'Civil Court', lat: 18.5203, lng: 73.8567, line: MetroLine.interchange,
  );

  // Legacy list kept for map_screen.dart marker rendering
  final List<Map<String, dynamic>> metroStations;
  MultimodalRouteService({required this.metroStations});

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  double _distKm(LatLng a, LatLng b) => const Distance()(a, b) / 1000;

  double _walkTime(double km)  => (km / _walkSpeedKmh) * 60;
  double _busTime(double km)   => (km / _busSpeedKmh) * 60;
  double _metroTime(double km) => (km / _metroSpeedKmh) * 60 + 3;
  double _cabTime(double km)   => (km / _cabSpeedKmh) * 60;

  double _cabCost(double km) =>
      km <= _cabMinKm ? _cabBase : _cabBase + (km - _cabMinKm) * _cabPerKm;

  double _metroCost(double km) => ((km / 2).ceil()) * _metroPerTwoKm;
  double _busCost(double km)   => ((km / 2).ceil()) * _busPerTwoKm;

  _MetroStation _nearest(LatLng loc) {
    _MetroStation best = _network[0];
    double minD = double.infinity;
    for (final s in _network) {
      final d = _distKm(loc, s.latLng);
      if (d < minD) { minD = d; best = s; }
    }
    return best;
  }

  // ─── Core rule: is metro genuinely useful? ───────────────────────────────────

  bool _isMetroUseful(LatLng origin, LatLng destination) {
    final board  = _nearest(origin);
    final alight = _nearest(destination);

    // Rule 1 — must board and alight at DIFFERENT stations
    if (board.name == alight.name) return false;

    // Rule 2 — stations must be on a connected line
    if (!_connected(board, alight)) return false;

    // Rule 3 — metro leg must cover meaningful distance
    final metroKm = _distKm(board.latLng, alight.latLng);
    if (metroKm < _minMetroUsefulKm) return false;

    // Rule 4 — origin must be accessible to a metro station
    if (_distKm(origin, board.latLng) > _maxWalkToMetroKm) return false;

    return true;
  }

  /// All Pune metro stations are reachable from each other because
  /// Civil Court interchange connects Line 1 (Purple) and Line 2 (Aqua).
  /// Routing logic automatically inserts an interchange leg when lines differ.
  bool _connected(_MetroStation a, _MetroStation b) {
    return true; // Civil Court links both lines — all stations are reachable
  }

  /// Build the best board/alight pair, routing via Civil Court for cross-line trips
  _MetroPair _bestPair(LatLng origin, LatLng destination) {
    final board  = _nearest(origin);
    final alight = _nearest(destination);

    // Same line or one is interchange → direct
    if (board.line == alight.line ||
        board.line == MetroLine.interchange ||
        alight.line == MetroLine.interchange) {
      return _MetroPair(board: board, alight: alight, viaInterchange: false);
    }

    // Cross-line → via Civil Court
    return _MetroPair(board: board, alight: alight, viaInterchange: true, interchange: _civilCourt);
  }

  // ─── Route builders ──────────────────────────────────────────────────────────

  JourneyModel _busMetro({
    required LatLng origin, required LatLng destination,
    required String originName, required String destName,
  }) {
    final pair   = _bestPair(origin, destination);
    final legs   = <JourneyLeg>[];

    // Leg 1: Bus → board station
    final busKm = _distKm(origin, pair.board.latLng);
    legs.add(JourneyLeg(
      mode: TransportMode.bus,
      fromName: originName,
      toName: '${pair.board.name} Metro Station',
      fromLatLng: origin, toLatLng: pair.board.latLng,
      distanceKm: busKm, durationMin: _busTime(busKm),
      cost: _busCost(busKm),
      instruction: 'Take PMPML bus from $originName to ${pair.board.name} Metro Station',
    ));

    // Metro leg(s)
    _addMetroLegs(legs, pair);

    // Final: Walk → destination
    final walkKm = _distKm(pair.alight.latLng, destination);
    legs.add(JourneyLeg(
      mode: TransportMode.walk,
      fromName: pair.alight.name, toName: destName,
      fromLatLng: pair.alight.latLng, toLatLng: destination,
      distanceKm: walkKm, durationMin: _walkTime(walkKm), cost: 0,
      instruction: 'Walk ${(walkKm * 1000).toStringAsFixed(0)} m to $destName',
    ));

    return JourneyModel(
      type: JourneyType.busMetro, title: 'Bus + Metro', legs: legs,
      totalCost:        legs.fold(0.0, (s, l) => s + l.cost),
      totalDurationMin: legs.fold(0.0, (s, l) => s + l.durationMin),
      totalDistanceKm:  legs.fold(0.0, (s, l) => s + l.distanceKm),
      summary: pair.viaInterchange
          ? 'Bus to metro, interchange at Civil Court, then walk.'
          : 'Bus to metro, then walk. Economical & eco-friendly.',
    );
  }

  JourneyModel _cabMetro({
    required LatLng origin, required LatLng destination,
    required String originName, required String destName,
  }) {
    final pair = _bestPair(origin, destination);
    final legs = <JourneyLeg>[];

    // Leg 1: Cab → board station
    final cabKm = _distKm(origin, pair.board.latLng);
    legs.add(JourneyLeg(
      mode: TransportMode.cab,
      fromName: originName, toName: '${pair.board.name} Metro Station',
      fromLatLng: origin, toLatLng: pair.board.latLng,
      distanceKm: cabKm, durationMin: _cabTime(cabKm),
      cost: _cabCost(cabKm),
      instruction: 'Take Ola/Uber from $originName to ${pair.board.name} Metro Station',
    ));

    _addMetroLegs(legs, pair);

    // Final: Walk → destination
    final walkKm = _distKm(pair.alight.latLng, destination);
    legs.add(JourneyLeg(
      mode: TransportMode.walk,
      fromName: pair.alight.name, toName: destName,
      fromLatLng: pair.alight.latLng, toLatLng: destination,
      distanceKm: walkKm, durationMin: _walkTime(walkKm), cost: 0,
      instruction: 'Walk ${(walkKm * 1000).toStringAsFixed(0)} m to $destName',
    ));

    return JourneyModel(
      type: JourneyType.cabMetro, title: 'Cab + Metro', legs: legs,
      totalCost:        legs.fold(0.0, (s, l) => s + l.cost),
      totalDurationMin: legs.fold(0.0, (s, l) => s + l.durationMin),
      totalDistanceKm:  legs.fold(0.0, (s, l) => s + l.distanceKm),
      summary: pair.viaInterchange
          ? 'Cab to metro, interchange at Civil Court, walk the last stretch.'
          : 'Fastest combo. Cab to metro, walk the last stretch.',
    );
  }

  /// Shared helper — appends metro legs (direct or via Civil Court interchange)
  void _addMetroLegs(List<JourneyLeg> legs, _MetroPair pair) {
    if (pair.viaInterchange && pair.interchange != null) {
      final km1 = _distKm(pair.board.latLng, pair.interchange!.latLng);
      legs.add(JourneyLeg(
        mode: TransportMode.metro,
        fromName: pair.board.name, toName: 'Civil Court (Interchange)',
        fromLatLng: pair.board.latLng, toLatLng: pair.interchange!.latLng,
        distanceKm: km1, durationMin: _metroTime(km1), cost: _metroCost(km1),
        instruction: 'Board metro at ${pair.board.name} → alight at Civil Court for line change',
      ));
      final km2 = _distKm(pair.interchange!.latLng, pair.alight.latLng);
      legs.add(JourneyLeg(
        mode: TransportMode.metro,
        fromName: 'Civil Court', toName: pair.alight.name,
        fromLatLng: pair.interchange!.latLng, toLatLng: pair.alight.latLng,
        distanceKm: km2, durationMin: _metroTime(km2), cost: _metroCost(km2),
        instruction: 'Change line at Civil Court → alight at ${pair.alight.name}',
      ));
    } else {
      final km = _distKm(pair.board.latLng, pair.alight.latLng);
      legs.add(JourneyLeg(
        mode: TransportMode.metro,
        fromName: pair.board.name, toName: pair.alight.name,
        fromLatLng: pair.board.latLng, toLatLng: pair.alight.latLng,
        distanceKm: km, durationMin: _metroTime(km), cost: _metroCost(km),
        instruction: 'Board metro at ${pair.board.name} → alight at ${pair.alight.name}',
      ));
    }
  }

  JourneyModel _directCab({
    required LatLng origin, required LatLng destination,
    required String originName, required String destName,
    required double distanceKm, required double durationMin,
  }) {
    final leg = JourneyLeg(
      mode: TransportMode.cab, fromName: originName, toName: destName,
      fromLatLng: origin, toLatLng: destination,
      distanceKm: distanceKm, durationMin: durationMin,
      cost: _cabCost(distanceKm),
      instruction: 'Take Ola/Uber directly from $originName to $destName',
    );
    return JourneyModel(
      type: JourneyType.directCab, title: 'Cab Only', legs: [leg],
      totalCost: leg.cost, totalDurationMin: leg.durationMin,
      totalDistanceKm: leg.distanceKm, summary: 'Door-to-door comfort. Most convenient.',
    );
  }

  JourneyModel _directBus({
    required LatLng origin, required LatLng destination,
    required String originName, required String destName,
    required double distanceKm, required double durationMin,
  }) {
    final leg = JourneyLeg(
      mode: TransportMode.bus, fromName: originName, toName: destName,
      fromLatLng: origin, toLatLng: destination,
      distanceKm: distanceKm, durationMin: durationMin * 1.3,
      cost: _busCost(distanceKm),
      instruction: 'Take PMPML bus directly from $originName to $destName',
    );
    return JourneyModel(
      type: JourneyType.directBus, title: 'Bus Only', legs: [leg],
      totalCost: leg.cost, totalDurationMin: leg.durationMin,
      totalDistanceKm: leg.distanceKm, summary: 'Cheapest option. Best for budget travellers.',
    );
  }

  // ─── Public API ───────────────────────────────────────────────────────────────

  /// Returns only VALID routes. Metro routes appear ONLY when metro
  /// genuinely helps (different board/alight station, connected line,
  /// meaningful distance, accessible from origin).
  List<JourneyModel> generateAllRoutes({
    required LatLng origin,
    required LatLng destination,
    required String originName,
    required String destName,
    required double distanceKm,
    required double durationMin,
  }) {
    final routes = <JourneyModel>[];

    // Always available
    routes.add(_directBus(
      origin: origin, destination: destination,
      originName: originName, destName: destName,
      distanceKm: distanceKm, durationMin: durationMin,
    ));
    routes.add(_directCab(
      origin: origin, destination: destination,
      originName: originName, destName: destName,
      distanceKm: distanceKm, durationMin: durationMin,
    ));

    // Metro only when it genuinely helps
    if (_isMetroUseful(origin, destination)) {
      routes.add(_busMetro(
        origin: origin, destination: destination,
        originName: originName, destName: destName,
      ));
      routes.add(_cabMetro(
        origin: origin, destination: destination,
        originName: originName, destName: destName,
      ));
    }

    routes.sort((a, b) => a.totalCost.compareTo(b.totalCost));
    return routes;
  }
}