import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/driver.dart';
import '../../bloc/tracking_bloc.dart';

/// Bottom card on the tracking screen: driver identity, car, live ETA and the
/// phase-appropriate action.
class DriverCard extends StatelessWidget {
  const DriverCard({
    super.key,
    required this.driver,
    required this.phase,
    required this.etaSeconds,
    required this.progress,
    required this.onCancel,
  });

  final Driver driver;
  final TrackingPhase phase;
  final int etaSeconds;
  final double progress;
  final VoidCallback onCancel;

  bool get _canCancel =>
      phase == TrackingPhase.driverEnRoute ||
      phase == TrackingPhase.driverArrived;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProgressBar(),
            const SizedBox(height: 18),
            Row(
              children: [
                _Avatar(initials: driver.initials),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: AppTheme.amber,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${driver.rating}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '· ${driver.carLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _CarPlate(number: driver.carNumber),
              ],
            ),
            const SizedBox(height: 16),
            _buildEtaRow(),
            if (_canCancel) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cancel ride'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppTheme.outline),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 200),
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: 5,
          backgroundColor: AppTheme.surfaceHigh,
          valueColor: AlwaysStoppedAnimation(
            phase == TrackingPhase.onTrip ? AppTheme.success : AppTheme.violet,
          ),
        ),
      ),
    );
  }

  Widget _buildEtaRow() {
    final isArrived = phase == TrackingPhase.driverArrived;
    final label = switch (phase) {
      TrackingPhase.driverEnRoute => 'Arriving in',
      TrackingPhase.driverArrived => 'Waiting for you',
      TrackingPhase.onTrip => 'Reaching drop in',
      _ => 'Trip status',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Icon(
            isArrived ? Icons.emoji_people_rounded : Icons.timer_outlined,
            color: isArrived ? AppTheme.success : AppTheme.violet,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13.5,
              ),
            ),
          ),
          Text(
            isArrived ? 'Now' : Formatters.countdown(etaSeconds),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isArrived ? AppTheme.success : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      width: 54,
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.violet, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppTheme.violet,
        ),
      ),
    );
  }
}

class _CarPlate extends StatelessWidget {
  const _CarPlate({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Text(
        number,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
