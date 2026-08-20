import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../data/models/ride_history_entry.dart';
import '../../../data/repositories/ride_repository.dart';
import '../cubit/history_cubit.dart';

/// Past rides, rendered from `assets/data/ride_history.json`.
class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          HistoryCubit(rideRepository: context.read<RideRepository>())..load(),
      child: const _RideHistoryView(),
    );
  }
}

class _RideHistoryView extends StatelessWidget {
  const _RideHistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your rides')),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          return switch (state.status) {
            HistoryStatus.initial ||
            HistoryStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            HistoryStatus.failure => Padding(
              padding: const EdgeInsets.all(24),
              child: InfoBanner(
                message: state.errorMessage ?? 'Something went wrong.',
              ),
            ),
            HistoryStatus.loaded => _HistoryList(state: state),
          };
        },
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.state});

  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    if (state.rides.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No rides yet.\nYour completed trips will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.violet,
      backgroundColor: AppTheme.surface,
      onRefresh: () => context.read<HistoryCubit>().load(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        itemCount: state.rides.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) return _SummaryHeader(state: state);
          return _RideTile(ride: state.rides[index - 1]);
        },
      ),
    );
  }
}

/// Lifetime totals across the dummy history.
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.state});

  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              label: 'Completed rides',
              value: '${state.completedCount}',
              icon: Icons.check_circle_rounded,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              label: 'Total spent',
              value: Formatters.fare(state.totalSpend),
              icon: Icons.account_balance_wallet_rounded,
              color: AppTheme.violet,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RideTile extends StatelessWidget {
  const _RideTile({required this.ride});

  final RideHistoryEntry ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  Formatters.historyDate(ride.date),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ),
              _StatusChip(isCancelled: ride.isCancelled),
            ],
          ),
          const SizedBox(height: 14),
          _RouteColumn(pickup: ride.pickup, drop: ride.drop),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.driverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ride.carNumber} · '
                      '${Formatters.distance(ride.distanceKm)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.fare(ride.fare),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      // A cancelled ride was never charged — strike the amount
                      // through rather than hiding it.
                      decoration: ride.isCancelled
                          ? TextDecoration.lineThrough
                          : null,
                      color: ride.isCancelled
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                    ),
                  ),
                  if (!ride.isCancelled && ride.rating > 0) ...[
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: AppTheme.amber,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${ride.rating}.0',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isCancelled});

  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final color = isCancelled ? AppTheme.danger : AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isCancelled ? 'Cancelled' : 'Completed',
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RouteColumn extends StatelessWidget {
  const _RouteColumn({required this.pickup, required this.drop});

  final String pickup;
  final String drop;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: 5),
            Container(
              height: 9,
              width: 9,
              decoration: const BoxDecoration(
                color: AppTheme.violet,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              height: 24,
              width: 2,
              margin: const EdgeInsets.symmetric(vertical: 3),
              color: AppTheme.outline,
            ),
            Container(
              height: 9,
              width: 9,
              decoration: BoxDecoration(
                color: AppTheme.success,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pickup,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.3),
              ),
              const SizedBox(height: 15),
              Text(
                drop,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
