# Seettu Playwright API tests (IT3060 Milestone 03, group WE_74)

Automated tests for the 29 functional test cases in section 8 of the report (TC-01 to TC-29).

Playwright cannot drive an Android app, so these tests call the Seettu **API** (the same server the Flutter app uses) and check the results: roles, validation, CRUD, and who may see what. Each test title starts with its test-case ID.

## One-time setup

Open PowerShell in the repository folder.

```powershell
cd playwright-tests
```

```powershell
npm install
```

```powershell
Copy-Item .env.example .env
```

Open `.env` and set `FIREBASE_API_KEY` to the **Web API Key** from Firebase console → Project settings → General.

## Start a test server (separate test database)

Use a different database name so the tests never touch your real data. In the **server** folder, open a second PowerShell window and run (use your own Atlas string, but end it with `/seettu_test` instead of `/seettu`):

```powershell
cd ..\server
```

```powershell
$env:PORT = "5001"
```

```powershell
$env:MONGO_URI = "mongodb+srv://USER:PASSWORD@cluster0.xxxx.mongodb.net/seettu_test?retryWrites=true&w=majority"
```

```powershell
npm start
```

## Run the tests

In the `playwright-tests` window:

```powershell
npm test
```

Open the HTML report (good for the viva):

```powershell
npm run report
```

Print one result line per test case, ready for the report:

```powershell
npm run summary
```

## Notes

- Run it on any day except the 1st of a month (new members only become overdue after the 1st).
- The tests create temporary Firebase accounts (`pwtest...@example.com`) and delete them at the end. Test data stays only in the `seettu_test` database.
- Tests run in order and share data. If one fails, the later ones show as "did not run": fix the problem and run again.
- Never commit `.env`.
