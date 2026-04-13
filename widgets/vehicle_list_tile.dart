import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../providers/vehicle_provider.dart';
import '../core/routes/app_routes.dart';

class VehicleListTile extends StatelessWidget {
  final VehicleModel vehicle;
  final double distanceM;

  const VehicleListTile({
    super.key,
    required this.vehicle,
    required this.distanceM,
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
      case 'delayed': return '⚠ Delayed';
      case 'arrived': return '✓ Arrived';
      default:        return '● On Time';
    }
  }

  String _formatDistance() {
    if (distanceM < 1000) return '${distanceM.toStringAsFixed(0)} m';
    return '${(distanceM / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sc    = _statusColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await context.read<VehicleProvider>().selectVehicle(vehicle);
          Get.toNamed(AppRoutes.driverDetail);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  vehicle.type == 'metro' ? Icons.train_rounded : Icons.directions_bus_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Route ${vehicle.routeNumber}',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: sc.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_statusLabel(),
                              style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(vehicle.routeName,
                        style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.speed_rounded, size: 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 3),
                        Text('${vehicle.speed.toStringAsFixed(0)} km/h',
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
                        const SizedBox(width: 10),
                        Icon(Icons.people_rounded, size: 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 3),
                        Text('${vehicle.currentPassengers}/${vehicle.capacity}',
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatDistance(),
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurface.withOpacity(0.4)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}