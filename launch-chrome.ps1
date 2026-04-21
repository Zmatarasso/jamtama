# Kill any running Flutter/Dart processes
Write-Host "Killing Flutter/Dart processes..." -ForegroundColor Yellow
taskkill /F /IM dart.exe /T 2>$null
taskkill /F /IM flutter.exe /T 2>$null
Start-Sleep -Seconds 1

# Launch Flutter in Chrome on a fixed port
Write-Host "Launching Jamtama in Chrome on port 5000..." -ForegroundColor Green
Set-Location "C:\Users\Kazta\Documents\jamtama\.claude\worktrees\pensive-jang\jamtama"
flutter run -d chrome --web-port 8080 --vmservice-out-file .flutter-vmservice
