import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';

class VehicleInfoCard extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback onClose;
  final VoidCallback onViewDetails;

  const VehicleInfoCard({
    super.key,
    required this.vehicle,
    required this.onClose,
    required this.onViewDetails,
  });

  Color _statusColor() {
    switch (vehicle.status) {
      case 'delayed': return AppColors.warning;
      case 'arrived': return AppColors.success;
      default:        return AppColors.primary;
    }
  }

  String _statusLabel() {
    switch (vehicle.status) {
      case 'delayed': return 'Delayed';
      case 'arrived': return 'Arrived';
      default:        return 'On Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sc    = _statusColor();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15),
              blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          vehicle.type == 'metro'
                              ? Icons.train_rounded
                              : Icons.directions_bus_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Route ${vehicle.routeNumber}',
                                style: theme.textTheme.titleLarge),
                            Text(vehicle.routeName,
                                style: theme.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      // Status chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sc.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_statusLabel(),
                            style: TextStyle(color: sc, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(onTap: onClose,
                          child: Icon(Icons.close_rounded, size: 20,
                              color: theme.colorScheme.onSurface.withOpacity(0.5))),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat(theme, Icons.speed_rounded,
                          '${vehicle.speed.toStringAsFixed(0)} km/h', 'Speed'),
                      _divider(),
                      _stat(theme, Icons.people_rounded,
                          '${vehicle.currentPassengers}/${vehicle.capacity}', 'Passengers'),
                      _divider(),
                      _stat(theme, Icons.access_time_rounded, '~5 min', 'ETA'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Occupancy bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Occupancy', style: theme.textTheme.bodyMedium),
                          Text('${(vehicle.occupancy * 100).toStringAsFixed(0)}%',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: vehicle.isCrowded ? AppColors.warning : AppColors.success,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: vehicle.occupancy,
                          minHeight: 6,
                          backgroundColor: theme.dividerColor,
                          valueColor: AlwaysStoppedAnimation(
                              vehicle.isCrowded ? AppColors.warning : AppColors.success),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // View details button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onViewDetails,
                      icon: const Icon(Icons.person_rounded, size: 18),
                      label: const Text('View Driver & Details'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().slideY(begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOut),
    );
  }

  Widget _stat(ThemeData t, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: t.colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: t.textTheme.titleMedium?.copyWith(fontSize: 13)),
        Text(label,  style: t.textTheme.bodyMedium?.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 40,
      color: AppColors.lBorder.withOpacity(0.5));
}