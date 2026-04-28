import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_typeahead/flutter_typeahead.dart';

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
  List<LatLng> metroRoutePoints = [];

  bool isLoading = false;

  double distanceKm = 0, timeMin = 0;
  double olaCost = 0, metroCost = 0, busCost = 0;
  double olaTime = 0, metroTime = 0, busTime = 0;

  String bestOption = "";
  String nearestMetroName = "";
  double nearestMetroDistance = 0;

  final List<Map<String, dynamic>> metroStations = [
    {"name": "Vanaz", "lat": 18.5074, "lng": 73.8077},
    {"name": "Garware", "lat": 18.5126, "lng": 73.8326},
    {"name": "Deccan", "lat": 18.5196, "lng": 73.8410},
    {"name": "Civil Court", "lat": 18.5203, "lng": 73.8567},
    {"name": "Shivajinagar", "lat": 18.5308, "lng": 73.8475},
    {"name": "PCMC", "lat": 18.6298, "lng": 73.7997},
  ];

  // 🔍 Suggestions
  Future<List<String>> getSuggestions(String query) async {
    if (query.isEmpty) return [];

    final url =
        "https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json"
        "?autocomplete=true&limit=5&proximity=73.8567,18.5204&access_token=$accessToken";

    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    return (data['features'] as List)
        .map((f) => f['place_name'].toString())
        .toList();
  }

  Future<LatLng?> getCoordinates(String place) async {
    if (!place.toLowerCase().contains("pune")) place = "$place Pune";

    final url =
        "https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(place)}.json"
        "?limit=1&access_token=$accessToken";

    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    if (data['features'].isNotEmpty) {
      final c = data['features'][0]['center'];
      return LatLng(c[1], c[0]);
    }
    return null;
  }

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

  Future<void> getRoute() async {
    final start = await getCoordinates(sourceController.text);
    final end = await getCoordinates(destController.text);

    if (start == null || end == null) return;

    setState(() => isLoading = true);

    final metroStart = findNearestMetro(start);
    final metroEnd = findNearestMetro(end);

    final bestMetro = (metroStart!["distance"] < metroEnd!["distance"])
        ? metroStart
        : metroEnd;

    nearestMetroName = bestMetro["name"];
    nearestMetroDistance = bestMetro["distance"];

    final url =
        "https://api.mapbox.com/directions/v5/mapbox/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&access_token=$accessToken";

    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);
    final route = data['routes'][0];

    distanceKm = route['distance'] / 1000;
    timeMin = route['duration'] / 60;

    olaCost = distanceKm * 15;
    busCost = distanceKm * 3;
    olaTime = timeMin;
    busTime = timeMin * 1.3;

    if (nearestMetroDistance < 3) {
      metroCost = distanceKm * 5;
      metroTime = timeMin * 0.7;
      bestOption = "Metro + Auto";
    } else if (olaTime < busTime) {
      bestOption = "Ola/Uber";
    } else {
      bestOption = "Bus";
      metroCost = 0;
      metroTime = 0;
    }

    final coords = route['geometry']['coordinates'];
    routePoints =
        coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();

    metroRoutePoints.clear();

    if (metroCost > 0) {
      final metroUrl =
          "https://api.mapbox.com/directions/v5/mapbox/driving/${start.longitude},${start.latitude};${bestMetro["lng"]},${bestMetro["lat"]}?geometries=geojson&access_token=$accessToken";

      final mres = await http.get(Uri.parse(metroUrl));
      final mdata = json.decode(mres.body);

      final mcoords = mdata['routes'][0]['geometry']['coordinates'];
      metroRoutePoints =
          mcoords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
    }

    setState(() => isLoading = false);
  }

  Widget buildCard(String title, String sub, IconData icon, bool highlight) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? Colors.green.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              Text(sub),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Smart Transport")),
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
              if (routePoints.isNotEmpty)
                PolylineLayer(polylines: [
                  Polyline(points: routePoints, color: Colors.blue, strokeWidth: 5)
                ]),
              if (metroRoutePoints.isNotEmpty)
                PolylineLayer(polylines: [
                  Polyline(points: metroRoutePoints, color: Colors.green, strokeWidth: 4)
                ]),
            ],
          ),

          if (isLoading) Center(child: CircularProgressIndicator()),

          // 🔍 SEARCH
          Positioned(
            top: 40,
            left: 15,
            right: 15,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  TypeAheadField<String>(
                    suggestionsCallback: getSuggestions,
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: sourceController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: "Source",
                          border: InputBorder.none,
                        ),
                      );
                    },
                    itemBuilder: (context, s) => ListTile(title: Text(s)),
                    onSelected: (s) => sourceController.text = s,
                  ),
                  Divider(),
                  TypeAheadField<String>(
                    suggestionsCallback: getSuggestions,
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: destController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: "Destination",
                          border: InputBorder.none,
                        ),
                      );
                    },
                    itemBuilder: (context, s) => ListTile(title: Text(s)),
                    onSelected: (s) => destController.text = s,
                  ),
                  ElevatedButton(onPressed: getRoute, child: Text("Find Route"))
                ],
              ),
            ),
          ),

          // 🔻 BOTTOM PANEL
          if (routePoints.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${distanceKm.toStringAsFixed(2)} km • ${timeMin.toStringAsFixed(0)} min"),
                    Text("Nearest Metro: $nearestMetroName (${nearestMetroDistance.toStringAsFixed(1)} km)"),
                    Text("Best: $bestOption", style: TextStyle(color: Colors.green)),

                    buildCard("Ola/Uber",
                        "₹${olaCost.toStringAsFixed(0)} | ${olaTime.toStringAsFixed(0)} min",
                        Icons.local_taxi, bestOption == "Ola/Uber"),

                    buildCard("Metro",
                        metroCost == 0 ? "Not Available"
                            : "₹${metroCost.toStringAsFixed(0)} | ${metroTime.toStringAsFixed(0)} min",
                        Icons.train, bestOption.contains("Metro")),

                    buildCard("Bus",
                        "₹${busCost.toStringAsFixed(0)} | ${busTime.toStringAsFixed(0)} min",
                        Icons.directions_bus, bestOption == "Bus"),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
