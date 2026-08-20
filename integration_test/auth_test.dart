// Exercises the real Firebase auth paths against the live project, so the
// same run can be repeated in debug and in release. Release is what matters
// here: a debug pass proves nothing about a shrunk, signed build.
//
//   flutter test integration_test/auth_test.dart -d <device>          # debug
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/auth_test.dart --release -d <device>  # release
//
// Each run signs up a throwaway account and deletes it at the end so the
// project's user list does not fill up.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:full_ride_flow_task/firebase_options.dart';
import 'package:full_ride_flow_task/main.dart' as app;

Future<void> hold(WidgetTester tester, int ms) async {
  final deadline = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  int timeoutMs = 40000,
  String? label,
}) async {
  final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 16));
    if (finder.evaluate().isNotEmpty) return;
  }
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

/// Taps and asserts the hit test landed — `tester.tap` only warns on a miss,
/// which silently turns a broken flow into a passing test.
Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  expect(finder, findsWidgets, reason: 'no widget with text "$text"');
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(finder.first, warnIfMissed: true);
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // A fresh address per run keeps signup deterministic.
  final unique = DateTime.now().millisecondsSinceEpoch;
  final email = 'ci.rider.$unique@vybecabs.com';
  const password = 'vybe123456';

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

  tearDownAll(() async {
    // Remove the throwaway account. Best-effort: never fail the run on cleanup.
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (_) {
      // ignore
    }
  });

  testWidgets('sign up, log out, log back in', (tester) async {
    app.main();
    await hold(tester, 1500);

    // ---- Sign up ---------------------------------------------------------
    await waitFor(tester, find.text('Welcome back'), label: 'login screen');
    await tapText(tester, 'Create one');
    await hold(tester, 1200);

    // Sign-up mode adds the name field ahead of email and password.
    var fields = find.byType(TextFormField);
    expect(
      tester.widgetList(fields).length,
      3,
      reason: 'sign-up should show name, email and password',
    );

    await tester.enterText(fields.at(0), 'Kavita');
    await tester.enterText(fields.at(1), email);
    await tester.enterText(fields.at(2), password);
    FocusManager.instance.primaryFocus?.unfocus();
    await hold(tester, 800);

    await tapText(tester, 'Create account');

    // Landing on Home is the proof the account was really created.
    await waitFor(tester, find.text('Where to?'),
        label: 'home after sign-up', timeoutMs: 60000);
    expect(FirebaseAuth.instance.currentUser, isNotNull);
    expect(FirebaseAuth.instance.currentUser!.email, email);
    await hold(tester, 1500);

    // The greeting must show the name given at sign-up, not the email prefix.
    // authStateChanges() fires before updateDisplayName lands and never fires
    // again for a profile edit, so this regressed once already.
    // Asserted on the UI, not on FirebaseAuth.currentUser.displayName: the SDK
    // does not read that value back straight after updateDisplayName. What
    // matters is that the rider sees their name.
    await waitFor(tester, find.text('Hi, Kavita'),
        label: 'greeting using the sign-up display name', timeoutMs: 15000);

    // ---- Log out ---------------------------------------------------------
    await tester.tap(find.byIcon(Icons.logout_rounded));
    await hold(tester, 1000);
    await tapText(tester, 'Log out');

    await waitFor(tester, find.text('Welcome back'),
        label: 'login screen after logout');
    expect(FirebaseAuth.instance.currentUser, isNull);
    await hold(tester, 1200);

    // ---- Log back in -----------------------------------------------------
    fields = find.byType(TextFormField);
    expect(
      tester.widgetList(fields).length,
      2,
      reason: 'login mode should show only email and password',
    );

    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), password);
    FocusManager.instance.primaryFocus?.unfocus();
    await hold(tester, 800);

    await tapText(tester, 'Log in');

    await waitFor(tester, find.text('Where to?'),
        label: 'home after log-in', timeoutMs: 60000);
    expect(FirebaseAuth.instance.currentUser, isNotNull);
    await hold(tester, 1500);
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('wrong password shows a readable error, not a raw code',
      (tester) async {
    await FirebaseAuth.instance.signOut();
    app.main();
    await hold(tester, 1500);

    await waitFor(tester, find.text('Welcome back'), label: 'login screen');

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), 'definitely-not-the-password');
    FocusManager.instance.primaryFocus?.unfocus();
    await hold(tester, 600);

    await tapText(tester, 'Log in');
    await hold(tester, 6000);

    // Still on the login screen, and no Firebase error code leaked to the UI.
    expect(find.text('Where to?'), findsNothing);
    final shown = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .join(' | ');
    expect(shown, isNot(contains('firebase_auth')));
    expect(shown, isNot(contains('INVALID_LOGIN')));
    expect(shown, isNot(contains('wrong-password')));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
