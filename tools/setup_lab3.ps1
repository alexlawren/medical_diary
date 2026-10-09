$ErrorActionPreference = "Stop"

Write-Host "[1/3] Flutter dependencies..."
flutter pub get

Write-Host "[2/3] Realm model generation..."
dart run realm generate

Write-Host "[3/3] Ready. Starting application..."
flutter run
