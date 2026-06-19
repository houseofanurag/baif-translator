@echo off
SETLOCAL EnableDelayedExpansion
cls
echo ========================================================
echo 🌐 BAIF Offline Translator - Windows Deployment Engine
echo ========================================================
echo.

:: Activate local environment space
if not exist "venv\Scripts\activate.bat" (
    echo ❌ Error: Workspace environment not found. Run 'setup.bat' first.
    pause
    exit /b 1
)
call .\venv\Scripts\activate

:: Extract Local IP Configuration for Hotspot tracking
set "LOCAL_IP=localhost"
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /i "IPv4"') do (
    set "TMP_IP=%%A"
    :: Strip leading spaces
    set "TMP_IP=!TMP_IP:~1!"
    if not "!TMP_IP!"=="" (
        set "LOCAL_IP=!TMP_IP!"
    )
)

echo --------------------------------------------------------
echo 🌐 Local Computer Access:       http://localhost:8000
echo 📱 Field Tablet Hotspot Access: http://!LOCAL_IP!:8000
echo --------------------------------------------------------
echo.
echo 🔥 Igniting FastAPI application loops...

:: Fire local hot-reloaded service pipeline bound to all network cards
uvicorn src.backend.main:app --host 0.0.0.0 --port 8000 --reload

pause