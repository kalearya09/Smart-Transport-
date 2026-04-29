import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'history_screen.dart';
import 'services/location_service.dart';
import 'services/multimodal_route_service.dart';
import 'models/journey_model.dart';
import 'screens/journey_details_screen.dart';
import 'services/route_service.dart';
import 'services/bus_stop_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();

}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController sourceController = TextEditingController();
  final TextEditingController destController = TextEditingController();
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  Map<String, dynamic>? nearestBusStop;
  double nearestBusDistance = 0;
  void findNearestBusStop() {
    if (_liveLocation == null || busStops.isEmpty) return;

    double minDistance = double.infinity;
    Map<String, dynamic>? nearest;

    for (var stop in busStops) {
      final dist = const Distance().as(
        LengthUnit.Kilometer,
        _liveLocation!,
        LatLng(stop['lat'], stop['lng']),
      );

      if (dist < minDistance) {
        minDistance = dist;
        nearest = stop;
      }
    }

    setState(() {
      nearestBusStop = nearest;
      nearestBusDistance = minDistance;
    });
  }



  final String accessToken =
      'pk.eyJ1IjoiYXJ5YWthbGUwOSIsImEiOiJjbW10MHU4NzAxZ2hlMnJxdGQ0bnA0YmxzIn0.BgEabKzzP8AyPoR4WSYNlw';

  List<LatLng> routePoints = [];
  bool isLoading = false;

  double distanceKm = 0, timeMin = 0;
  double olaCost = 0, metroCost = 0, busCost = 0;
  double olaTime = 0, metroTime = 0, busTime = 0;
  String bestOption = '';
  String nearestMetroName = '';
  double nearestMetroDistance = 0;

  List<JourneyModel> journeyOptions = [];
  List<Map<String, dynamic>> busStops = [];

  // Live-location-as-source state
  bool _isUsingLiveLocation = false;   // true when From = GPS
  LatLng? _sourceLatLng;               // pre-resolved LatLng when using live loc

  LatLng? _liveLocation;
  StreamSubscription<LatLng>? _locationSub;
  bool _locationPermitted = false;

  final List<Map<String, dynamic>> metroStations = [
    {'name': 'PCMC', 'lat': 18.6298, 'lng': 73.7997},
    {'name': 'Sant Tukaram Nagar', 'lat': 18.6166, 'lng': 73.8037},
    {'name': 'Bhosari', 'lat': 18.6040, 'lng': 73.8075},
    {'name': 'Kasarwadi', 'lat': 18.5933, 'lng': 73.8095},
    {'name': 'Phugewadi', 'lat': 18.5805, 'lng': 73.8130},
    {'name': 'Dapodi', 'lat': 18.5700, 'lng': 73.8157},
    {'name': 'Bopodi', 'lat': 18.5610, 'lng': 73.8175},
    {'name': 'Khadki', 'lat': 18.5520, 'lng': 73.8200},
    {'name': 'Range Hill', 'lat': 18.5450, 'lng': 73.8235},
    {'name': 'Shivajinagar', 'lat': 18.5308, 'lng': 73.8470},
    {'name': 'Civil Court', 'lat': 18.5203, 'lng': 73.8567},
    {'name': 'Mandai', 'lat': 18.5135, 'lng': 73.8558},
    {'name': 'Swargate', 'lat': 18.5010, 'lng': 73.8630},
    {'name': 'Vanaz', 'lat': 18.5074, 'lng': 73.8077},
    {'name': 'Anand Nagar', 'lat': 18.5088, 'lng': 73.8000},
    {'name': 'Ideal Colony', 'lat': 18.5105, 'lng': 73.8120},
    {'name': 'Nal Stop', 'lat': 18.5125, 'lng': 73.8225},
    {'name': 'Garware College', 'lat': 18.5155, 'lng': 73.8350},
    {'name': 'Deccan Gymkhana', 'lat': 18.5180, 'lng': 73.8400},
    {'name': 'Sambhaji Udyan', 'lat': 18.5195, 'lng': 73.8455},
    {'name': 'Pune Railway Station', 'lat': 18.5286, 'lng': 73.8740},
    {'name': 'Ruby Hall Clinic', 'lat': 18.5315, 'lng': 73.8770},
    {'name': 'Bund Garden', 'lat': 18.5365, 'lng': 73.8845},
    {'name': 'Yerawada', 'lat': 18.5510, 'lng': 73.8870},
    {'name': 'Kalyani Nagar', 'lat': 18.5485, 'lng': 73.9020},
    {'name': 'Ramwadi', 'lat': 18.5620, 'lng': 73.9120},
  ];

  @override
  void initState() {
    super.initState();
    _initLiveLocation();

    Future.delayed(const Duration(seconds: 2), () {
      loadBusStops();
    });
  }

  Future<void> loadBusStops() async {
    final bounds = _mapController.camera.visibleBounds;
    if (bounds == null) return;

    try {
      final stops = await BusStopService.getBusStops(
        south: bounds.south,
        west: bounds.west,
        north: bounds.north,
        east: bounds.east,
      );

      setState(() {
        busStops = stops.take(80).toList();
        findNearestBusStop();
      });
    } catch (e) {
      debugPrint("Bus stop error: $e");
    }
  }
  Future<void> _initLiveLocation() async {
    final granted = await _locationService.requestPermission();
    if (!mounted) return;
    setState(() => _locationPermitted = granted);
    if (!granted) return;

    final current = await _locationService.getCurrentLocation();
    if (current != null && mounted) {
      setState(() => _liveLocation = current);
      _mapController.move(current, 13);
    }

    await _locationService.startTracking();
    _locationSub = _locationService.locationStream.listen((loc) {
      if (!mounted) return;
      setState(() {
        _liveLocation = loc;
        if (_isUsingLiveLocation) {
          _sourceLatLng = loc;
        }
      });
    });
  }

  // ── Use My Location ──────────────────────────────────────────────────────────

  /// Called when user taps the GPS button in the From field.
  /// Grabs the current live location, reverse-geocodes it for a human-readable
  /// label, fills the source text field, and marks _isUsingLiveLocation = true.
  Future<void> _useMyLocation() async {
    final granted = await _locationService.requestPermission();
    if (!mounted) return;
    setState(() => _locationPermitted = granted);

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable location permission and GPS.'),
        ),
      );
      return;
    }

    final current =
        await _locationService.getCurrentLocation() ?? _liveLocation;

    if (current == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS location not available yet. Please try again.'),
        ),
      );
      return;
    }

    setState(() {
      _isUsingLiveLocation = true;
      _liveLocation = current;
      _sourceLatLng = current;
      sourceController.text = 'Getting address…';
    });

    // Reverse-geocode to a readable address
    final address = await _reverseGeocode(current);
    if (mounted) {
      setState(() {
        sourceController.text = address ?? 'My Current Location';
      });
    }

    // Pan map to current location
    _mapController.move(current, 15);
    await _locationService.startTracking();
  }

  /// Reverse geocodes a LatLng using Mapbox and returns a short place name.
  Future<String?> _reverseGeocode(LatLng loc) async {
    try {
      final url =
          'https://api.mapbox.com/geocoding/v5/mapbox.places/'
          '${loc.longitude},${loc.latitude}.json'
          '?access_token=$accessToken'
          '&types=address,poi,locality,neighborhood&limit=1';
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);
      if (data['features'] != null && (data['features'] as List).isNotEmpty) {
        final full = data['features'][0]['place_name'] as String;
        final parts = full.split(',');
        return parts.take(2).join(',').trim();
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _locationService.stopTracking();
    sourceController.dispose();
    destController.dispose();
    super.dispose();
  }

  bool isWithinPune(LatLng loc) {
    return loc.latitude >= 18.40 &&
        loc.latitude <= 18.70 &&
        loc.longitude >= 73.70 &&
        loc.longitude <= 74.05;
  }

  double calculateDistance(LatLng a, LatLng b) {
    return const Distance()(a, b) / 1000;
  }

  Map<String, dynamic>? findNearestMetro(LatLng loc) {
    double min = double.infinity;
    Map<String, dynamic>? nearest;
    for (final m in metroStations) {
      final d = calculateDistance(loc, LatLng(m['lat'], m['lng']));
      if (d < min) {
        min = d;
        nearest = {...m, 'distance': d};
      }
    }
    return nearest;
  }

  void _centerOnLiveLocation() {
    if (_liveLocation != null) {
      _mapController.move(_liveLocation!, 15);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available yet')),
      );
    }
  }

  void openCabApp() async {
    final olaUrl = Uri.parse('olacabs://app');
    final uberUrl = Uri.parse('uber://');
    if (await canLaunchUrl(olaUrl)) {
      await launchUrl(olaUrl);
    } else if (await canLaunchUrl(uberUrl)) {
      await launchUrl(uberUrl);
    } else {
      await launchUrl(Uri.parse('https://ola.com'));
    }
  }

  void openBusApp() async => await launchUrl(Uri.parse('https://pmpml.org'));
  void openMetroApp() async =>
      await launchUrl(Uri.parse('https://www.punemetrorail.org'));

  void _openJourneyDetails(JourneyModel journey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JourneyDetailsScreen(
          journey: journey,
          accessToken: accessToken,
        ),
      ),
    );
  }

  Future<void> getRoute() async {
    // If user chose "My Location", use the pre-resolved GPS LatLng directly.
    // Otherwise geocode the typed text as before.
    final LatLng? start = _isUsingLiveLocation && _sourceLatLng != null
        ? _sourceLatLng
        : await getCoordinates(sourceController.text);
    final LatLng? end = await getCoordinates(destController.text);

    if (start == null || end == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find one of the locations')),
        );
      }
      return;
    }

    if (!isWithinPune(start) || !isWithinPune(end)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only Pune locations allowed')),
        );
      }
      return;
    }

    setState(() => isLoading = true);

    // Find nearest metro stations
    final metroStart = findNearestMetro(start);
    final metroEnd = findNearestMetro(end);
    if (metroStart != null && metroEnd != null) {
      final best = (metroStart['distance'] as double) <
          (metroEnd['distance'] as double)
          ? metroStart
          : metroEnd;
      nearestMetroName = best['name'];
      nearestMetroDistance = best['distance'];
    }

    try {
      final routeService = RouteService(accessToken: accessToken);

      final route = await routeService.getRoute(
        origin: start,
        destination: end,
      );

      routePoints = (route?['points'] as List<LatLng>?) ?? <LatLng>[];
      if (routePoints.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not find a route')),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      distanceKm = route!['distance'] as double;
      timeMin = route['duration'] as double;

      // Calculate costs for each transport mode
      // 🚇 METRO
      if (distanceKm <= 2) {
        metroCost = 10;
      } else if (distanceKm <= 5) {
        metroCost = 20;
      } else if (distanceKm <= 10) {
        metroCost = 30;
      } else {
        metroCost = 35;
      }

      double metroTime;
      double busTime;
      double olaTime;


// 🚌 BUS
      if (distanceKm <= 3) {
        busCost = 5;
      } else if (distanceKm <= 6) {
        busCost = 10;
      } else if (distanceKm <= 10) {
        busCost = 15;
      } else if (distanceKm <= 15) {
        busCost = 20;
      } else if (distanceKm <= 20) {
        busCost = 25;
      } else {
        busCost = 30;
      }

// 🚕 OLA / UBER
      double baseFare = 40;
      double perKmRate = 12;

      olaCost = baseFare + (distanceKm * perKmRate);

      if (olaCost < 80) {
        olaCost = 80;
      }

      // Calculate time for each transport mode
      olaTime = timeMin;
      busTime = timeMin * 1.3;
      metroTime = (timeMin * 0.7) + 5;

      // Determine best option
      double minTime = metroTime;
      bestOption = "Metro";

      if (busTime < minTime) {
        minTime = busTime;
        bestOption = "Bus";
      }

      if (olaTime < minTime) {
        minTime = olaTime;
        bestOption = "Ola";
      }

      // Generate multimodal journey options
      final multimodalService = MultimodalRouteService(metroStations: metroStations);
      journeyOptions = multimodalService.generateAllRoutes(
        origin: start,
        destination: end,
        originName: sourceController.text,
        destName: destController.text,
        distanceKm: distanceKm,
        durationMin: timeMin,
      );

      // Save to Firebase history
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('history')
          .add({
        'source': _isUsingLiveLocation ? 'My Location' : sourceController.text,
        'destination': destController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Center map on route
      if (routePoints.isNotEmpty) {
        _mapController.move(routePoints[routePoints.length ~/ 2], 13);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      debugPrint('getRoute error: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<LatLng?> getCoordinates(String place) async {
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(place)}.json?access_token=$accessToken';
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);
    if (data['features'].isNotEmpty) {
      final c = data['features'][0]['center'];
      return LatLng(c[1], c[0]);
    }
    return null;
  }

  Widget _transportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isBest = false,
  }) {
    return Card(
      elevation: isBest ? 6 : 3,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isBest ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Row(
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (isBest) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(10)),
                child: const Text('Best',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ]
          ],
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }

  Widget _journeyOptionCard(JourneyModel journey, int index) {
    final isFirst = index == 0;
    return Card(
      elevation: isFirst ? 6 : 3,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isFirst
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.indigo.withOpacity(0.12),
          child: Text(journey.typeEmoji, style: const TextStyle(fontSize: 18)),
        ),
        title: Row(
          children: [
            Text(journey.typeLabel,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (isFirst) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10)),
                child: const Text('Cheapest',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ]
          ],
        ),
        subtitle: Text(
          'Rs.${journey.totalCost.toStringAsFixed(0)}  •  '
              '${journey.totalDurationMin.toStringAsFixed(0)} min  •  '
              '${journey.totalDistanceKm.toStringAsFixed(1)} km',
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => _openJourneyDetails(journey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Transport'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
              if (result != null) {
                sourceController.text = result['source'];
                destController.text = result['destination'];
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(18.5204, 73.8567),
              initialZoom: 13,
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  loadBusStops();
                }
              },
            ),
            children: [
              MarkerLayer(
                markers: busStops.map((stop) {
                  return Marker(
                    point: LatLng(stop['lat'], stop['lng']),
                    width: 25,
                    height: 25,
                    child: Icon(
                      Icons.directions_bus,
                      color: (nearestBusStop != null &&
                          stop['lat'] == nearestBusStop!['lat'] &&
                          stop['lng'] == nearestBusStop!['lng'])
                          ? Colors.red // 🔥 highlight
                          : Colors.green,
                      size: 16,
                    ),
                  );
                }).toList(),
              ),
              TileLayer(
                urlTemplate:
                'https://api.mapbox.com/styles/v1/mapbox/navigation-day-v1/tiles/{z}/{x}/{y}?access_token=$accessToken',
              ),
              MarkerLayer(
                markers: metroStations.map((station) {
                  return Marker(
                    point: LatLng(station['lat'], station['lng']),
                    width: 40,
                    height: 40,
                    child: Column(
                      children: [
                        const Icon(Icons.train, color: Colors.blue, size: 22),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          color: Colors.white,
                          child: Text(
                            station['name'],
                            style: const TextStyle(fontSize: 7),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              if (routePoints.isNotEmpty)
                PolylineLayer(polylines: [
                  Polyline(
                      points: routePoints,
                      color: Colors.blue,
                      strokeWidth: 6)
                ]),
              if (_liveLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _liveLocation!,
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.35),
                            blurRadius: 10,
                            spreadRadius: 4,
                          )
                        ],
                      ),
                    ),
                  ),
                ]),
            ],
          ),

          if (isLoading) const Center(child: CircularProgressIndicator()),

          // Search panel
          Positioned(
            top: 40,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: sourceController,
                    onChanged: (_) {
                      // If user manually edits the field, stop using live loc
                      if (_isUsingLiveLocation) {
                        setState(() {
                          _isUsingLiveLocation = false;
                          _sourceLatLng = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'From',
                      prefixIcon: _isUsingLiveLocation
                          ? const Icon(Icons.my_location, color: Colors.blue)
                          : const Icon(Icons.my_location, color: Colors.green),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: Tooltip(
                        message: 'Use my current location',
                        child: IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _isUsingLiveLocation
                                ? const Icon(
                              Icons.gps_fixed,
                              key: ValueKey('fixed'),
                              color: Colors.blue,
                              size: 20,
                            )
                                : const Icon(
                              Icons.gps_not_fixed,
                              key: ValueKey('notfixed'),
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                          onPressed: _useMyLocation,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: destController,
                    decoration: const InputDecoration(
                      labelText: 'To',
                      prefixIcon:
                      Icon(Icons.location_on, color: Colors.red),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: getRoute,
                      icon: const Icon(Icons.directions),
                      label: const Text('Find Route'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (nearestBusStop != null)
            Positioned(
              top: 130,
              left: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_bus, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${nearestBusStop!['name']} • ${nearestBusDistance.toStringAsFixed(2)} km',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Live location FAB
          if (_locationPermitted)
            Positioned(
              right: 16,
              bottom: routePoints.isNotEmpty ? 440 : 24,
              child: FloatingActionButton(
                heroTag: 'live_loc_map',
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                onPressed: _centerOnLiveLocation,
                child: const Icon(Icons.my_location),
              ),
            ),

          // Bottom results panel
          if (routePoints.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, -4))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 4),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${distanceKm.toStringAsFixed(1)} km  •  ${timeMin.toStringAsFixed(0)} min',
                            style:
                            const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Best: $bestOption',
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Nearest Metro: $nearestMetroName (${nearestMetroDistance.toStringAsFixed(1)} km)',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                    const Divider(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (journeyOptions.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: Text('Multi-Modal Routes',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                        fontWeight: FontWeight.bold)),
                              ),
                              ...journeyOptions
                                  .asMap()
                                  .entries
                                  .map((e) =>
                                  _journeyOptionCard(e.value, e.key)),
                              const Divider(height: 16),
                            ],
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Text('Single Mode',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                      fontWeight: FontWeight.bold)),
                            ),
                            _transportCard(
                              title: 'Metro',
                              subtitle:
                              'Rs.${metroCost.toStringAsFixed(0)}  •  ${metroTime.toStringAsFixed(0)} min',
                              icon: Icons.train,
                              color: Colors.blue,
                              isBest: bestOption.contains('Metro'),
                              onTap: openMetroApp,
                            ),
                            _transportCard(
                              title: 'Bus (PMPML)',
                              subtitle:
                              'Rs.${busCost.toStringAsFixed(0)}  •  ${busTime.toStringAsFixed(0)} min',
                              icon: Icons.directions_bus,
                              color: Colors.green,
                              isBest: bestOption.contains('Bus'),
                              onTap: openBusApp,
                            ),
                            _transportCard(
                              title: 'Ola / Uber',
                              subtitle:
                              'Rs.${olaCost.toStringAsFixed(1)}  •  ${olaTime.toStringAsFixed(0)} min',
                              icon: Icons.local_taxi,
                              color: Colors.orange,
                              isBest: bestOption.contains('Ola'),
                              onTap: openCabApp,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
