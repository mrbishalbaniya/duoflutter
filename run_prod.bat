@echo off
cd /d "%~dp0"
call flutter pub get
flutter run -d chrome
