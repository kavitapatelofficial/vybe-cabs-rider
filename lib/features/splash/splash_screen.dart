import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/vybe_logo.dart';
import '../../router/app_router.dart';
import '../auth/bloc/auth_bloc.dart';

/// Brand screen that holds until Firebase reports whether a session exists,
/// then routes to Home (auto-login) or Login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Minimum time the logo stays up, so a fast auth check does not produce a
  /// jarring one-frame flash of the splash screen.
  static const Duration _minimumDisplay = Duration(milliseconds: 1600);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Future<void> _minimumDisplayElapsed = Future<void>.delayed(
    _minimumDisplay,
  );

  bool _navigated = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _routeFor(AuthStatus status) async {
    if (_navigated || status == AuthStatus.unknown) return;
    _navigated = true;

    await _minimumDisplayElapsed;
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      status == AuthStatus.authenticated ? AppRoutes.home : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) => _routeFor(state.status),
      child: Scaffold(
        body: Builder(
          builder: (context) {
            // Covers the case where the status is already known on first build.
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _routeFor(context.read<AuthBloc>().state.status),
            );

            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [Color(0xFF1B1533), AppTheme.background],
                ),
              ),
              child: Center(
                child: FadeTransition(
                  opacity: _controller,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VybeLogo(size: 96),
                        SizedBox(height: 44),
                        SizedBox(
                          height: 26,
                          width: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
