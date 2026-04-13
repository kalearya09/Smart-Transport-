import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/vehicle_provider.dart';

class DriverDetailScreen extends StatelessWidget {
  const DriverDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final veh    = context.watch<VehicleProvider>();
    final driver = veh.driver;
    final vehicle= veh.selected;

    if (driver == null || vehicle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Driver Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Driver & Vehicle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Driver card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: driver.photoUrl.isNotEmpty
                            ? NetworkImage(driver.photoUrl)
                            : null,
                        child: driver.photoUrl.isEmpty
                            ? Text(driver.name[0].toUpperCase(),
                            style: const TextStyle(
                                fontSize: 32, fontWeight: FontWeight.w700,
                                color: AppColors.primary))
                            : null,
                      ),
                      if (driver.isOnDuty)
                        Positioned(
                          bottom: 2, right: 2,
                          child: Container(
                            width: 16, height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(driver.name, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(driver.isOnDuty ? 'On Duty' : 'Off Duty',
                      style: TextStyle(
                          color: driver.isOnDuty ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.w600, fontSize: 13)),

                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat(theme, '${driver.rating}', 'Rating', Icons.star_rounded, AppColors.warning),
                      _vDivider(),
                      _stat(theme, '${driver.totalTrips}', 'Total Trips', Icons.route_rounded, AppColors.primary),
                      _vDivider(),
                      _stat(theme, driver.isOnDuty ? 'Active' : 'Off', 'Status',
                          Icons.circle, driver.isOnDuty ? AppColors.success : AppColors.warning),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 16),

            // Driver info
            _infoCard(theme, 'Driver Information', [
              _infoRow(theme, Icons.phone_outlined, 'Phone', driver.phone),
              _infoRow(theme, Icons.credit_card_outlined, 'License', driver.licenseNumber),
            ]).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 16),

            // Vehicle info
            _infoCard(theme, 'Vehicle Information', [
              _infoRow(theme, Icons.directions_bus_rounded, 'Route', vehicle.routeNumber),
              _infoRow(theme, Icons.label_outlined, 'Route Name', vehicle.routeName),
              _infoRow(theme, Icons.speed_rounded, 'Current Speed',
                  '${vehicle.speed.toStringAsFixed(0)} km/h'),
              _infoRow(theme, Icons.people_rounded, 'Passengers',
                  '${vehicle.currentPassengers} / ${vehicle.capacity}'),
              _infoRow(theme, Icons.info_outline, 'Status',
                  vehicle.status == 'on_time' ? 'On Time'
                      : vehicle.status == 'delayed' ? 'Delayed' : 'Arrived'),
            ]).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 16),

            // Occupancy bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bus Occupancy', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${vehicle.currentPassengers} passengers',
                          style: theme.textTheme.bodyMedium),
                      Text('${(vehicle.occupancy * 100).toStringAsFixed(0)}% full',
                          style: TextStyle(
                              color: vehicle.isCrowded ? AppColors.warning : AppColors.success,
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: vehicle.occupancy,
                      minHeight: 10,
                      backgroundColor: theme.dividerColor,
                      valueColor: AlwaysStoppedAnimation(
                          vehicle.isCrowded ? AppColors.warning : AppColors.success),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _stat(ThemeData t, String val, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(val, style: t.textTheme.titleMedium),
        Text(label, style: t.textTheme.bodyMedium?.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 48, color: Colors.grey.withOpacity(0.2));

  Widget _infoCard(ThemeData t, String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData t, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Text('$label: ', style: t.textTheme.bodyMedium),
          Expanded(
            child: Text(value,
                style: t.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}