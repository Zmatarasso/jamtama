@echo off
setlocal EnableDelayedExpansion

REM ── Paths ────────────────────────────────────────────────────────────────────
set FLUTTER=C:\Users\Kazta\Documents\flutter\bin\flutter.bat
set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
set EMULATOR=%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe
set AVD=Pixel_7_API34
set PKG=io.royalruckus.app
set APK=build\app\outputs\flutter-apk\app-debug.apk

REM ── Make sure the ADB server is up ───────────────────────────────────────────
echo Starting ADB server...
"%ADB%" start-server >nul 2>&1

REM ── Detect an already-online device by parsing `adb devices` cleanly ─────────
set ONLINE=
for /f "skip=1 tokens=1,2" %%A in ('"%ADB%" devices') do (
    if "%%B"=="device" set ONLINE=%%A
)

if defined ONLINE (
    echo Device !ONLINE! already online.
    goto :build_and_run
)

REM ── Boot path: cold boot to avoid the stale-snapshot freeze ──────────────────
echo No online device. Cold-booting %AVD%...
echo   (using -no-snapshot-load for clean state; first boot ~60-90s)
start "" "%EMULATOR%" -avd %AVD% -no-snapshot-load -no-snapshot-save

echo Waiting for ADB to see a device...
"%ADB%" wait-for-device
if %errorlevel% neq 0 (
    echo adb wait-for-device failed. Is the emulator actually launching?
    exit /b 1
)

echo Device connected. Waiting for Android OS boot to finish...
set ATTEMPTS=0
:wait_boot
timeout /t 4 /nobreak >nul
set BOOTED=
for /f "tokens=*" %%B in ('"%ADB%" shell getprop sys.boot_completed 2^>nul') do set BOOTED=%%B
set /a ATTEMPTS+=1
echo   [check !ATTEMPTS!] sys.boot_completed=!BOOTED!
if not "!BOOTED!"=="1" (
    if !ATTEMPTS! gtr 45 (
        echo Gave up after 3 minutes. Emulator might be hung — kill it and retry.
        exit /b 1
    )
    goto :wait_boot
)

echo Boot completed. Waiting for launcher to settle...
set ATTEMPTS=0
:wait_anim
timeout /t 2 /nobreak >nul
set ANIM=
for /f "tokens=*" %%B in ('"%ADB%" shell getprop init.svc.bootanim 2^>nul') do set ANIM=%%B
set /a ATTEMPTS+=1
if not "!ANIM!"=="stopped" (
    if !ATTEMPTS! gtr 30 (
        echo Boot animation never stopped; continuing anyway.
        goto :build_and_run
    )
    goto :wait_anim
)

echo Emulator fully ready.

REM ── Build + install + launch ─────────────────────────────────────────────────
:build_and_run
pushd jamtama

echo.
echo === Building debug APK ===
call "%FLUTTER%" build apk --debug
if errorlevel 1 (
    echo BUILD FAILED.
    popd
    exit /b 1
)

echo.
echo === Installing on device ===
"%ADB%" install -r "%APK%"
if errorlevel 1 (
    echo INSTALL FAILED.
    popd
    exit /b 1
)

echo.
echo === Launching %PKG% ===
"%ADB%" shell am force-stop %PKG% >nul 2>&1
timeout /t 1 /nobreak >nul
"%ADB%" shell am start -n "%PKG%/%PKG%.MainActivity"

popd

echo.
echo ============================================================
echo  App launched. Re-run this script to rebuild + reinstall
echo  without rebooting the emulator.
echo ============================================================

endlocal
