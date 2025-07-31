# ========================================
#    Building car_wash_provider AAB
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Building car_wash_provider AAB" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter not found"
    }
    Write-Host "✅ Flutter is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter and add it to your PATH" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Navigate to the project directory
Set-Location $PSScriptRoot
Write-Host "📁 Current directory: $(Get-Location)" -ForegroundColor Blue
Write-Host ""

# Clean the project
Write-Host "🧹 Cleaning the project..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to clean the project" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "✅ Project cleaned successfully" -ForegroundColor Green
Write-Host ""

# Get dependencies
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to get dependencies" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green
Write-Host ""

# Check Android licenses
Write-Host "🔐 Checking Android licenses..." -ForegroundColor Yellow
flutter doctor --android-licenses
Write-Host ""

# Build AAB
Write-Host "🏗️  Building Android App Bundle (AAB)..." -ForegroundColor Yellow
flutter build appbundle --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to build AAB" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check the error messages above" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "    ✅ BUILD SUCCESSFUL!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Display AAB file information
$AAB_PATH = "build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $AAB_PATH) {
    $fileInfo = Get-Item $AAB_PATH
    Write-Host "📱 AAB File Details:" -ForegroundColor Cyan
    Write-Host "   Path: $AAB_PATH" -ForegroundColor White
    Write-Host "   Size: $($fileInfo.Length) bytes" -ForegroundColor White
    Write-Host ""
    Write-Host "🎯 Version: 1.0.2+8" -ForegroundColor Green
    Write-Host "📅 Build Date: $(Get-Date)" -ForegroundColor White
    Write-Host ""
    Write-Host "📂 Opening output folder..." -ForegroundColor Yellow
    Start-Process "build\app\outputs\bundle\release"
} else {
    Write-Host "❌ AAB file not found at expected location" -ForegroundColor Red
    Write-Host "Expected: $AAB_PATH" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    🚀 Ready for Google Play Store!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Upload the AAB file to Google Play Console" -ForegroundColor White
Write-Host "   2. Create a new release" -ForegroundColor White
Write-Host "   3. Add release notes" -ForegroundColor White
Write-Host "   4. Submit for review" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to exit" 