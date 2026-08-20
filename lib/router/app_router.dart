import 'package:flutter/material.dart';

import '../data/models/driver.dart';
import '../data/models/place.dart';
import '../data/models/ride_estimate.dart';
import '../features/auth/view/login_screen.dart';
import '../features/booking/view/finding_driver_screen.dart';
import '../features/booking/view/home_screen.dart';
import '../features/history/view/ride_history_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/tracking/view/live_tracking_screen.dart';
import '../features/tracking/view/trip_completed_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String findingDriver = '/finding-driver';
  static const String tracking = '/tracking';
  static const String tripCompleted = '/trip-completed';
  static const String history = '/history';
}

/// Everything the live tracking screen needs to run the simulation.
class TrackingArgs {
  const TrackingArgs({
    required this.driver,
    required this.pickup,
    required this.destination,
    required this.estimate,
  });

  final Driver driver;
  final Place pickup;
  final Place destination;
  final RideEstimate estimate;
}

/// Receipt data for the completion screen.
class TripSummaryArgs {
  const TripSummaryArgs({
    required this.driver,
    required this.pickup,
    required this.destination,
    required this.estimate,
  });

  final Driver driver;
  final Place pickup;
  final Place destination;
  final RideEstimate estimate;
}

class AppRouter {
  const AppRouter._();

  /// Lets the session guard in `app.dart` navigate without a BuildContext.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _fade(const SplashScreen(), settings);
      case AppRoutes.login:
        return _fade(const LoginScreen(), settings);
      case AppRoutes.home:
        return _fade(const HomeScreen(), settings);
      case AppRoutes.findingDriver:
        return _slideUp(const FindingDriverScreen(), settings);
      case AppRoutes.tracking:
        final args = settings.arguments as TrackingArgs;
        return _slideUp(LiveTrackingScreen(args: args), settings);
      case AppRoutes.tripCompleted:
        final args = settings.arguments as TripSummaryArgs;
        return _fade(TripCompletedScreen(args: args), settings);
      case AppRoutes.history:
        return MaterialPageRoute(
          builder: (_) => const RideHistoryScreen(),
          settings: settings,
        );
      default:
        return _fade(const SplashScreen(), settings);
    }
  }

  static Route<dynamic> _fade(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  static Route<dynamic> _slideUp(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
