import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/location_repository.dart';
import 'data/repositories/ride_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/booking/bloc/booking_bloc.dart';
import 'router/app_router.dart';

/// Root widget.
///
/// Repositories are provided once at the top so every bloc below receives the
/// same instances (and the same in-memory dummy-data cache). [AuthBloc] and
/// [BookingBloc] live app-wide because the session and the in-progress booking
/// both outlive individual screens; tracking and history blocs are scoped to
/// their own routes.
class VybeCabsApp extends StatelessWidget {
  const VybeCabsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => RideRepository()),
        RepositoryProvider(create: (_) => const LocationRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthBloc(authRepository: context.read<AuthRepository>())
                  ..add(const AuthSubscriptionRequested()),
          ),
          BlocProvider(
            create: (context) => BookingBloc(
              rideRepository: context.read<RideRepository>(),
              locationRepository: context.read<LocationRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Vybe Cabs',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          navigatorKey: AppRouter.navigatorKey,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
          builder: (context, child) => _SessionGuard(child: child),
        ),
      ),
    );
  }
}

/// Sends the rider back to the login screen the moment the session ends,
/// wherever they happen to be in the app.
class _SessionGuard extends StatelessWidget {
  const _SessionGuard({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status == AuthStatus.authenticated &&
          current.status == AuthStatus.unauthenticated,
      listener: (context, state) => AppRouter.navigatorKey.currentState
          ?.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
