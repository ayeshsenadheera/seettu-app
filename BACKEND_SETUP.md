# Backend for Wijesundara’s six screens

The Flutter app has two modes. The default is the offline UI preview. With
`--dart-define=BACKEND_ENABLED=true`, Firebase sign-in opens only the six connected
screens: overdue payments, payment detail, payouts, payout detail, profile and
rules. Other group/member interfaces remain outside this flow.

## Start the API and MongoDB

From the repository root:

```powershell
cd server
npm install
npm run dev:local
```

This starts a real local MongoDB process, downloads its binary into
`server/.mongo-binaries` on first use, and persists data in `server/.local-mongo`.
Keep the terminal open. The health endpoint is
[http://localhost:5000/api/health](http://localhost:5000/api/health).
Health is public; all six-screen data endpoints require a Firebase ID token.

If you prefer your own MongoDB installation or Atlas, set `MONGO_URI` in
`server/.env` and use `npm start` instead. Use `.env.example` as the template.
The API uses Asia/Colombo for monthly cycle calculations. Scheduled deadlines
are returned as date-only strings so a device timezone cannot shift them a day.

## Connect Firebase

1. Create a project in the [Firebase console](https://console.firebase.google.com/).
2. Open **Authentication → Sign-in method** and enable **Email/Password**.
   See the [official authentication setup](https://firebase.google.com/docs/auth/flutter/start).
3. Open **Project settings → Service accounts → Generate new private key**.
   Save the downloaded file as `server/serviceAccountKey.json`. This file stays
   on the server; it is excluded from Git. Application Default Credentials are
   also supported for deployments.
4. Configure Flutter using the [official Flutter Firebase setup](https://firebase.google.com/docs/flutter/setup):

```powershell
npm install -g firebase-tools
firebase login
C:\Users\ASUS\flutter\bin\cache\dart-sdk\bin\dart.exe pub global activate flutterfire_cli
cd ..\mobile
flutterfire configure
```

Choose the same Firebase project and Android platform. If `flutterfire` is not
on PATH, use its launcher in `%LOCALAPPDATA%\Pub\Cache\bin`. This replaces
`mobile/lib/firebase_options.dart` with your project configuration. Restart the
API after adding the service account.

The API intentionally has no development authentication bypass. Integration
tests inject a verifier only into an isolated test application; the running
server always verifies Firebase tokens. Firebase account email cannot be
changed through the MongoDB profile endpoint.

## Run the connected Android app

Start an Android emulator, then from `mobile/`:

```powershell
..\flutter-local.cmd run -d emulator-5556 --dart-define=BACKEND_ENABLED=true
```

Use the device ID shown by `..\flutter-local.cmd devices` if it differs.
The Android emulator automatically uses `http://10.0.2.2:5000/api`.
For a physical phone on the same Wi-Fi, use your computer’s local IP:

```powershell
..\flutter-local.cmd run --dart-define=BACKEND_ENABLED=true --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:5000/api
```

Local HTTP is enabled only in the Android debug manifest. Use an HTTPS API URL
for a release build. The local wrapper keeps Gradle and temporary build files
on D: and avoids the broken Windows PowerShell app alias on this computer.

Create an account in the app. Until a pool exists, the app shows an empty state;
the Profile tab still works. To add sample records for your new account, copy
its UID from Firebase Authentication’s user list and run this in a second
terminal from `server/`:

```powershell
npm run seed:ui -- YOUR_FIREBASE_UID --local
```

Omit `--local` when using the `MONGO_URI` database with `npm start`. This seed adds
one Community Seettu pool with contributions and payout receipts without deleting
existing records. Refresh the pools list in the app to see it.

## Six-screen API

All paths below start with `/api/ui`. Pass
`Authorization: Bearer <Firebase ID token>`.

| Screen/action | Method and path |
| --- | --- |
| Available pools | `GET /groups` |
| Missed/late payments and totals | `GET /groups/:id/outstanding` |
| Payment detail and communication history | `GET /groups/:id/payments/:memberId?month=YYYY-MM` |
| Record outstanding payment reminders | `POST /groups/:id/reminders` |
| Payout schedule and progress | `GET /groups/:id/payouts` |
| Payout detail | `GET /groups/:id/payouts/:memberId` |
| Record a payout receipt | `POST /groups/:id/payouts/:memberId` |
| Rules | `GET /groups/:id/rules` |
| Change rules | `PUT /groups/:id/rules` |
| Read/update account | `GET /profile`, `PUT /profile` |
| Save privacy, notifications, text size, language | `PUT /profile/settings` |
| Link an existing account to a group member | `PUT /groups/:id/members/:memberId/account` |

Profile updates accept `name` and a Sri Lankan `phone` number. Settings accept
`notificationsEnabled`, `sharePayoutUpdates`, `textSize`, and `language`.
Rules updates accept `graceDays`, `lateFeePerDay`, and `maxDiscountPercent`.
Payout recording accepts `status` (`Processing` or `Paid`), a non-empty
`reference`, and optional `method` (`Cash`, `Bank Transfer`, or `Other`).
Account linking accepts `userId`, the account ID returned by `/profile`.

Only a group’s owner may write reminders, rules, account links or payout receipts.
Active members linked by Firebase UID can read their pool; an unverified phone
number alone does not grant membership. Payouts are recorded in the agreed order,
and an already Paid payout cannot be downgraded. Repeating the same Paid reference
returns the original receipt rather than creating another.

The existing group/member/payment APIs remain available for later integration.
The six-screen financial cycle endpoints currently support monthly pools.
Partial payments reduce the overdue balance and do not mark a contribution paid.
Fees apply after the configured grace period; the default fee is zero. Passing a
scheduled payout date does not automatically mark the payout Paid.

Reminder records are stored in MongoDB; SMS, WhatsApp and push delivery require
a provider connection later. The app records transfers made outside the app and
does not move money. Privacy and notification preferences are saved, but automated
sharing and notification delivery are not yet implemented. Language preference is
stored; Sinhala/Tamil screen translation remains a separate task.

## Checks

```powershell
# server/
npm test

# mobile/
..\flutter-local.cmd analyze lib/frontend lib/main.dart lib/config.dart test
..\flutter-local.cmd test
```

The backend tests use a separate temporary MongoDB on D: and do not touch your
local app database. They cover authentication, group access, balances, reminders,
payouts, rules, profile settings and contribution-cycle boundaries. Flutter tests
cover the preview and connected screen navigation, profile saves and API retry.
