@echo off
setlocal
set "GRADLE_USER_HOME=%~dp0.android-build-cache\gradle-home"
set "TEMP=%~dp0.android-build-cache\tmp"
set "TMP=%TEMP%"
if not exist "%TEMP%" mkdir "%TEMP%"
rem Avoid the non-launchable PowerShell app execution alias on this computer.
set "PATH=%PATH:C:\Users\ASUS\AppData\Local\Microsoft\WindowsApps;=%"
set "PATH=%PATH:;C:\Users\ASUS\AppData\Local\Microsoft\WindowsApps=%"
call C:\Users\ASUS\flutter\bin\flutter.bat %*
exit /b %errorlevel%
