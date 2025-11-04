#!/bin/bash

echo "====================================="
echo "  M10 Support - Telegram Bridge"
echo "====================================="
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 is not installed!"
    echo "Please install Python 3.8 or higher"
    exit 1
fi

# Install dependencies
echo "Installing dependencies..."
pip3 install -r requirements_telegram.txt

echo ""
echo "====================================="
echo "  IMPORTANT: Telegram Setup"
echo "====================================="
echo ""
echo "1. Open Telegram"
echo "2. Search for your bot: @your_bot_name"
echo "3. Send /start to get your Chat ID"
echo "4. Add ADMIN_CHAT_ID to .env file"
echo ""
echo "====================================="
echo ""

# Run the server
echo "Starting server..."
python3 main_telegram.py
