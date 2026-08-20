import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/map_style.dart';
import '../../../core/utils/marker_factory.dart';
import '../../../core/utils/route_animator.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../data/models/place.dart';
import '../../../router/app_router.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/booking_bloc.dart';
import 'widgets/booking_panel.dart';
import 'widgets/destination_sheet.dart';

/// Map + "Where to?" + fare quote + Book Ride.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _mapController = Completer();

  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropIcon;
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _loadMapAssets();

    final bloc = context.read<BookingBloc>();
    // Only bootstrap once; coming back from a finished trip keeps the state.
    if (bloc.state.status == BookingStatus.initial) {
      bloc.add(const BookingStarted());
    } else {
      bloc.add(const BookingReset());
    }
  }

  Future<void> _loadMapAssets() async {
    final pickup = await MarkerFactory.pickupPin();
    final drop = await MarkerFactory.dropPin();
    final style = await MapStyle.dark();
    if (!mounted) return;
    setState(() {
      _pickupIcon = pickup;
      _dropIcon = drop;
      _mapStyle = style;
    });
  }

  Future<void> _openDestinationSheet() async {
    final bloc = context.read<BookingBloc>();
    final destinations = bloc.state.destinations;
    if (destinations.isEmpty) return;

    final selected = await DestinationSheet.show(
      context,
      destinations: destinations,
    );
    if (selected == null) return;
    bloc.add(BookingDestinationSelected(selected));
  }

  /// Frames the whole trip route once a destination is chosen, and re-centres
  /// on the rider when it is cleared.
  Future<void> _fitCamera(BookingState state) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;

    final destination = state.selectedDestination;
    if (destination == null) {
      final position = state.riderPosition;
      if (position == null) return;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(position, 15),
      );
      return;
    }

    final points = destination.tripWaypoints.isNotEmpty
        ? destination.tripWaypoints
        : [state.riderPosition ?? destination.position, destination.position];
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(RouteAnimator.boundsOf(points), 70),
    );
  }

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to book a ride.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener<BookingBloc, BookingState>(
            listenWhen: (previous, current) =>
                previous.selectedDestination != current.selectedDestination ||
                previous.riderPosition != current.riderPosition,
            listener: (context, state) => _fitCamera(state),
          ),
          BlocListener<BookingBloc, BookingState>(
            listenWhen: (previous, current) =>
                previous.status != current.status &&
                current.status == BookingStatus.searchingDriver,
            listener: (context, state) =>
                Navigator.of(context).pushNamed(AppRoutes.findingDriver),
          ),
        ],
        child: BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            return Stack(
              children: [
                _buildMap(state),
                // Scoped to the greeting name so the bar only rebuilds when
                // that changes. It has to be a widget rather than a
                // `context.select` inside _buildTopBar: that call would run
                // against this State's context, which is not the element
                // being built here.
                BlocSelector<AuthBloc, AuthState, String>(
                  selector: (authState) =>
                      authState.user?.greetingName ?? 'there',
                  builder: (context, name) => _buildTopBar(state, name),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: BookingPanel(
                    pickup: state.pickup,
                    destination: state.selectedDestination,
                    estimate: state.estimate,
                    isLoading: state.status == BookingStatus.loading,
                    onSearchTapped: _openDestinationSheet,
                    onClearDestination: () => context.read<BookingBloc>().add(
                      const BookingDestinationCleared(),
                    ),
                    onBookRide: () => context.read<BookingBloc>().add(
                      const BookingRideRequested(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMap(BookingState state) {
    final center = state.riderPosition ?? const LatLng(12.9756, 77.6068);

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: center, zoom: 15),
      style: _mapStyle,
      onMapCreated: (controller) {
        if (!_mapController.isCompleted) _mapController.complete(controller);
        _fitCamera(state);
      },
      myLocationEnabled: state.isLiveLocation,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      // Keeps the Google logo and controls clear of the bottom panel.
      padding: const EdgeInsets.only(bottom: 260),
      markers: _buildMarkers(state),
      polylines: _buildPolylines(state),
    );
  }

  Set<Marker> _buildMarkers(BookingState state) {
    final markers = <Marker>{};
    final pickupPosition = state.riderPosition ?? state.pickup?.position;

    if (pickupPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupPosition,
          icon: _pickupIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: state.pickup?.name ?? 'Current location',
          ),
        ),
      );
    }

    final destination = state.selectedDestination;
    if (destination != null) {
      markers.add(
        Marker(
          markerId: MarkerId(destination.id),
          position: destination.position,
          icon: _dropIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: 'Drop',
            snippet: destination.name,
          ),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _buildPolylines(BookingState state) {
    final Place? destination = state.selectedDestination;
    if (destination == null || destination.tripWaypoints.isEmpty) return {};

    return {
      Polyline(
        polylineId: PolylineId('route_${destination.id}'),
        points: RouteAnimator.densify(destination.tripWaypoints),
        color: AppTheme.violet,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Widget _buildTopBar(BookingState state, String name) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _GlassCard(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.violet,
                          child: Icon(
                            Icons.person_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Hi, $name',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                state.isLiveLocation
                                    ? 'Using your current location'
                                    : 'Using default pickup point',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _confirmLogout,
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          color: AppTheme.textSecondary,
                          tooltip: 'Log out',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _GlassCard(
                  padding: EdgeInsets.zero,
                  child: IconButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.history),
                    icon: const Icon(Icons.receipt_long_rounded),
                    tooltip: 'Ride history',
                  ),
                ),
              ],
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 10),
              InfoBanner(message: state.errorMessage!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Translucent rounded container used for the floating controls over the map.
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}
