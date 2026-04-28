import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'history_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  final TextEditingController sourceController = TextEditingController();
  final TextEditingController destController = TextEditingController();

  final String accessToken = "pk.eyJ1IjoiYXJ5YWthbGUwOSIsImEiOiJjbW10MHU4NzAxZ2hlMnJxdGQ0bnA0YmxzIn0.BgEabKzzP8AyPoR4WSYNlw";

  List<LatLng> routePoints = [];
  bool isLoading = false;

  double distanceKm = 0, timeMin = 0;
  double olaCost = 0, metroCost = 0, busCost = 0;
  double olaTime = 0, metroTime = 0, busTime = 0;

  String bestOption = "";
  String nearestMetroName = "";
  double nearestMetroDistance = 0;

  // ================= PUNE RESTRICTION =================
  bool isWithinPune(LatLng loc) {
    return loc.latitude >= 18.40 &&
        loc.latitude <= 18.70 &&
        loc.longitude >= 73.70 &&
        loc.longitude <= 74.05;
  }

  // ================= METRO STATIONS =================
  final List<Map<String, dynamic>> metroStations = [
    {"name": "PCMC", "lat": 18.6298, "lng": 73.7997},
    {"name": "Sant Tukaram Nagar", "lat": 18.6166, "lng": 73.8037},
    {"name": "Bhosari", "lat": 18.6040, "lng": 73.8075},
    {"name": "Kasarwadi", "lat": 18.5933, "lng": 73.8095},
    {"name": "Phugewadi", "lat": 18.5805, "lng": 73.8130},
    {"name": "Dapodi", "lat": 18.5700, "lng": 73.8157},
    {"name": "Bopodi", "lat": 18.5610, "lng": 73.8175},
    {"name": "Khadki", "lat": 18.5520, "lng": 73.8200},
    {"name": "Range Hill", "lat": 18.5450, "lng": 73.8235},
    {"name": "Shivajinagar", "lat": 18.5308, "lng": 73.8470},
    {"name": "Civil Court", "lat": 18.5203, "lng": 73.8567},
    {"name": "Mandai", "lat": 18.5135, "lng": 73.8558},
    {"name": "Swargate", "lat": 18.5010, "lng": 73.8630},

    {"name": "Vanaz", "lat": 18.5074, "lng": 73.8077},
    {"name": "Anand Nagar", "lat": 18.5088, "lng": 73.8000},
    {"name": "Ideal Colony", "lat": 18.5105, "lng": 73.8120},
    {"name": "Nal Stop", "lat": 18.5125, "lng": 73.8225},
    {"name": "Garware College", "lat": 18.5155, "lng": 73.8350},
    {"name": "Deccan Gymkhana", "lat": 18.5180, "lng": 73.8400},
    {"name": "Sambhaji Udyan", "lat": 18.5195, "lng": 73.8455},
    {"name": "Pune Railway Station", "lat": 18.5286, "lng": 73.8740},
    {"name": "Ruby Hall Clinic", "lat": 18.5315, "lng": 73.8770},
    {"name": "Bund Garden", "lat": 18.5365, "lng": 73.8845},
    {"name": "Yerawada", "lat": 18.5510, "lng": 73.8870},
    {"name": "Kalyani Nagar", "lat": 18.5485, "lng": 73.9020},
    {"name": "Ramwadi", "lat": 18.5620, "lng": 73.9120},
  ];

  // ================= DISTANCE =================
  double calculateDistance(LatLng a, LatLng b) {
    final Distance d = Distance();
    return d(a, b) / 1000;
  }

  Map<String, dynamic>? findNearestMetro(LatLng loc) {
    double min = double.infinity;
    Map<String, dynamic>? nearest;

    for (var m in metroStations) {
      double dist = calculateDistance(loc, LatLng(m["lat"], m["lng"]));
      if (dist < min) {
        min = dist;
        nearest = {...m, "distance": dist};
      }
    }
    return nearest;
  }

  // ================= OPEN APPS =================
  void openCabApp() async {
    final olaUrl = Uri.parse("olacabs://app");
    final uberUrl = Uri.parse("uber://");

    if (await canLaunchUrl(olaUrl)) {
      await launchUrl(olaUrl);
    } else if (await canLaunchUrl(uberUrl)) {
      await launchUrl(uberUrl);
    } else {
      await launchUrl(Uri.parse("https://ola.com"));
    }
  }

  void openBusApp() async {
    await launchUrl(Uri.parse("https://pmpml.org"));
  }

  void openMetroApp() async {
    await launchUrl(Uri.parse("https://www.punemetrorail.org"));
  }

  // ================= ROUTE =================
  Future<void> getRoute() async {
    final start = await getCoordinates(sourceController.text);
    final end = await getCoordinates(destController.text);

    if (start == null || end == null) return;

    if (!isWithinPune(start) || !isWithinPune(end)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Only Pune locations allowed")),
      );
      return;
    }

    setState(() => isLoading = true);

    final metroStart = findNearestMetro(start);
    final metroEnd = findNearestMetro(end);

    if (metroStart != null && metroEnd != null) {
      final bestMetro = (metroStart["distance"] < metroEnd["distance"])
          ? metroStart
          : metroEnd;

      nearestMetroName = bestMetro["name"];
      nearestMetroDistance = bestMetro["distance"];
    }

    final url =
        "https://api.mapbox.com/directions/v5/mapbox/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&access_token=$accessToken";

    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);
    final route = data['routes'][0];

    distanceKm = route['distance'] / 1000;
    timeMin = route['duration'] / 60;

    olaCost = distanceKm * 25;
    busCost = distanceKm * 10;

    olaTime = timeMin;
    busTime = timeMin * 1.3;

    metroCost = distanceKm * 10;
    metroTime = (timeMin * 0.7) + 5;

    bestOption = "Metro + Auto";

    final coords = route['geometry']['coordinates'];
    routePoints = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('history')
        .add({
      'source': sourceController.text,
      'destination': destController.text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() => isLoading = false);
  }

  Future<LatLng?> getCoordinates(String place) async {
    final url =
        "https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(place)}.json?access_token=$accessToken";

    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    if (data['features'].isNotEmpty) {
      final c = data['features'][0]['center'];
      return LatLng(c[1], c[0]);
    }
    return null;
  }

  // ================= CARD =================
  Widget transportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Transport"),
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
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(18.5204, 73.8567),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate:
                "https://api.mapbox.com/styles/v1/mapbox/navigation-day-v1/tiles/{z}/{x}/{y}?access_token=$accessToken",
              ),

              // 🚇 METRO MARKERS
              MarkerLayer(
                markers: metroStations.map((station) {
                  return Marker(
                    point: LatLng(station["lat"], station["lng"]),
                    width: 40,
                    height: 40,
                    child: Column(
                      children: [
                        const Icon(Icons.train, color: Colors.blue, size: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          color: Colors.white,
                          child: Text(
                            station["name"],
                            style: const TextStyle(fontSize: 8),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              // 🚗 ROUTE
              if (routePoints.isNotEmpty)
                PolylineLayer(polylines: [
                  Polyline(points: routePoints, color: Colors.black, strokeWidth: 5)
                ]),
            ],
          ),

          if (isLoading)
            const Center(child: CircularProgressIndicator()),

          Positioned(
            top: 40,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(controller: sourceController),
                  TextField(controller: destController),
                  ElevatedButton(onPressed: getRoute, child: const Text("Find Route"))
                ],
              ),
            ),
          ),

          if (routePoints.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(15),
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${distanceKm.toStringAsFixed(2)} km • ${timeMin.toStringAsFixed(0)} min"),
                    Text("Nearest Metro: $nearestMetroName (${nearestMetroDistance.toStringAsFixed(1)} km)"),
                    Text("Best: $bestOption", style: const TextStyle(color: Colors.green)),

                    const SizedBox(height: 10),

                    transportCard(
                      title: "Metro",
                      subtitle: "₹${metroCost.toStringAsFixed(0)} • ${metroTime.toStringAsFixed(0)} min",
                      icon: Icons.train,
                      color: Colors.blue,
                      onTap: openMetroApp,
                    ),

                    transportCard(
                      title: "Bus (PMPML)",
                      subtitle: "₹${busCost.toStringAsFixed(0)} • ${busTime.toStringAsFixed(0)} min",
                      icon: Icons.directions_bus,
                      color: Colors.green,
                      onTap: openBusApp,
                    ),

                    transportCard(
                      title: "Ola / Uber",
                      subtitle: "₹${olaCost.toStringAsFixed(0)} • ${olaTime.toStringAsFixed(0)} min",
                      icon: Icons.local_taxi,
                      color: Colors.orange,
                      onTap: openCabApp,
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
