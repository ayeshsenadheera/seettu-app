@echo off
setlocal
rem Avoid the non-launchable PowerShell app execution alias on this computer.
set "PATH=%PATH:C:\Users\ASUS\AppData\Local\Microsoft\WindowsApps;=%"
set "PATH=%PATH:;C:\Users\ASUS\AppData\Local\Microsoft\WindowsApps=%"
call C:\Users\ASUS\flutter\bin\flutter.bat %*
exit /b %errorlevel%
