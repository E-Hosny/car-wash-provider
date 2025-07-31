@echo off
echo ========================================
echo    Building car_wash_provider AAB
echo ========================================
echo.

:: Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed or not in PATH
    echo Please install Flutter and add it to your PATH
    pause
    exit /b 1
)

echo ✅ Flutter is installed
echo.

:: Navigate to the project directory
cd /d "%~dp0"
echo 📁 Current directory: %CD%
echo.

:: Clean the project
echo 🧹 Cleaning the project...
flutter clean
if %errorlevel% neq 0 (
    echo ❌ Failed to clean the project
    pause
    exit /b 1
)
echo ✅ Project cleaned successfully
echo.

:: Get dependencies
echo 📦 Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Failed to get dependencies
    pause
    exit /b 1
)
echo ✅ Dependencies installed successfully
echo.

:: Check Android licenses
echo 🔐 Checking Android licenses...
flutter doctor --android-licenses
echo.

:: Build AAB
echo 🏗️  Building Android App Bundle (AAB)...
flutter build appbundle --release
if %errorlevel% neq 0 (
    echo ❌ Failed to build AAB
    echo.
    echo Please check the error messages above
    pause
    exit /b 1
)

echo.
echo ========================================
echo    ✅ BUILD SUCCESSFUL!
echo ========================================
echo.

:: Display AAB file information
set "AAB_PATH=build\app\outputs\bundle\release\app-release.aab"
if exist "%AAB_PATH%" (
    echo 📱 AAB File Details:
    echo    Path: %AAB_PATH%
    for %%A in ("%AAB_PATH%") do echo    Size: %%~zA bytes
    echo.
    echo 🎯 Version: 1.0.2+8
    echo 📅 Build Date: %date% %time%
    echo.
    echo 📂 Opening output folder...
    explorer "build\app\outputs\bundle\release"
) else (
    echo ❌ AAB file not found at expected location
    echo Expected: %AAB_PATH%
)

echo.
echo ========================================
echo    🚀 Ready for Google Play Store!
echo ========================================
echo.
echo 📋 Next steps:
echo    1. Upload the AAB file to Google Play Console
echo    2. Create a new release
echo    3. Add release notes
echo    4. Submit for review
echo.
pause 