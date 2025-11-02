# Telegram Bot Integration - Usage Guide

## Quick Start

### 1. Bot Information
- **Bot Token**: `8445924679:AAEFxGjFjCjUg8coV7vNyvV8OimUN_jw3wA`
- **Bot Username**: (You need to find this in your BotFather conversation)

### 2. First Time Setup

1. Open Telegram and search for your bot using its username
2. Send `/start` or any message to the bot
3. This message will:
   - Be stored as the active chat_id
   - Appear in your iOS app
   - Receive an automated response from the AI

### 3. Using the Integration

#### From iOS App:
- Type a message in the AI Chat view
- Press send
- The message will:
  - Appear in the iOS app chat
  - Be sent to your Telegram bot (prefixed with "User: ")
  - Receive an AI response
  - The AI response will appear in both iOS app and Telegram (prefixed with "Assistant: ")

#### From Telegram:
- Send a message to your bot
- The message will:
  - Appear in the iOS app chat
  - Be processed by the AI
  - The AI response will appear in both the iOS app and Telegram

### 4. Message Format in Telegram

When you send a message from the iOS app, you'll see in Telegram:
```
User: How do I check my balance?
Assistant: Balansınızı yoxlamaq üçün əsas ekrana keçin...
```

When you send from Telegram, the iOS app will show the message without the prefix.

## Code Integration Points

### TelegramService.swift
Main service handling all Telegram communication:

```swift
// Initialize
let telegramService = TelegramService(botToken: APIConfig.Telegram.botToken)

// Set callback for incoming messages
telegramService.onMessageReceived = { text in
    print("Received: \(text)")
}

// Start polling
telegramService.startPolling()

// Send message
try await telegramService.sendMessage(text: "Hello from iOS!")

// Stop polling
telegramService.stopPolling()

// Clear chat ID (for testing)
telegramService.clearChatId()
```

### AIChatViewModel.swift
Automatically integrates Telegram with the chat:

```swift
// Initialization (automatic)
init() {
    telegramService = TelegramService(botToken: APIConfig.Telegram.botToken)
    telegramService.onMessageReceived = { [weak self] text in
        Task { @MainActor in
            self?.handleTelegramMessage(text)
        }
    }
    Task {
        await initializeSession()
        telegramService.startPolling()
    }
}

// Cleanup (automatic)
deinit {
    telegramService.stopPolling()
}
```

## Debugging

### Enable Debug Logging
The integration already includes print statements for debugging:

```
Starting Telegram polling...
Received message from Telegram: Hello!
Message forwarded to Telegram
Message sent to Telegram successfully
Saved new Telegram chat ID: 123456789
```

### Check if Polling is Active
```swift
if viewModel.telegramService.isPolling {
    print("Polling is active")
}
```

### Check Chat ID
```swift
if let chatId = viewModel.telegramService.chatId {
    print("Chat ID: \(chatId)")
} else {
    print("No chat ID - send a message to the bot first")
}
```

### Clear Chat ID for Testing
```swift
viewModel.telegramService.clearChatId()
```

## Common Issues

### Messages not appearing in iOS app
1. Check that polling is active
2. Verify the bot token is correct
3. Check console for error messages
4. Ensure you're sending to the correct bot

### Messages not appearing in Telegram
1. Verify you've sent at least one message to the bot (to set chat_id)
2. Check that chat_id is saved (console will show this)
3. Verify internet connection
4. Check console for send errors

### Duplicate Messages
- This should not happen as the service tracks `lastUpdateId`
- If it does, try restarting the app

### No Response from AI
1. Check that APIService is working (test without Telegram)
2. Verify network connection
3. Check API endpoint configuration

## Network Requirements

- Internet connection required for:
  - Telegram API communication
  - Backend API communication
  - Long polling (continuous connection)

## Performance Notes

- Long polling uses minimal bandwidth (only when messages arrive)
- Polling timeout is 30 seconds (standard for Telegram)
- Error retry delay is 3 seconds
- No battery impact from efficient long polling

## Privacy & Security

- Chat ID is stored locally in UserDefaults
- Bot token is in app code (consider moving to secure storage for production)
- Only one chat is supported per app instance
- Messages from other chats are ignored

## Testing Checklist

- [ ] Send message from iOS app -> appears in Telegram
- [ ] Send message to Telegram bot -> appears in iOS app
- [ ] AI response from iOS message -> appears in Telegram
- [ ] AI response from Telegram message -> appears in iOS app
- [ ] Restart app -> chat_id persists
- [ ] Send message from different Telegram account -> ignored
- [ ] Network error -> app continues working
- [ ] Telegram error -> API messages still work
