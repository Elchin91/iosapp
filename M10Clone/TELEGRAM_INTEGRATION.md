# Telegram Bot Integration

This document describes the Telegram bot integration implemented in the M10Clone iOS app.

## Overview

The app now supports bidirectional messaging with a Telegram bot:
- Messages sent in the iOS app are forwarded to the Telegram bot
- Messages sent to the Telegram bot appear in the iOS app
- Both the user and assistant responses are synced across both platforms

## Files Created/Modified

### Created Files

1. **C:\Users\elchi\Desktop\IOS app\M10Clone\M10Clone\Services\TelegramService.swift**
   - Main service class for Telegram bot communication
   - Implements long polling to receive messages
   - Sends messages to the bot
   - Stores chat_id in UserDefaults

### Modified Files

1. **C:\Users\elchi\Desktop\IOS app\M10Clone\M10Clone\ViewModels\AIChatViewModel.swift**
   - Integrated TelegramService
   - Forwards user messages to Telegram
   - Receives and displays messages from Telegram
   - Processes Telegram messages through the API and sends responses back

## Configuration

### Bot Token
The bot token is stored in `APIConfig.swift`:
```swift
struct Telegram {
    static let botToken = "8445924679:AAEFxGjFjCjUg8coV7vNyvV8OimUN_jw3wA"
}
```

### Chat ID Storage
The Telegram chat ID is automatically stored in UserDefaults when the first message is received from Telegram. This ensures that subsequent messages are sent to the correct chat.

Key: `telegram_chat_id`

## How It Works

### Initialization
1. When `AIChatViewModel` is initialized, it creates a `TelegramService` instance
2. The service starts long polling for Telegram updates
3. A callback is set up to handle incoming messages

### Sending Messages (iOS -> Telegram)
1. User types a message in the iOS app
2. Message is sent to the API service (existing functionality)
3. Message is forwarded to Telegram with prefix "User: "
4. Assistant response is also sent to Telegram with prefix "Assistant: "

### Receiving Messages (Telegram -> iOS)
1. User sends a message to the Telegram bot
2. Long polling receives the update
3. Chat ID is stored if it's the first message
4. Message is added to the chat UI
5. Message is processed through the API service
6. Assistant response is displayed in the app
7. Assistant response is sent back to Telegram

### Long Polling
- Uses Telegram's getUpdates API with 30-second timeout
- Automatically retries on error with 3-second delay
- Tracks the last update_id to avoid duplicate processing
- Stops polling when the view model is deinitialized

## Error Handling

The integration includes robust error handling:
- Network errors don't crash the app
- Telegram failures don't prevent API messages from working
- Errors are logged to console for debugging
- The app continues to function even if Telegram is unavailable

## API Endpoints Used

### Telegram Bot API
- **Base URL**: https://api.telegram.org/bot{token}
- **sendMessage**: Sends messages to a specific chat
- **getUpdates**: Receives incoming messages via long polling

## Message Flow

### User sends message in iOS app:
```
User types message -> AIChatViewModel.sendMessage()
                   -> APIService.sendMessage() (existing)
                   -> TelegramService.sendMessage("User: ...")
                   -> API response received
                   -> TelegramService.sendMessage("Assistant: ...")
```

### User sends message to Telegram bot:
```
User sends Telegram message -> TelegramService.pollUpdates()
                            -> processUpdate()
                            -> onMessageReceived callback
                            -> handleTelegramMessage()
                            -> Message added to UI
                            -> APIService.sendMessage()
                            -> Response added to UI
                            -> TelegramService.sendMessage()
```

## Testing

To test the integration:

1. Start the iOS app
2. Send a message to the bot: @YourBotName on Telegram
3. The message should appear in the iOS app
4. Send a message from the iOS app
5. Check Telegram - you should see both the user message and assistant response

## Security Considerations

- Bot token is currently hardcoded in APIConfig.swift
- For production, consider using:
  - Keychain for token storage
  - Environment variables
  - Secure configuration management

## Limitations

- Only supports text messages (no photos, documents, etc.)
- Single chat support (one-to-one with the user who first messages the bot)
- No message history sync (only new messages)
- Requires active internet connection for polling

## Future Enhancements

Potential improvements:
- Support for media messages
- Multiple chat support
- Webhook-based updates instead of polling
- Message history synchronization
- Read receipts
- Typing indicators
- Custom keyboards in Telegram
