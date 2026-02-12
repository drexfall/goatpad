@echo off
REM Local Build Test Script for Windows
REM This script helps you test builds locally before pushing to GitHub

setlocal enabledelayedexpansion

echo ================================
echo GOATpad Local Build Test
echo ================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Flutter is not installed or not in PATH
    exit /b 1
)

echo Flutter Version:
flutter --version
echo.

REM Get current version from pubspec.yaml
for /f "tokens=2" %%a in ('findstr /r "^version:" pubspec.yaml') do set VERSION=%%a
for /f "tokens=1 delims=+" %%a in ("!VERSION!") do set VERSION=%%a
echo Current Version: !VERSION!
echo.

REM Get dependencies
echo Getting Flutter dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Failed to get dependencies
    exit /b 1
)
echo [OK] Dependencies installed
echo.

REM Ask user what to build
if "%~1"=="" (
    echo Select platforms to build:
    echo 1^) Android
    echo 2^) Windows
    echo 3^) Both
    echo.
    set /p choice="Enter choice (1-3): "
) else (
    set choice=%~1
)

if "!choice!"=="1" goto build_android
if "!choice!"=="2" goto build_windows
if "!choice!"=="3" goto build_both
echo [ERROR] Invalid choice
exit /b 1

:build_android
echo.
echo Building for Android...
flutter build apk --release
if %errorlevel% neq 0 (
    echo [ERROR] Android build failed
    exit /b 1
)
echo [OK] Android APK built successfully
echo Location: build\app\outputs\flutter-apk\app-release.apk
if "!choice!"=="3" goto build_windows
goto end

:build_windows
echo.
echo Building for Windows...
flutter config --enable-windows-desktop
flutter build windows --release
if %errorlevel% neq 0 (
    echo [ERROR] Windows build failed
    exit /b 1
)
echo [OK] Windows app built successfully
echo Location: build\windows\x64\runner\Release\
goto end

:build_both
call :build_android
call :build_windows
goto end

:end
echo.
echo ================================
echo Build test complete!
echo ================================
echo.
echo If all builds succeeded, you're ready to create a release:
echo.
echo   git tag v!VERSION!
echo   git push origin v!VERSION!
echo.
exit /b 0

