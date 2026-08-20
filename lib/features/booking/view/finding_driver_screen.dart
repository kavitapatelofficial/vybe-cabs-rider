import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../data/models/driver.dart';
import '../../../router/app_router.dart';
import '../bloc/booking_bloc.dart';

/// Simulated dispatch: a radar animation for 3-5 seconds, then the assigned
/// driver from the dummy dataset.
class FindingDriverScreen extends StatefulWidget {
  const FindingDriverScreen({super.key});

  @override
  State<FindingDriverScreen> createState() => _FindingDriverScreenState();
}

class _FindingDriverScreenState extends State<FindingDriverScreen> {
  /// How long the driver card is shown before tracking opens automatically.
  static const Duration _handoffDelay = Duration(milliseconds: 2600);

  Timer? _handoffTimer;

  @override
  void dispose() {
    _handoffTimer?.cancel();
    super.dispose();
  }

  void _scheduleHandoff(BookingState state) {
    if (_handoffTimer != null) return;
    _handoffTimer = Timer(_handoffDelay, () => _openTracking(state));
  }

  void _openTracking(BookingState state) {
    _handoffTimer?.cancel();
    _handoffTimer = null;

    final driver = state.driver;
    final pickup = state.pickup;
    final destination = state.selectedDestination;
    final estimate = state.estimate;
    if (driver == null ||
        pickup == null ||
        destination == null ||
        estimate == null) {
      return;
    }
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      AppRoutes.tracking,
      arguments: TrackingArgs(
        driver: driver,
        pickup: pickup,
        destination: destination,
        estimate: estimate,
      ),
    );
  }

  void _cancelSearch() {
    _handoffTimer?.cancel();
    context.read<BookingBloc>().add(const BookingSearchCancelled());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelSearch();
      },
      child: Scaffold(
        body: BlocConsumer<BookingBloc, BookingState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: (context, state) {
            if (state.status == BookingStatus.driverAssigned) {
              _scheduleHandoff(state);
            } else if (state.status == BookingStatus.ready &&
                state.errorMessage != null) {
              // Dispatch failed — drop back to Home with the message showing.
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            final driver = state.driver;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _cancelSearch,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Cancel',
                      ),
                    ),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      child: driver == null
                          ? const _SearchingView()
                          : _DriverFoundView(
                              key: ValueKey(driver.id),
                              driver: driver,
                            ),
                    ),
                    const Spacer(),
                    if (state.selectedDestination != null)
                      _TripLine(
                        pickup: state.pickup?.name ?? 'Current location',
                        drop: state.selectedDestination!.name,
                        fare: state.estimate?.fare,
                      ),
                    const SizedBox(height: 20),
                    if (driver == null)
                      OutlinedButton(
                        onPressed: _cancelSearch,
                        child: const Text('Cancel search'),
                      )
                    else
                      LoadingButton(
                        label: 'Track your ride',
                        icon: Icons.navigation_rounded,
                        onPressed: () => _openTracking(state),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Pulsing radar rings while dispatch runs.
class _SearchingView extends StatefulWidget {
  const _SearchingView();

  @override
  State<_SearchingView> createState() => _SearchingViewState();
}

class _SearchingViewState extends State<_SearchingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('searching'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
          width: 220,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Three rings, evenly offset in time, expanding and fading.
                  for (var i = 0; i < 3; i++)
                    _Ring(progress: (_controller.value + i / 3) % 1),
                  child!,
                ],
              );
            },
            child: Container(
              height: 84,
              width: 84,
              decoration: const BoxDecoration(
                color: AppTheme.violet,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_taxi_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
        ),
        const SizedBox(height: 36),
        const Text(
          'Finding your driver',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Connecting you with nearby Vybe drivers…',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final size = 84 + (progress * 136);
    return Opacity(
      opacity: (1 - progress).clamp(0.0, 1.0) * 0.5,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.violet, width: 1.6),
        ),
      ),
    );
  }
}

/// The assigned driver, straight from `assets/data/drivers.json`.
class _DriverFoundView extends StatelessWidget {
  const _DriverFoundView({super.key, required this.driver});

  final Driver driver;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppTheme.success,
              ),
              SizedBox(width: 7),
              Text(
                'Driver assigned',
                style: TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        // Placeholder avatar: the dummy dataset ships no photos, so we render
        // the driver's initials instead of a broken image.
        Container(
          height: 104,
          width: 104,
          decoration: BoxDecoration(
            color: AppTheme.surfaceHigh,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.violet, width: 2.5),
          ),
          alignment: Alignment.center,
          child: Text(
            driver.initials,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppTheme.violet,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          driver.name,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_rounded, color: AppTheme.amber, size: 18),
            const SizedBox(width: 4),
            Text(
              '${driver.rating}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Text(
              '· ${driver.totalTrips} trips',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Column(
            children: [
              Text(
                driver.carNumber,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                driver.carLabel,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripLine extends StatelessWidget {
  const _TripLine({
    required this.pickup,
    required this.drop,
    required this.fare,
  });

  final String pickup;
  final String drop;
  final double? fare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pickup,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_downward_rounded,
                      size: 14,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        drop,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (fare != null) ...[
            const SizedBox(width: 12),
            Text(
              Formatters.fare(fare!),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ],
      ),
    );
  }
}
