import 'package:flutter/material.dart';
import '../models/journey_leg.dart';

class JourneyStepCard extends StatelessWidget {
  final JourneyLeg leg;
  final int stepNumber;
  final bool isLast;

  const JourneyStepCard({
    super.key,
    required this.leg,
    required this.stepNumber,
    required this.isLast,
  });

  Color get _modeColor {
    switch (leg.mode) {
      case TransportMode.walk:
        return Colors.teal;
      case TransportMode.bus:
        return Colors.green;
      case TransportMode.metro:
        return Colors.blue;
      case TransportMode.cab:
        return Colors.orange;
    }
  }

  IconData get _modeIcon {
    switch (leg.mode) {
      case TransportMode.walk:
        return Icons.directions_walk;
      case TransportMode.bus:
        return Icons.directions_bus;
      case TransportMode.metro:
        return Icons.train;
      case TransportMode.cab:
        return Icons.local_taxi;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline column ──────────────────────────────────────────────
          SizedBox(
            width: 48,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _modeColor,
                  child: Icon(_modeIcon, color: Colors.white, size: 16),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: _modeColor.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Content card ─────────────────────────────────────────────────
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _modeColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _modeColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step label
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _modeColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${leg.modeEmoji} ${leg.modeLabel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (leg.cost > 0)
                        Text(
                          '₹${leg.cost.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: _modeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      else
                        Text(
                          'Free',
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // From → To
                  Text(
                    '${leg.fromName}  →  ${leg.toName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Instruction
                  Text(
                    leg.instruction,
                    style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        height: 1.4),
                  ),

                  const SizedBox(height: 8),

                  // Stats row
                  Row(
                    children: [
                      _statChip(
                          Icons.schedule,
                          '${leg.durationMin.toStringAsFixed(0)} min',
                          Colors.grey[800]!),
                      const SizedBox(width: 8),
                      _statChip(
                          Icons.straighten,
                          '${leg.distanceKm.toStringAsFixed(1)} km',
                          Colors.grey[800]!),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
