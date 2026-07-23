@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================
echo    Micro-Indigo Immersive
echo ========================================
echo.
echo  Starting server...
echo.

start "MicroIndigoServer" powershell -ExecutionPolicy Bypass -File "%~dp0server.ps1"

timeout /t 3 /nobreak >nul

start http://localhost:8080/

echo  Browser should open automatically.
echo  If not, visit http://localhost:8080
echo.
echo  Close this window to stop the server.
echo  Or press any key to stop...
pause >nul

taskkill /FI "WINDOWTITLE eq MicroIndigoServer*" /F >nul 2>&1
