import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../router/app_router.dart';
import '../../booking/bloc/booking_bloc.dart';

/// End of the flow: a receipt for the simulated trip plus a driver rating.
class TripCompletedScreen extends StatefulWidget {
  const TripCompletedScreen({super.key, required this.args});

  final TripSummaryArgs args;

  @override
  State<TripCompletedScreen> createState() => _TripCompletedScreenState();
}

class _TripCompletedScreenState extends State<TripCompletedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  int _rating = 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goHome() {
    // Clear the finished booking so Home comes back to a fresh "Where to?".
    context.read<BookingBloc>().add(const BookingReset());
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOutBack,
                  ),
                  child: Center(
                    child: Container(
                      height: 92,
                      width: 92,
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 50,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Trip completed',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have arrived at ${args.destination.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                _FareBreakdown(args: args),
                const SizedBox(height: 20),
                _RatingCard(
                  driverName: args.driver.name,
                  initials: args.driver.initials,
                  carNumber: args.driver.carNumber,
                  rating: _rating,
                  onRate: (value) => setState(() => _rating = value),
                ),
                const SizedBox(height: 28),
                LoadingButton(
                  label: 'Submit and go home',
                  icon: Icons.home_rounded,
                  onPressed: _goHome,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.history),
                  child: const Text('View ride history'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FareBreakdown extends StatelessWidget {
  const _FareBreakdown({required this.args});

  final TripSummaryArgs args;

  @override
  Widget build(BuildContext context) {
    final estimate = args.estimate;
    // The receipt is derived from the same dummy quote the rider accepted, so
    // the line items always add up to what they were shown before booking.
    final breakdown = estimate.breakdown;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          Text(
            Formatters.fare(estimate.fare),
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Total fare · Cash',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 14),
          _SummaryRow(
            icon: Icons.trip_origin_rounded,
            iconColor: AppTheme.violet,
            label: 'Pickup',
            value: args.pickup.name,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.flag_rounded,
            iconColor: AppTheme.success,
            label: 'Drop',
            value: args.destination.name,
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 14),
          _AmountRow(label: 'Base fare', value: breakdown.base),
          const SizedBox(height: 8),
          _AmountRow(
            label: 'Distance (${Formatters.distance(estimate.distanceKm)})',
            value: breakdown.distance,
          ),
          const SizedBox(height: 8),
          _AmountRow(
            label: 'Time (${estimate.etaMinutes} min)',
            value: breakdown.time,
          ),
          if (breakdown.surge > 0) ...[
            const SizedBox(height: 8),
            _AmountRow(
              label: 'Surge (${estimate.surgeMultiplier}x)',
              value: breakdown.surge,
              highlight: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final double value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: highlight ? AppTheme.amber : AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          Formatters.fare(value),
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: highlight ? AppTheme.amber : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.driverName,
    required this.initials,
    required this.carNumber,
    required this.rating,
    required this.onRate,
  });

  final String driverName;
  final String initials;
  final String carNumber;
  final int rating;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.violet, width: 1.8),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.violet,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate $driverName',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      carNumber,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                onPressed: () => onRate(value),
                icon: Icon(
                  value <= rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 34,
                  color: value <= rating
                      ? AppTheme.amber
                      : AppTheme.textSecondary,
                ),
                tooltip: '$value star${value == 1 ? '' : 's'}',
              );
            }),
          ),
        ],
      ),
    );
  }
}
