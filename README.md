# Seettu App — Flutter + Node.js/Express + MongoDB + Firebase Authentication

```
Flutter (mobile)  ->  REST API / JSON  ->  Node.js + Express.js  ->  MongoDB
       |                                         |
       +-------------- Firebase Authentication ---+   (both sides verify the same Firebase ID token)
```

Folders in this zip
- `server/`  the API (Express + Mongoose + Firebase Admin SDK). Verifies the Firebase login token on every request.
- `mobile/`  the Flutter app source (`lib/` and `pubspec.yaml`). You copy it into a fresh Flutter project in step 4.

I have **not** been able to compile-check the Flutter code (no Flutter SDK in the environment that built this).
Run `flutter analyze` after step 5 below, before your demo, and send me any errors so I can fix them fast.

---------------------------------------------------------------------
## 1. Install these on your computer (one time)
1. **Node.js LTS** — https://nodejs.org
2. **VS Code** — https://code.visualstudio.com, plus its **Flutter** extension (Extensions panel, search "Flutter").
3. **Flutter SDK** — https://docs.flutter.dev/get-started/install (choose Windows). Run `flutter doctor` afterwards and fix anything it flags red. This also gets you the Dart SDK.
4. **MongoDB** — pick ONE:
   - MongoDB Community Server + Compass — https://www.mongodb.com/try/download/community. Install as a Windows service, tick "Install MongoDB as a Service" and "Install MongoDB Compass".
   - OR Docker Desktop, then `docker compose up -d` in this folder (see `docker-compose.yml`).
   - OR a free MongoDB Atlas cluster — put its connection string in `server/.env` as `MONGO_URI`.
5. A phone or emulator to run the app on: either the **Expo Go**-style approach isn't used here (this is plain Flutter) — instead, either
   - a physical Android/iPhone with **USB debugging** enabled and a cable, or
   - an emulator: Android Studio's Android Virtual Device manager, or Xcode's iOS Simulator (Mac only).

## 2. Set up Firebase (needed by both the app and the server)
1. Go to https://console.firebase.google.com and create a new project (any name, e.g. "seettu").
2. In the project, go to **Build > Authentication > Get started**, open the **Sign-in method** tab, and enable **Email/Password**.
3. **For the backend:** go to the gear icon > **Project settings > Service accounts**, click **Generate new private key**. A JSON file downloads — rename it `serviceAccountKey.json` and put it directly inside the `server` folder (next to `package.json`). This file is a secret; don't commit or share it.
4. **For the app:** you'll connect the Flutter project to this same Firebase project in step 4 below, using a tool called FlutterFire.

## 3. Run the backend
Open this folder in VS Code, open a terminal:
```
cd server
npm install
npm run seed      # creates demo data AND a demo Firebase login (needs serviceAccountKey.json from step 2)
npm start
```
You should see `MongoDB connected` and `API running on http://localhost:5000/api`.
Test in a browser: http://localhost:5000/api/health → `{"ok":true}`
Keep this terminal open.

## 4. Create the Flutter app and copy the source in
Open a SECOND terminal in the project root (containing `server` and `mobile`... careful, see note below):
```
flutter create seettu_app
```
This creates a new folder `seettu_app` with its own `lib/`, `pubspec.yaml`, `android/`, `ios/`, etc. Now copy this zip's `mobile` contents OVER it:
```
Copy-Item mobile\pubspec.yaml seettu_app\pubspec.yaml -Force
Remove-Item seettu_app\lib -Recurse -Force
Copy-Item mobile\lib seettu_app\lib -Recurse -Force
```
(Mac/Linux: `cp mobile/pubspec.yaml seettu_app/pubspec.yaml && rm -rf seettu_app/lib && cp -r mobile/lib seettu_app/lib`)

```
cd seettu_app
flutter pub get
```

### Connect this project to your Firebase project
```
dart pub global activate flutterfire_cli
npm install -g firebase-tools      # if you don't have the Firebase CLI already
firebase login
flutterfire configure
```
`flutterfire configure` will ask you to pick the Firebase project you made in step 2, and which platforms (choose Android, and iOS if you're on a Mac). It **overwrites** `lib/firebase_options.dart` with your real keys and sets up the native Android/iOS config automatically. This is the step that makes the placeholder file work.

## 5. Point the app at your computer
Open `lib/config.dart` and find:
```dart
static const String apiHost = 'CHANGE_ME';
```
- **Android emulator**: leave it as `'CHANGE_ME'` — it auto-detects `10.0.2.2`, which reaches your computer's `localhost`.
- **Real phone or iOS Simulator**: set it to your computer's IP address on the same Wi-Fi, e.g. `'192.168.1.10'` (find it with `ipconfig`, look for IPv4 Address).

## 6. Run the app
```
flutter analyze     # fix anything it reports before running — see the note at the top
flutter run
```
Pick your device/emulator when prompted. On first launch you'll land on Onboarding → Log In.
Log in with **nimal@example.com / password123** (created by `npm run seed`), or tap **Create account** to sign up as yourself (this creates a real Firebase user).

## What is inside (every screen from the prototype)
Onboarding, Login, Sign Up, Home, My Groups, Create/Edit Group, Group Details, Member List,
Add/Edit Member, Member Details, Payment dashboard, Record Payment, Payment History, Shared Payment
Records, Payment Reminder, Missed/Late Payments (+ Notify), Payout Schedule, Payout Details,
Rules & Guidelines, Profile, Account, Accessibility (text size, language), Trusted people.

Colors: `mobile/lib/theme.dart` (sampled from the recording of your Figma prototype; edit there).

## API summary (all under /api, JSON, `Authorization: Bearer <Firebase ID token>`)
- POST /auth/sync (create/fetch profile after Firebase sign-in/up); GET/PUT /auth/me
- GET/PUT /settings
- GET /dashboard
- GET/POST /groups; GET/PUT/DELETE /groups/:id
- GET/POST /groups/:id/members; GET/PUT/DELETE /groups/:id/members/:mid
- GET /groups/:id/payouts
- POST /payments; GET /payments/history | /shared | /outstanding | /summary; POST /payments/notify
- GET/POST /trusted; DELETE /trusted/:id; POST /trusted/accept; GET /trusted/shared

## Known limits (say these in your report)
- Password changes go through Firebase's "reset link by email" flow, not an in-app old/new password form.
- Reminder and Notify settings/records are saved in the database, but no real SMS/push/WhatsApp is sent.
- Language choice is saved; Sinhala/Tamil screen text is not translated yet.
- Contribution cycles are monthly ("YYYY-MM"); Weekly groups are stored but tracked per month.
- Dates are typed as YYYY-MM-DD (no date picker).
- No real money movement (by design, NFR6).
- **The Flutter code has not been run or compiled by me — treat `flutter analyze` as part of setup, not optional.**

## Troubleshooting
- `npm run seed` fails with a message about `serviceAccountKey.json`: you skipped step 2.3 — download the key from Firebase Console and place it in `server/`.
- `MongoDB connection failed`: MongoDB isn't running. Start the Windows service / `docker compose up -d` / fix `MONGO_URI`.
- App shows "Cannot reach the server": backend not running, wrong `apiHost` in `lib/config.dart`, different Wi-Fi, or a firewall blocking Node.js (allow it on Private networks).
- `firebase_options.dart is still the placeholder file`: you haven't run `flutterfire configure` yet, or it failed — rerun it inside `seettu_app`.
- Sign-up creates a Firebase user but then shows an error: the backend isn't running or isn't reachable — check step 5's `apiHost`, then try signing up again (it signs the half-created Firebase user back out automatically so you can retry cleanly).
- Version/plugin errors after `flutter pub get`: run `flutter pub upgrade --major-versions`, then `flutter analyze` again.
