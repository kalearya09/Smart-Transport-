import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/journey_model.dart';
import '../models/journey_leg.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../widgets/journey_step_card.dart';

class JourneyDetailsScreen extends StatefulWidget {
  final JourneyModel journey;
  final String accessToken;

  const JourneyDetailsScreen({
    super.key,
    required this.journey,
    required this.accessToken,
  });

  @override
  State<JourneyDetailsScreen> createState() => _JourneyDetailsScreenState();
}

class _JourneyDetailsScreenState extends State<JourneyDetailsScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  LatLng? _liveLocation;
  StreamSubscription<LatLng>? _locationSub;
  bool _locationPermitted = false;
  bool _isLoadingLegRoutes = false;
  final Map<int, List<LatLng>> _legRoutePoints = {};

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadLegRoutes();
  }

  Future<void> _initLocation() async {
    final granted = await _locationService.requestPermission();
    if (!mounted) return;
    setState(() => _locationPermitted = granted);
    if (!granted) return;

    final current = await _locationService.getCurrentLocation();
    if (current != null && mounted) {
      setState(() => _liveLocation = current);
    }

    await _locationService.startTracking();
    _locationSub = _locationService.locationStream.listen((loc) {
      if (mounted) setState(() => _liveLocation = loc);
    });
  }

  Future<void> _loadLegRoutes() async {
    setState(() => _isLoadingLegRoutes = true);

    final routeService = RouteService(accessToken: widget.accessToken);
    final fetchedRoutes = <int, List<LatLng>>{};

    for (var i = 0; i < widget.journey.legs.length; i++) {
      final leg = widget.journey.legs[i];
      final profile = _profileForMode(leg.mode);

      if (profile == null) {
        fetchedRoutes[i] = [leg.fromLatLng, leg.toLatLng];
        continue;
      }

      final points = await routeService.getRouteCoordinates(
        origin: leg.fromLatLng,
        destination: leg.toLatLng,
        profile: profile,
      );

      fetchedRoutes[i] = points.length >= 2
          ? points
          : [leg.fromLatLng, leg.toLatLng];
    }

    if (!mounted) return;
    setState(() {
      _legRoutePoints
        ..clear()
        ..addAll(fetchedRoutes);
      _isLoadingLegRoutes = false;
    });
  }

  String? _profileForMode(TransportMode mode) {
    switch (mode) {
      case TransportMode.walk:
        return 'walking';
      case TransportMode.bus:
      case TransportMode.cab:
        return 'driving';
      case TransportMode.metro:
        return null;
    }
  }

  void _centerOnLiveLocation() {
    if (_liveLocation != null) {
      _mapController.move(_liveLocation!, 15);
    }
  }

  // Build polyline points from all leg waypoints
  List<LatLng> get _allRoutePoints {
    final pts = <LatLng>[];
    for (final leg in widget.journey.legs) {
      pts.add(leg.fromLatLng);
      pts.add(leg.toLatLng);
    }
    return pts;
  }

  // Centre of the route
  LatLng get _routeCenter {
    final pts = _allRoutePoints;
    if (pts.isEmpty) return const LatLng(18.5204, 73.8567);
    final lat = pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final lng = pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;
    return LatLng(lat, lng);
  }

  Color _legColor(TransportMode mode) {
    switch (mode) {
      case TransportMode.walk:
        return Colors.teal;
      case TransportMode.bus:
        return Colors.green;
      case TransportMode.metro:
        return Colors.blue;
      case TransportMode.cab:
        return Colors.orange;
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _locationService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journey = widget.journey;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(journey.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[200]),
        ),
      ),
      body: Column(
        children: [
          // ── Summary banner ─────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryItem(
                  Icons.currency_rupee,
                  '₹${journey.totalCost.toStringAsFixed(0)}',
                  'Total Cost',
                  Colors.green,
                ),
                _divider(),
                _summaryItem(
                  Icons.schedule,
                  '${journey.totalDurationMin.toStringAsFixed(0)} min',
                  'Duration',
                  Colors.blue,
                ),
                _divider(),
                _summaryItem(
                  Icons.straighten,
                  '${journey.totalDistanceKm.toStringAsFixed(1)} km',
                  'Distance',
                  Colors.orange,
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Map ──────────────────────────────────────────────────
                  SizedBox(
                    height: 240,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _routeCenter,
                            initialZoom: 12,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://api.mapbox.com/styles/v1/mapbox/navigation-day-v1/tiles/{z}/{x}/{y}?access_token=${widget.accessToken}',
                            ),

                            // Per-leg polylines with mode colours
                            PolylineLayer(
                              polylines: widget.journey.legs.asMap().entries.map((entry) {
                                final index = entry.key;
                                final leg = entry.value;
                                return Polyline(
                                  points: _legRoutePoints[index] ??
                                      [leg.fromLatLng, leg.toLatLng],
                                  color: _legColor(leg.mode),
                                  strokeWidth: 5,
                                  isDotted: leg.mode == TransportMode.walk,
                                );
                              }).toList(),
                            ),

                            // Waypoint markers
                            MarkerLayer(
                              markers: [
                                // Origin
                                Marker(
                                  point: widget.journey.legs.first.fromLatLng,
                                  width: 32,
                                  height: 32,
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.green,
                                    child: Icon(Icons.my_location,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                                // Destination
                                Marker(
                                  point: widget.journey.legs.last.toLatLng,
                                  width: 32,
                                  height: 32,
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.location_on,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                                // Live location (blue dot)
                                if (_liveLocation != null)
                                  Marker(
                                    point: _liveLocation!,
                                    width: 24,
                                    height: 24,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 3,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        if (_isLoadingLegRoutes)
                          const Positioned(
                            top: 12,
                            right: 12,
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),

                        // Live location button
                        if (_locationPermitted)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: FloatingActionButton.small(
                              heroTag: 'live_loc_detail',
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              onPressed: _centerOnLiveLocation,
                              child: const Icon(Icons.my_location),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Route summary ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      journey.summary,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  // ── Step-by-step ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      'Step-by-Step Route',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        for (int i = 0; i < journey.legs.length; i++)
                          JourneyStepCard(
                            leg: journey.legs[i],
                            stepNumber: i + 1,
                            isLast: i == journey.legs.length - 1,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Cost breakdown ──────────────────────────────────────
                  _costBreakdownCard(journey),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _divider() =>
      Container(height: 36, width: 1, color: Colors.grey[200]);

  Widget _costBreakdownCard(JourneyModel journey) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cost Breakdown',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          ...journey.legs.where((l) => l.cost > 0).map(
                (leg) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text('${leg.modeEmoji} ${leg.modeLabel}',
                          style: const TextStyle(fontSize: 13)),
                      const Spacer(),
                      Text('₹${leg.cost.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ),
          const Divider(),
          Row(
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(
                '₹${journey.totalCost.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
