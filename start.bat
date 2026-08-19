@echo off
cd /d "%~dp0"

REM ========== Port config: first arg, default 12580 ==========
set PORT=%1
if "%PORT%"=="" set PORT=12580

echo ============================================
echo   AI Text Polish - Starting ...
echo ============================================
echo.

REM ========== Check PowerShell ==========
where powershell.exe >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] PowerShell not found. It is built into Windows.
    echo If missing, install Windows Management Framework.
    echo.
    pause
    exit /b 1
)
echo [1/3] PowerShell detected

REM ========== Check port in use ==========
netstat -ano | findstr ":%PORT% " | findstr LISTENING >nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo [ERROR] Port %PORT% is already in use!
    echo Choose:
    echo   A. Close the program using port %PORT% and retry
    echo   B. Use a custom port:  start.bat 8080
    echo.
    pause
    exit /b 2
)
echo [2/3] Port %PORT% is free

echo [3/3] Starting HTTP server ...
echo       URL: http://localhost:%PORT%
echo.

REM ========== Open browser after 2s ==========
start /b cmd /c "timeout /t 2 >nul & start http://localhost:%PORT%"

echo ============================================
echo   System started. Do not close this window.
echo   Closing this window stops the server.
echo   (Port: %PORT%)
echo ============================================
echo.

REM ========== Start PowerShell HTTP server (blocks) ==========
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start.ps1" %PORT%
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Server exited with code %errorlevel%.
    echo.
    pause
)
