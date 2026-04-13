import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/location_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/vehicle_list_tile.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});
  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  double _radius = 2.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _filter());
  }

  void _filter() {
    final loc = context.read<LocationProvider>();
    final veh = context.read<VehicleProvider>();
    final c   = loc.coords;
    if (c != null) veh.filterNearby(c['lat']!, c['lng']!, _radius);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final veh   = context.watch<VehicleProvider>();
    final loc   = context.watch<LocationProvider>();
    final list  = veh.nearby;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Vehicles'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _filter),
        ],
      ),
      body: Column(
        children: [
          // Radius card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Search radius', style: theme.textTheme.titleMedium),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${_radius.toStringAsFixed(1)} km',
                          style: const TextStyle(
                              color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                Slider(
                  value: _radius, min: 0.5, max: 10.0, divisions: 19,
                  activeColor: AppColors.primary,
                  onChanged: (v) { setState(() => _radius = v); _filter(); },
                ),
              ],
            ),
          ),

          // Count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.directions_bus_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('${list.length} vehicle${list.length == 1 ? '' : 's'} found',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          // List
          Expanded(
            child: list.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus_outlined, size: 64,
                      color: theme.colorScheme.onSurface.withOpacity(0.25)),
                  const SizedBox(height: 16),
                  Text('No vehicles nearby',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  const SizedBox(height: 6),
                  Text('Try increasing the search radius',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: list.length,
              itemBuilder: (ctx, i) {
                final v    = list[i];
                final dist = loc.distanceTo(v.lat, v.lng);
                return VehicleListTile(vehicle: v, distanceM: dist)
                    .animate(delay: (i * 70).ms)
                    .fadeIn()
                    .slideX(begin: 0.1);
              },
            ),
          ),
        ],
      ),
    );
  }
}