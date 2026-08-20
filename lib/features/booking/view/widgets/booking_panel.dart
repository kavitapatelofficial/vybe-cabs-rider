import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../data/models/place.dart';
import '../../../../data/models/ride_estimate.dart';

/// The bottom card on Home. Shows the "Where to?" prompt until a destination
/// is chosen, then swaps to the trip summary + fare quote + Book Ride button.
class BookingPanel extends StatelessWidget {
  const BookingPanel({
    super.key,
    required this.pickup,
    required this.destination,
    required this.estimate,
    required this.isLoading,
    required this.onSearchTapped,
    required this.onClearDestination,
    required this.onBookRide,
  });

  final Place? pickup;
  final Place? destination;
  final RideEstimate? estimate;
  final bool isLoading;
  final VoidCallback onSearchTapped;
  final VoidCallback onClearDestination;
  final VoidCallback onBookRide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: destination == null
              ? _SearchPrompt(onTap: onSearchTapped, isLoading: isLoading)
              : _TripSummary(
                  pickup: pickup,
                  destination: destination!,
                  estimate: estimate,
                  onChange: onSearchTapped,
                  onClear: onClearDestination,
                  onBookRide: onBookRide,
                ),
        ),
      ),
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt({required this.onTap, required this.isLoading});

  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('search-prompt'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Book a ride',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        // Styled as a search bar, but it opens the dummy destination sheet —
        // no places API involved.
        InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppTheme.outline),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Where to?',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Pick from your saved destinations to see fare and ETA.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
        ),
      ],
    );
  }
}

class _TripSummary extends StatelessWidget {
  const _TripSummary({
    required this.pickup,
    required this.destination,
    required this.estimate,
    required this.onChange,
    required this.onClear,
    required this.onBookRide,
  });

  final Place? pickup;
  final Place destination;
  final RideEstimate? estimate;
  final VoidCallback onChange;
  final VoidCallback onClear;
  final VoidCallback onBookRide;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('trip-summary'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your trip',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _RouteRow(
          pickupName: pickup?.name ?? 'Current location',
          dropName: destination.name,
          onChangeDrop: onChange,
        ),
        const SizedBox(height: 18),
        if (estimate != null) _FareCard(estimate: estimate!),
        const SizedBox(height: 18),
        LoadingButton(
          label: 'Book Ride',
          icon: Icons.local_taxi_rounded,
          onPressed: onBookRide,
        ),
      ],
    );
  }
}

/// Pickup -> drop with the classic connected dot / square indicator.
class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.pickupName,
    required this.dropName,
    required this.onChangeDrop,
  });

  final String pickupName;
  final String dropName;
  final VoidCallback onChangeDrop;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: 6),
            Container(
              height: 10,
              width: 10,
              decoration: const BoxDecoration(
                color: AppTheme.violet,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              height: 30,
              width: 2,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: AppTheme.outline,
            ),
            Container(
              height: 10,
              width: 10,
              decoration: BoxDecoration(
                color: AppTheme.success,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pickupName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: onChangeDrop,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        dropName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dummy fare + ETA quote.
class _FareCard extends StatelessWidget {
  const _FareCard({required this.estimate});

  final RideEstimate estimate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppTheme.violet.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_taxi_rounded,
              color: AppTheme.violet,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vybe Go',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${estimate.etaMinutes} min · '
                      '${Formatters.distance(estimate.distanceKm)}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.fare(estimate.fare),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (estimate.isSurging) ...[
                const SizedBox(height: 3),
                Text(
                  '${estimate.surgeMultiplier}x surge',
                  style: const TextStyle(color: AppTheme.amber, fontSize: 11.5),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
