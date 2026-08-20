// Drives the whole rider flow on a real device/simulator so the screen can be
// recorded. This is a demo driver, not an assertion suite — the unit tests in
// test/ cover correctness. Pauses here are deliberate: they let a viewer read
// each screen before it moves on.
//
//   xcrun simctl privacy booted grant location com.vybecabs.rider
//   flutter test integration_test/demo_flow_test.dart -d <device-id>

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:full_ride_flow_task/firebase_options.dart';
import 'package:full_ride_flow_task/main.dart' as app;

/// Real-time pump. `pumpAndSettle` deadlocks here because the map, the radar
/// pulse and the 80ms tracking ticker never go idle.
Future<void> hold(WidgetTester tester, int ms) async {
  final deadline = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Pumps until [finder] matches, or throws after [timeoutMs].
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  int timeoutMs = 30000,
  String? label,
}) async {
  final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 16));
    if (finder.evaluate().isNotEmpty) return;
  }
  // Dump what is actually on screen — far quicker to diagnose than a bare
  // timeout when driving a real device.
  final visible = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .toList();
  throw StateError(
    'Timed out waiting for ${label ?? finder.toString()}.\n'
    'Visible text was: $visible',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Firebase persists the session in the keychain, so a second run would boot
  // straight to Home and skip the login screen. Clear it before the app starts
  // so the recording always opens on login.
  setUpAll(() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }
    await FirebaseAuth.instance.signOut();
  });

  testWidgets('full rider flow, paced for recording', (tester) async {
    app.main();
    await hold(tester, 1000);

    // ---- Splash -> Login -------------------------------------------------
    await waitFor(tester, find.text('Welcome back'), label: 'login screen');
    await hold(tester, 4000);

    // ---- Log in ----------------------------------------------------------
    final email = find.byType(TextFormField).first;
    final password = find.byType(TextFormField).last;

    await tester.enterText(email, 'rider@vybecabs.com');
    await hold(tester, 1800);
    await tester.enterText(password, 'vybe123456');
    await hold(tester, 1800);

    // Dismiss the keyboard so the button is not covered.
    FocusManager.instance.primaryFocus?.unfocus();
    await hold(tester, 1400);

    await tester.tap(find.text('Log in'));
    await hold(tester, 500);

    // ---- Home ------------------------------------------------------------
    await waitFor(tester, find.text('Where to?'),
        label: 'home screen', timeoutMs: 40000);

    // The search bar renders immediately but its onTap stays null until the
    // GPS fix resolves (up to a 10s timeout), so wait for the chevron that
    // replaces the panel's spinner before tapping.
    await waitFor(tester, find.byIcon(Icons.chevron_right_rounded),
        label: 'booking panel ready', timeoutMs: 30000);
    await hold(tester, 9000); // let the map draw and the pin settle

    // ---- Pick a destination ---------------------------------------------
    await tester.tap(find.text('Where to?'));
    await hold(tester, 3200); // sheet slides up

    const destination = 'Indiranagar 100 Feet Road';
    await waitFor(tester, find.text(destination), label: 'destination sheet');
    await hold(tester, 4500);
    await tester.tap(find.text(destination));
    await hold(tester, 10000); // fare quote + route render

    // ---- Book ------------------------------------------------------------
    await waitFor(tester, find.text('Book Ride'), label: 'Book Ride button');
    await tester.tap(find.text('Book Ride'));
    await hold(tester, 1500);

    // ---- Finding a driver (3-5s of radar) --------------------------------
    await hold(tester, 5500);

    // ---- Live tracking ---------------------------------------------------
    // ~15s approach, ~4s arrived pause, ~22s trip. Hold past all of it and
    // let the completion screen appear on its own.
    await waitFor(tester, find.text('Trip completed'),
        label: 'trip completed screen', timeoutMs: 90000);
    await hold(tester, 11000); // read the receipt

    // ---- Rate the driver -------------------------------------------------
    final stars = find.byIcon(Icons.star_rounded);
    if (stars.evaluate().isNotEmpty) {
      await tester.tap(stars.at(stars.evaluate().length - 1));
      await hold(tester, 3200);
    }

    // ---- Ride history ----------------------------------------------------
    await waitFor(tester, find.text('View ride history'),
        label: 'history button');
    // The button sits below the fold on the completion screen. tap() only
    // *warns* when the hit test misses, so without this the tap silently does
    // nothing and the run still passes.
    await tester.ensureVisible(find.text('View ride history'));
    await hold(tester, 1500);
    await tester.tap(find.text('View ride history'));
    await hold(tester, 1000);

    // Assert we actually landed, rather than trusting a tap that may have missed.
    await waitFor(tester, find.text('Your rides'), label: 'ride history screen');
    await hold(tester, 6000);

    // Scroll the list so more than the first card is visible.
    final list = find.byType(ListView);
    if (list.evaluate().isNotEmpty) {
      await tester.drag(list.first, const Offset(0, -240));
      await hold(tester, 4000);
      await tester.drag(list.first, const Offset(0, -240));
      await hold(tester, 4000);
      await tester.drag(list.first, const Offset(0, 480));
      await hold(tester, 3500);
    }

    await hold(tester, 6000);
  }, timeout: const Timeout(Duration(minutes: 6)));
}
