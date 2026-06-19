@echo off
SETLOCAL EnableDelayedExpansion
cls
echo ========================================================
echo 🇮🇳 BAIF Offline Translator - Windows Setup Compiler
echo ========================================================
echo.

:: Check for Python installation
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Error: Python is not installed or not added to your system PATH.
    echo Please install Python 3.11 or higher before running this script.
    pause
    exit /b 1
)

:: Create dropzones and storage workspaces
echo 📁 Creating local workspace directories...
if not exist "uploads" mkdir uploads
if not exist "outputs" mkdir outputs

:: Establish Virtual Environment
echo 📦 Configuring isolated Python environment (venv)...
if not exist "venv" (
    python -m venv venv
    echo ✅ Virtual environment compiled successfully.
) else (
    echo ℹ️ Virtual environment already exists. Skipping compilation.
)

:: Activate and bootstrap dependencies
echo ⚡ Activating environment and running dependency sync...
call .\venv\Scripts\activate

echo 🔄 Upgrading local package managers...
python -m pip install --upgrade pip

echo 📥 Synchronizing offline platform library models...
pip install -r requirements.txt

echo ========================================================
echo 🎉 Setup Complete! Neural weights and binaries pre-staged.
echo Run 'run.bat' to initiate the translator platform.
echo ========================================================
pause