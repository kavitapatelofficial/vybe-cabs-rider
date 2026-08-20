# Vybe Cabs — Rider App

Full rider-side ride flow built for the Vybe Cabs Flutter assignment: splash →
login → home → finding driver → live tracking → trip completed → ride history.

Firebase Authentication is real. Everything else (places, drivers, routes, ride
history) is local dummy data, structured so it can be swapped for real APIs
without touching the UI or the state layer.

---

## Setup

The repo builds as-is, but the map is blank and login is disabled until you add
your own Firebase project and Google Maps key. Both are free.

### 1. Firebase (required for login)

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Pick or create a Firebase project and select **Android** (and iOS if you need
it). The Android application id is `com.vybecabs.rider`. This overwrites
`lib/firebase_options.dart` with your real keys.

Then in the Firebase console: **Authentication → Sign-in method → Email/Password
→ Enable**.

Until this is done the app shows a "Setup required" screen instead of crashing —
see `DefaultFirebaseOptions.isPlaceholder` in
[`lib/firebase_options.dart`](lib/firebase_options.dart).

### 2. Google Maps (required for the map)

Create an API key in the Google Cloud console with **Maps SDK for Android**
enabled, then add it to `android/local.properties` (git-ignored):

```properties
MAPS_API_KEY=AIza...your-key
```

`android/app/build.gradle.kts` reads it and injects it into the manifest as a
placeholder, so the key never enters version control. For iOS, replace
`REPLACE_ME_IOS_MAPS_API_KEY` in `ios/Runner/AppDelegate.swift`.

### 3. Run

```bash
flutter pub get
flutter run
flutter test          # 26 unit tests, no device needed
flutter build apk --release
```

Minimum Android SDK is 23 (required by `firebase_auth`).

---

## Auth method: email + password

The spec allowed either phone OTP or email/password. **This app uses Firebase
email + password**, for two reasons:

- Phone OTP needs SHA-1/SHA-256 fingerprints registered per machine, Play
  Integrity configuration, and a real device or whitelisted test number —
  meaning a reviewer cloning the repo often cannot log in at all.
- Email/password works the moment the Firebase project exists, so anyone can
  create an account from the app itself and see the whole flow.

The login screen doubles as sign-up (toggle at the bottom), with:

- inline validation (email format, 6-character minimum password),
- a spinner on the button and blocked double-submits while the request is in
  flight,
- Firebase error codes translated to human copy — `wrong-password`,
  `email-already-in-use`, `network-request-failed` and friends are mapped in
  `AuthRepository._messageFor`, never shown raw.

**Session persistence** is Firebase's own: `authStateChanges` is the single
source of truth, so a returning user is signed straight into Home from the
splash screen with no extra storage layer. Logging out anywhere in the app pops
back to login via a listener in [`lib/app.dart`](lib/app.dart).

---

## State management: Bloc

`flutter_bloc` throughout, one bloc per area of responsibility:

| Bloc | Scope | Owns |
|---|---|---|
| `AuthBloc` | app-wide | session, login/sign-up submission, auth errors |
| `BookingBloc` | app-wide | GPS fix, dummy places, selected drop, fare quote, simulated dispatch |
| `TrackingBloc` | tracking route | the ride simulation and its phase machine |
| `HistoryCubit` | history route | loading past rides |

Auth and booking are provided above the navigator because a session and an
in-progress booking both outlive any single screen. Tracking and history are
scoped to their routes so their timers and state die with the screen.

`HistoryCubit` is a Cubit rather than a Bloc on purpose: that screen only ever
loads a list, so events would be ceremony. It is still the same family, so the
app stays consistent.

Each bloc exposes **one state class with an enum status** rather than a sealed
hierarchy of states. With a flow this linear it keeps `copyWith` transitions
cheap and lets widgets use `buildWhen` on individual fields.

### Architecture

```
lib/
├── core/            theme, formatters, validators, map + route utilities
├── data/
│   ├── models/      Place, Driver, RideEstimate, RideHistoryEntry
│   └── repositories/ AuthRepository, RideRepository, LocationRepository
├── features/        splash, auth, booking, tracking, history
│   └── <feature>/   bloc/ + view/ (+ view/widgets/)
└── router/          named routes and typed route arguments
```

Widgets never import `firebase_auth`, never decode JSON, and never touch
`geolocator`. Repositories are the only layer that knows where data comes from,
and they return domain models. **`RideRepository` is the single seam holding all
the dummy data** — pointing the app at a real backend means reimplementing four
methods against HTTP, with no caller changes.

---

## How the dummy data is structured

Three JSON files in `assets/data/`, loaded through `RideRepository` and parsed
into models via `fromJson`, exactly as an HTTP response would be.

### `places.json`

One `pickup` object plus five `destinations`. Each destination carries its own
dummy metrics and, importantly, its **`tripWaypoints`** — the hardcoded lat-lng
path from the pickup point to that drop:

```jsonc
{
  "id": "dst_indiranagar",
  "name": "Indiranagar 100 Feet Road",
  "address": "HAL 2nd Stage, Indiranagar, Bengaluru",
  "lat": 12.9719, "lng": 77.6412,
  "distanceKm": 4.9,
  "etaMinutes": 18,
  "tripWaypoints": [[12.9756, 77.6068], /* … */ [12.9719, 77.6412]]
}
```

### `drivers.json`

Four drivers with name, car model/colour/number, rating, trip count, and their
own **`approachWaypoints`** — the hardcoded path each one drives to reach the
pickup point. `photoUrl` is deliberately empty; the UI renders an initials
avatar rather than a broken image.

### `ride_history.json`

Six past rides with date, pickup, drop, fare, distance, driver, and status. One
is `cancelled` so the list has more than one visual state. The repository sorts
them newest-first.

### Fare and ETA

`FareCalculator` (in `lib/data/models/ride_estimate.dart`) quotes:

```
fare = (32 + 14.5 × distanceKm + 1.8 × etaMinutes) × surge
```

Surge is between 1.0x and 1.3x, seeded from the destination id so the price
does not jump around while the rider is looking at it. The same calculator
produces the itemised receipt on the completion screen, so the line items
always add up to the fare that was quoted before booking.

---

## The ride simulation

`TrackingBloc` runs a small phase machine:

```
driverEnRoute ──(reaches pickup)──▶ driverArrived ──(4s)──▶ onTrip ──▶ tripCompleted
```

A `Timer.periodic` advances one frame every 80 ms. Before each leg starts,
`RouteAnimator.resample` converts the coarse hardcoded waypoints into exactly
one point per frame, spaced evenly **by distance**. That matters for two
reasons: the car moves at a constant speed instead of accelerating wherever the
authored waypoints happen to sit closer together, and every leg takes the same
wall-clock time (15 s to the pickup, 22 s for the trip) regardless of whether
the rider picked a 5 km or a 35 km destination — so the demo never drags.

Per frame the bloc also computes the **bearing** to the next point, which
rotates the car marker so it faces the way it is driving, and splits the route
into `routeBehind` / `routeAhead` so the polyline dims out behind the car.

The ETA countdown is derived from leg progress, so it hits `0:00` exactly as the
car reaches the pin rather than drifting against it.

Markers are painted on a canvas at runtime in `MarkerFactory` (no PNG assets),
which keeps them crisp at any DPI and tied to the app's colour tokens. The map
uses a custom dark style from `assets/map_style_dark.json` to match the theme.

The camera reframes on **phase changes only**, not per frame — following the car
every 80 ms fights the user's own pan/zoom and looks jittery. A recenter button
snaps to the car on demand.

### Location permission

`LocationRepository` asks for GPS and **falls back to the dummy MG Road pickup**
if the service is off, permission is denied, or the fix times out — so the
booking flow still works end-to-end on an emulator with no GPS. The Home header
says which of the two is in use.

---

## Tests

```bash
flutter test
```

26 unit tests covering the parts worth protecting: fare maths and receipt
totals, route resampling / bearing / bounds geometry, dummy-data parsing and
sort order, dispatch timing, input validation, and the tracking bloc's start,
advance, and cancel behaviour.

---

## Notes and trade-offs

- **No backend beyond Firebase Auth.** Bookings are not persisted; ride history
  is static dummy data and does not gain the trip you just completed. Wiring
  that up is a `RideRepository` change plus a Firestore collection.
- **Ride history is read-only.** The rating on the completion screen is
  collected and shown but not stored anywhere.
- **Release APK is signed with debug keys** (Flutter's template default). Add a
  real `key.properties` and signing config before shipping anywhere real.
