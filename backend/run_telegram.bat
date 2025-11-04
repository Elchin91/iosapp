@echo off
echo =====================================
echo   M10 Support - Telegram Bridge
echo =====================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed!
    echo Please install Python 3.8 or higher
    pause
    exit /b 1
)

REM Install dependencies
echo Installing dependencies...
pip install -r requirements_telegram.txt

echo.
echo =====================================
echo   IMPORTANT: Telegram Setup
echo =====================================
echo.
echo 1. Open Telegram
echo 2. Search for your bot: @your_bot_name
echo 3. Send /start to get your Chat ID
echo 4. Add ADMIN_CHAT_ID to .env file
echo.
echo =====================================
echo.

REM Run the server
echo Starting server...
python main_telegram.py

pause
