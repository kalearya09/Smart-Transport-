import 'dart:convert';
import 'package:http/http.dart' as http;

class BusStopService {
  static Future<List<Map<String, dynamic>>> getBusStops({
    required double south,
    required double west,
    required double north,
    required double east,
  }) async {
    final query = '''
    [out:json];
    node["highway"="bus_stop"]($south,$west,$north,$east);
    out;
    ''';

    final url = Uri.parse(
      'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to load bus stops");
    }

    final data = jsonDecode(response.body);

    return (data['elements'] as List).map((e) {
      return {
        'name': e['tags']?['name'] ?? 'Bus Stop',
        'lat': e['lat'],
        'lng': e['lon'],
      };
    }).toList();
  }
}