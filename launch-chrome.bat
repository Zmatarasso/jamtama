@echo off
REM Kill any running Flutter/Dart processes first
taskkill /F /IM dart.exe /T >nul 2>&1
taskkill /F /IM flutter.exe /T >nul 2>&1

REM Launch using bash (avoids Git Bash /c path conversion issue with cmd /c)
echo Launching Jamtama in Chrome on port 5000...
"C:\Program Files\Git\bin\bash.exe" -c "cd 'C:/Users/Kazta/Documents/jamtama/.claude/worktrees/pensive-jang/jamtama' && 'C:/Users/Kazta/Documents/flutter/bin/flutter.bat' run -d chrome --web-port 5000"
