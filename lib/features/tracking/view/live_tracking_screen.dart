import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/map_style.dart';
import '../../../core/utils/marker_factory.dart';
import '../../../core/utils/route_animator.dart';
import '../../../router/app_router.dart';
import '../bloc/tracking_bloc.dart';
import 'widgets/driver_card.dart';

/// Live ride simulation: the car marker drives the hardcoded approach path to
/// the pickup pin, holds for the "Driver Arrived" beat, then drives the trip
/// path to the drop and finishes on the completion screen.
class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key, required this.args});

  final TrackingArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrackingBloc()
        ..add(
          TrackingStarted(
            driver: args.driver,
            pickup: args.pickup,
            destination: args.destination,
            estimate: args.estimate,
          ),
        ),
      child: _LiveTrackingView(args: args),
    );
  }
}

class _LiveTrackingView extends StatefulWidget {
  const _LiveTrackingView({required this.args});

  final TrackingArgs args;

  @override
  State<_LiveTrackingView> createState() => _LiveTrackingViewState();
}

class _LiveTrackingViewState extends State<_LiveTrackingView> {
  final Completer<GoogleMapController> _mapController = Completer();

  BitmapDescriptor? _carIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropIcon;
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _loadMapAssets();
  }

  Future<void> _loadMapAssets() async {
    final car = await MarkerFactory.car();
    final pickup = await MarkerFactory.pickupPin();
    final drop = await MarkerFactory.dropPin();
    final style = await MapStyle.dark();
    if (!mounted) return;
    setState(() {
      _carIcon = car;
      _pickupIcon = pickup;
      _dropIcon = drop;
      _mapStyle = style;
    });
  }

  /// Frames the leg that is about to be driven. Called on phase changes only —
  /// moving the camera on every animation frame would fight the user's own
  /// pan/zoom and look jittery.
  Future<void> _fitLeg(TrackingState state) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;

    final points = <LatLng>[
      ...state.routeAhead,
      ...state.routeBehind,
      if (state.carPosition != null) state.carPosition!,
    ];
    if (points.isEmpty) return;

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(RouteAnimator.boundsOf(points), 80),
    );
  }

  Future<void> _recenterOnCar(TrackingState state) async {
    final car = state.carPosition;
    if (car == null || !_mapController.isCompleted) return;
    final controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.newLatLngZoom(car, 16.5));
  }

  void _confirmCancel() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Cancel this ride?'),
        content: const Text(
          'Your driver is on the way. Frequent cancellations may affect your '
          'account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep ride'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<TrackingBloc>().add(const TrackingCancelled());
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.home,
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Cancel ride'),
          ),
        ],
      ),
    );
  }

  void _openSummary() {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.tripCompleted,
      arguments: TripSummaryArgs(
        driver: widget.args.driver,
        pickup: widget.args.pickup,
        destination: widget.args.destination,
        estimate: widget.args.estimate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The ride is in progress — back should ask, not silently abandon it.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmCancel();
      },
      child: Scaffold(
        body: BlocConsumer<TrackingBloc, TrackingState>(
          listenWhen: (previous, current) => previous.phase != current.phase,
          listener: (context, state) {
            if (state.phase == TrackingPhase.tripCompleted) {
              _openSummary();
            } else {
              _fitLeg(state);
            }
          },
          builder: (context, state) {
            final driver = state.driver;
            return Stack(
              children: [
                _buildMap(state),
                _buildStatusBanner(state),
                Positioned(
                  right: 16,
                  bottom: MediaQuery.of(context).size.height * 0.34,
                  child: _RecenterButton(
                    onPressed: () => _recenterOnCar(state),
                  ),
                ),
                if (driver != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: DriverCard(
                      driver: driver,
                      phase: state.phase,
                      etaSeconds: state.etaSeconds,
                      progress: state.progress,
                      onCancel: _confirmCancel,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMap(TrackingState state) {
    final initial =
        state.carPosition ??
        widget.args.pickup.position;

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: initial, zoom: 15.5),
      style: _mapStyle,
      onMapCreated: (controller) {
        if (!_mapController.isCompleted) _mapController.complete(controller);
        _fitLeg(state);
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      padding: const EdgeInsets.only(bottom: 240),
      markers: _buildMarkers(state),
      polylines: _buildPolylines(state),
    );
  }

  Set<Marker> _buildMarkers(TrackingState state) {
    final markers = <Marker>{};

    final pickup = state.pickup;
    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup.position,
          icon: _pickupIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(title: 'Pickup', snippet: pickup.name),
        ),
      );
    }

    // The drop pin only matters once the trip itself has started.
    final destination = state.destination;
    if (destination != null &&
        (state.phase == TrackingPhase.onTrip ||
            state.phase == TrackingPhase.tripCompleted)) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: destination.position,
          icon: _dropIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(title: 'Drop', snippet: destination.name),
        ),
      );
    }

    final car = state.carPosition;
    if (car != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('car'),
          position: car,
          icon: _carIcon ?? BitmapDescriptor.defaultMarker,
          rotation: state.carBearing,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndexInt: 2,
        ),
      );
    }
    return markers;
  }

  /// Two polylines: the road still to drive in violet, the part already
  /// covered dimmed out behind the car.
  Set<Polyline> _buildPolylines(TrackingState state) {
    final polylines = <Polyline>{};

    if (state.routeBehind.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('covered'),
          points: state.routeBehind,
          color: AppTheme.outline,
          width: 5,
        ),
      );
    }
    if (state.routeAhead.length > 1) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('remaining'),
          points: state.routeAhead,
          color: state.phase == TrackingPhase.onTrip
              ? AppTheme.success
              : AppTheme.violet,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }
    return polylines;
  }

  Widget _buildStatusBanner(TrackingState state) {
    final isArrived = state.phase == TrackingPhase.driverArrived;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: Container(
            key: ValueKey(state.phase),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: (isArrived ? AppTheme.success : AppTheme.surface)
                  .withValues(alpha: isArrived ? 0.95 : 0.94),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.outline),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isArrived
                      ? Icons.check_circle_rounded
                      : Icons.directions_car_rounded,
                  color: isArrived ? Colors.white : AppTheme.violet,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.headline,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: isArrived
                              ? Colors.white
                              : AppTheme.textPrimary,
                        ),
                      ),
                      if (state.subline.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          state.subline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isArrived
                                ? Colors.white70
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      shape: const CircleBorder(
        side: BorderSide(color: AppTheme.outline),
      ),
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.my_location_rounded, size: 22),
        ),
      ),
    );
  }
}
