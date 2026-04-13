import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/location_provider.dart';
import '../../providers/route_provider.dart';
import '../../widgets/app_button.dart';

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({super.key});
  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  final _fromCtrl = TextEditingController();
  final _toCtrl   = TextEditingController();
  List<GeocodingResult> _fromResults = [];
  List<GeocodingResult> _toResults   = [];
  bool _searchingFrom = false;
  bool _searchingTo   = false;

  @override
  void initState() {
    super.initState();
    final loc = context.read<LocationProvider>();
    final c   = loc.coords;
    if (c != null) {
      _fromCtrl.text = 'My Current Location';
      context.read<RouteProvider>()
          .setOrigin(c['lat']!, c['lng']!, 'My Current Location');
    }
  }

  @override
  void dispose() { _fromCtrl.dispose(); _toCtrl.dispose(); super.dispose(); }

  Future<void> _searchFrom(String q) async {
    if (q.isEmpty || q == 'My Current Location') return;
    setState(() => _searchingFrom = true);
    final r = await context.read<RouteProvider>().geocode(q);
    setState(() { _fromResults = r; _searchingFrom = false; });
  }

  Future<void> _searchTo(String q) async {
    if (q.isEmpty) return;
    setState(() => _searchingTo = true);
    final r = await context.read<RouteProvider>().geocode(q);
    setState(() { _toResults = r; _searchingTo = false; });
  }

  void _pickFrom(GeocodingResult r) {
    _fromCtrl.text = r.name;
    context.read<RouteProvider>().setOrigin(r.lat, r.lng, r.name);
    setState(() => _fromResults = []);
  }

  void _pickTo(GeocodingResult r) {
    _toCtrl.text = r.name;
    context.read<RouteProvider>().setDestination(r.lat, r.lng, r.name);
    setState(() => _toResults = []);
  }

  Future<void> _plan() async {
    if (_toCtrl.text.trim().isEmpty) {
      Get.snackbar('Missing destination', 'Please enter a destination',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
      return;
    }
    await context.read<RouteProvider>().planRoute();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rp    = context.watch<RouteProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Route Planner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  _SearchRow(
                    controller: _fromCtrl,
                    label: 'From',
                    hint: 'Starting point',
                    dotColor: AppColors.success,
                    isLoading: _searchingFrom,
                    onChanged: _searchFrom,
                  ),
                  if (_fromResults.isNotEmpty)
                    _Suggestions(results: _fromResults, onSelect: _pickFrom),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const SizedBox(width: 20),
                        Expanded(child: Divider(color: theme.dividerColor)),
                        IconButton(
                          icon: const Icon(Icons.swap_vert_rounded,
                              color: AppColors.primary),
                          onPressed: () {
                            final t = _fromCtrl.text;
                            _fromCtrl.text = _toCtrl.text;
                            _toCtrl.text   = t;
                          },
                        ),
                      ],
                    ),
                  ),

                  _SearchRow(
                    controller: _toCtrl,
                    label: 'To',
                    hint: 'Search destination…',
                    dotColor: AppColors.error,
                    isLoading: _searchingTo,
                    onChanged: _searchTo,
                  ),
                  if (_toResults.isNotEmpty)
                    _Suggestions(results: _toResults, onSelect: _pickTo),

                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Find Routes',
                    icon: Icons.search_rounded,
                    onPressed: _plan,
                    isLoading: rp.status == PlanStatus.loading,
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),

            // Error banner
            if (rp.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(rp.error!,
                          style: const TextStyle(
                              color: AppColors.warning, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],

            // Route results
            if (rp.status == PlanStatus.loaded && rp.routes.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('Suggested Routes', style: theme.textTheme.titleLarge),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${rp.routes.length} found',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...rp.routes.asMap().entries.map((e) => _RouteCard(
                route: e.value,
                isSelected: rp.selected?.id == e.value.id,
                onTap: () => rp.selectRoute(e.value),
              ).animate(delay: (e.key * 100).ms).fadeIn().slideY(begin: 0.1)),

              if (rp.selected != null) ...[
                const SizedBox(height: 16),
                AppButton(
                  label: 'View on Map',
                  icon: Icons.map_rounded,
                  outlined: true,
                  onPressed: () => Get.back(),
                ),
              ],
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Search row ────────────────────────────────────────────────────
class _SearchRow extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final Color dotColor;
  final bool isLoading;
  final ValueChanged<String> onChanged;

  const _SearchRow({
    required this.controller, required this.label, required this.hint,
    required this.dotColor, required this.isLoading, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, color: dotColor, size: 14),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: label, hintText: hint,
              border: InputBorder.none,
              filled: false,
              suffixIcon: isLoading
                  ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)))
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Suggestions list ──────────────────────────────────────────────
class _Suggestions extends StatelessWidget {
  final List<GeocodingResult> results;
  final ValueChanged<GeocodingResult> onSelect;

  const _Suggestions({required this.results, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 6),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: results.map((r) => ListTile(
          dense: true,
          leading: const Icon(Icons.place_outlined, size: 18),
          title: Text(r.name, style: theme.textTheme.bodyLarge,
              maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () => onSelect(r),
        )).toList(),
      ),
    );
  }
}

// ── Route card ────────────────────────────────────────────────────
class _RouteCard extends StatelessWidget {
  final RouteModel route;
  final bool isSelected;
  final VoidCallback onTap;

  const _RouteCard({required this.route, required this.isSelected, required this.onTap});

  Color get _color {
    switch (route.type) {
      case 'walking':   return AppColors.success;
      case 'alternate': return AppColors.accent;
      default:          return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (route.type) {
      case 'walking':   return Icons.directions_walk_rounded;
      case 'alternate': return Icons.alt_route_rounded;
      default:          return Icons.flash_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c     = _color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? c.withOpacity(0.07) : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? c : theme.dividerColor,
              width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                  color: c.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(_icon, color: c),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(route.name, style: theme.textTheme.titleMedium),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: c, borderRadius: BorderRadius.circular(20)),
                        child: Text(route.type[0].toUpperCase() + route.type.substring(1),
                            style: const TextStyle(color: Colors.white,
                                fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text('${route.durationMinutes} min',
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(width: 12),
                      Icon(Icons.straighten_rounded, size: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text('${route.distanceKm.toStringAsFixed(1)} km',
                          style: theme.textTheme.bodyMedium),
                      if (route.stops.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.stop_circle_outlined, size: 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text('${route.stops.length} stops',
                            style: theme.textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: c),
          ],
        ),
      ),
    );
  }
}