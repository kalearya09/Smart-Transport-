import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/location_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/map_search_bar.dart';
import '../../widgets/sos_button.dart';
import '../../widgets/vehicle_info_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MapboxMap?                  _map;
  PointAnnotationManager?     _pointMgr;
  PolylineAnnotationManager?  _lineMgr;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final loc = context.read<LocationProvider>();
    final veh = context.read<VehicleProvider>();
    await loc.fetchOnce();
    loc.startTracking();
    veh.startTracking();
  }

  void _onMapCreated(MapboxMap map) async {
    _map = map;
    map.compass.updateSettings(CompassSettings(enabled: false));
    map.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    _pointMgr = await map.annotations.createPointAnnotationManager();
    _lineMgr  = await map.annotations.createPolylineAnnotationManager();

    final loc = context.read<LocationProvider>();
    if (loc.coords != null) {
      _flyTo(loc.coords!['lat']!, loc.coords!['lng']!);
    }
  }

  void _flyTo(double lat, double lng, {double zoom = 14}) {
    _map?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: zoom,
        pitch: 40,
      ),
      MapAnimationOptions(duration: 1200),
    );
  }

  Future<void> _updateMarkers(List<VehicleModel> vehicles) async {
    if (_pointMgr == null) return;
    await _pointMgr!.deleteAll();
    for (final v in vehicles) {
      await _pointMgr!.create(PointAnnotationOptions(
        geometry: Point(coordinates: Position(v.lng, v.lat)),
        iconSize: 1.2,
        textField: v.routeNumber,
        textSize: 11,
        textOffset: [0, 2.2],
        textColor: Colors.white.value,
        iconColor: v.status == 'delayed'
            ? Colors.orange.value
            : AppColors.primary.value,
      ));
    }
  }

  Future<void> _drawRoute(List<List<double>> pts) async {
    if (_lineMgr == null || pts.isEmpty) return;
    await _lineMgr!.deleteAll();
    await _lineMgr!.create(PolylineAnnotationOptions(
      geometry: LineString(coordinates: pts.map((p) => Position(p[0], p[1])).toList()),
      lineColor: AppColors.primary.value,
      lineWidth: 5.0,
      lineOpacity: 0.85,
    ));
  }

  String get _mapStyle {
    final isDark = context.read<ThemeProvider>().isDark;
    return isDark ? AppConstants.mapStyleDark : AppConstants.mapStyleLight;
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final veh     = context.watch<VehicleProvider>();
    final loc     = context.watch<LocationProvider>();
    final notif   = context.watch<NotificationProvider>();
    final route   = context.watch<RouteProvider>();

    // Side-effects after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (veh.vehicles.isNotEmpty) _updateMarkers(veh.vehicles);
      if (route.geometry.isNotEmpty) _drawRoute(route.geometry);
    });

    final coords = loc.coords;
    final hasVehicle = veh.selected != null;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────
          MapWidget(
            key: const ValueKey('mapbox'),
            styleUri: _mapStyle,
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(
                coords?['lng'] ?? AppConstants.defaultLng,
                coords?['lat'] ?? AppConstants.defaultLat,
              )),
              zoom: AppConstants.defaultZoom,
            ),
            onMapCreated: _onMapCreated,
          ),

          // ── Top bar ───────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: MapSearchBar(
                        onTap: () => Get.toNamed(AppRoutes.routePlanner)),
                  ),
                  const SizedBox(width: 12),
                  _topIconBtn(
                    icon: Icons.notifications_outlined,
                    badge: notif.unread > 0,
                    onTap: () => Get.toNamed(AppRoutes.notifications),
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),

          // ── Right FABs ────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: hasVehicle ? 295 : 170,
            child: Column(
              children: [
                _fab('loc', Icons.my_location_rounded, AppColors.primary,
                        () => coords != null
                        ? _flyTo(coords['lat']!, coords['lng']!)
                        : null),
                const SizedBox(height: 10),
                _fab('nearby', Icons.directions_bus_rounded, AppColors.accent,
                        () => Get.toNamed(AppRoutes.nearby)),
                const SizedBox(height: 10),
                _fab('satellite', Icons.satellite_alt_rounded, AppColors.success,
                        () => _map?.loadStyleURI(AppConstants.mapStyleSatellite)),
              ],
            ),
          ),

          // ── SOS ───────────────────────────────────────────────────
          Positioned(
            left: 16,
            bottom: hasVehicle ? 295 : 170,
            child: const SosButton(),
          ),

          // ── Vehicle card ──────────────────────────────────────────
          if (hasVehicle)
            Positioned(
              bottom: 82,
              left: 0, right: 0,
              child: VehicleInfoCard(
                vehicle: veh.selected!,
                onClose: veh.clearSelection,
                onViewDetails: () => Get.toNamed(AppRoutes.driverDetail),
              ),
            ),

          // ── Bottom nav ────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _bottomNav(theme),
          ),
        ],
      ),
    );
  }

  Widget _topIconBtn({
    required IconData icon,
    required bool badge,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: IconButton(icon: Icon(icon), onPressed: onTap),
        ),
        if (badge)
          Positioned(
            right: 8, top: 8,
            child: Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                  color: AppColors.error, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }

  Widget _fab(String tag, IconData icon, Color color, VoidCallback? onTap) {
    return FloatingActionButton.small(
      heroTag: tag,
      onPressed: onTap,
      backgroundColor: Theme.of(context).cardColor,
      foregroundColor: color,
      elevation: 4,
      child: Icon(icon),
    );
  }

  Widget _bottomNav(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1),
            blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.map_rounded,             Icons.map_outlined,             'Map'),
              _navItem(1, Icons.directions_bus_rounded,  Icons.directions_bus_outlined,  'Nearby',
                  onTap: () => Get.toNamed(AppRoutes.nearby)),
              _navItem(2, Icons.route_rounded,           Icons.route_outlined,           'Routes',
                  onTap: () => Get.toNamed(AppRoutes.routePlanner)),
              _navItem(3, Icons.notifications_rounded,   Icons.notifications_outlined,   'Alerts',
                  onTap: () => Get.toNamed(AppRoutes.notifications)),
              _navItem(4, Icons.person_rounded,          Icons.person_outlined,          'Profile',
                  onTap: () => Get.toNamed(AppRoutes.profile)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData active, IconData inactive, String label,
      {VoidCallback? onTap}) {
    final theme    = Theme.of(context);
    final isActive = _navIndex == idx;
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _navIndex = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? active : inactive,
                color: isActive
                    ? AppColors.primary
                    : theme.colorScheme.onSurface.withOpacity(0.45),
                size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? AppColors.primary
                      : theme.colorScheme.onSurface.withOpacity(0.45),
                )),
          ],
        ),
      ),
    );
  }
}