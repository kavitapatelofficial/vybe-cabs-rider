import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Firebase is the one real backend in this app. If it is not configured yet
  // we show a setup screen rather than crashing on a red screen, so the app is
  // still runnable straight after cloning.
  String? bootstrapError;
  try {
    if (DefaultFirebaseOptions.isPlaceholder) {
      bootstrapError =
          'Firebase is not configured yet.\n\nRun `flutterfire configure` in '
          'the project root to generate lib/firebase_options.dart and '
          'android/app/google-services.json, then restart the app.';
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    bootstrapError = 'Could not start Firebase.\n\n$e';
  }

  runApp(
    bootstrapError == null
        ? const VybeCabsApp()
        : BootstrapErrorApp(message: bootstrapError),
  );
}

/// Shown only when Firebase credentials are missing or invalid.
class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vybe Cabs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.settings_suggest_rounded,
                  size: 60,
                  color: AppTheme.amber,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Setup required',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.5,
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
