#!/usr/bin/env python3
"""
Telegram Bot для получения сообщений из iOS приложения
"""

import os
import logging
from datetime import datetime
import asyncio
from typing import Dict, List

from telegram import Update, Bot
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# Bot configuration
BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "8445924679:AAEFxGjFjCjUg8coV7vNyvV8OimUN_jw3wA")

# Storage for chat sessions
sessions: Dict[str, Dict] = {}

# Bot instance for sending messages
bot = Bot(token=BOT_TOKEN)

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Send a message when the command /start is issued."""
    user = update.effective_user
    await update.message.reply_text(
        f'Salam {user.mention_html()}! 👋\n\n'
        f'Mən m10 dəstək botuyam. iOS tətbiqindən gələn mesajları burada görəcəksiniz.\n\n'
        f'Sizin Telegram ID: <code>{user.id}</code>\n'
        f'(Bu ID-ni saxlayın, iOS tətbiqdə lazım olacaq)',
        parse_mode='HTML'
    )

async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Send a message when the command /help is issued."""
    help_text = """
🤖 <b>m10 Support Bot Komandaları:</b>

/start - Botu işə salın və ID-nizi öyrənin
/help - Bu yardım mesajını göstərin
/status - Aktiv sessiyaları görün
/clear - Bütün sessiyaları silin

<b>Necə işləyir:</b>
1. iOS tətbiqdə mesaj göndərin
2. Mesajınız burada görünəcək
3. Cavab yazın - iOS tətbiqdə görünəcək

<b>Qeyd:</b> Real vaxtda cavab vermək üçün bot aktiv olmalıdır.
    """
    await update.message.reply_text(help_text, parse_mode='HTML')

async def status_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Show active sessions"""
    if not sessions:
        await update.message.reply_text("Aktiv sessiya yoxdur.")
        return
    
    status_text = "📊 <b>Aktiv Sessiyalar:</b>\n\n"
    for session_id, session_data in sessions.items():
        messages_count = len(session_data.get('messages', []))
        created_at = session_data.get('created_at', 'Unknown')
        status_text += f"• Session: <code>{session_id[:8]}...</code>\n"
        status_text += f"  Mesajlar: {messages_count}\n"
        status_text += f"  Yaradılıb: {created_at}\n\n"
    
    await update.message.reply_text(status_text, parse_mode='HTML')

async def clear_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Clear all sessions"""
    sessions.clear()
    await update.message.reply_text("✅ Bütün sessiyalar silindi.")

async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle incoming messages - these are responses to iOS app users"""
    if not update.message.reply_to_message:
        await update.message.reply_text(
            "⚠️ Cavab vermək üçün iOS tətbiqdən gələn mesaja reply edin."
        )
        return
    
    # Extract session ID from the replied message
    replied_text = update.message.reply_to_message.text
    if "Session:" not in replied_text:
        await update.message.reply_text("❌ Bu mesaja cavab verilə bilməz.")
        return
    
    try:
        # Parse session ID from message
        session_line = [line for line in replied_text.split('\n') if 'Session:' in line][0]
        session_id = session_line.split('Session:')[1].strip()
        
        # Store the response
        response_text = update.message.text
        if session_id in sessions:
            sessions[session_id]['responses'].append({
                'text': response_text,
                'timestamp': datetime.utcnow().isoformat(),
                'from_telegram': True
            })
            
            await update.message.reply_text(
                f"✅ Cavabınız qeydə alındı!\n"
                f"Session: <code>{session_id}</code>",
                parse_mode='HTML'
            )
        else:
            await update.message.reply_text("❌ Sessiya tapılmadı.")
            
    except Exception as e:
        logger.error(f"Error handling response: {e}")
        await update.message.reply_text("❌ Xəta baş verdi.")

async def send_to_telegram(session_id: str, user_message: str, device_info: dict = None):
    """Send iOS app message to Telegram (called from API)"""
    try:
        # Get bot info
        bot_info = await bot.get_me()
        
        # Format device info
        device_text = ""
        if device_info:
            device_text = f"\n📱 {device_info.get('model', 'Unknown')} - iOS {device_info.get('os_version', '?')}"
        
        # Send message to Telegram
        message_text = (
            f"💬 <b>Yeni mesaj iOS tətbiqdən:</b>\n\n"
            f"{user_message}\n"
            f"\n➖➖➖➖➖➖➖➖➖\n"
            f"Session: <code>{session_id}</code>"
            f"{device_text}\n"
            f"🕐 {datetime.now().strftime('%H:%M:%S')}"
        )
        
        # You need to specify chat_id where to send messages
        # For testing, you can use your own chat ID
        # Run /start command to get your chat ID
        ADMIN_CHAT_ID = os.getenv("ADMIN_CHAT_ID", None)
        
        if ADMIN_CHAT_ID:
            await bot.send_message(
                chat_id=ADMIN_CHAT_ID,
                text=message_text,
                parse_mode='HTML'
            )
            return True
        else:
            logger.warning("ADMIN_CHAT_ID not set. Message not sent to Telegram.")
            return False
            
    except Exception as e:
        logger.error(f"Error sending to Telegram: {e}")
        return False

def main():
    """Start the bot."""
    # Create the Application
    application = Application.builder().token(BOT_TOKEN).build()

    # Register handlers
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("help", help_command))
    application.add_handler(CommandHandler("status", status_command))
    application.add_handler(CommandHandler("clear", clear_command))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))

    # Run the bot
    application.run_polling()

if __name__ == '__main__':
    main()
