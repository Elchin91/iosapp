# M10 Clone - Архитектура приложения

## Общая архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                      M10CloneApp.swift                       │
│                      (@main Entry Point)                     │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     ContentView.swift                        │
│                  (TabView Container)                         │
│  ┌──────┬──────────┬──────────┬───────────┬──────────┐     │
│  │ Home │ Payments │   AI     │ Transfers │ Profile  │     │
│  └──────┴──────────┴──────────┴───────────┴──────────┘     │
└─────────────────────────────────────────────────────────────┘
         │         │         │          │           │
         ▼         ▼         ▼          ▼           ▼
    ┌────────┬────────┬─────────┬─────────┬─────────┐
    │ Home   │ Pay    │  AI     │ Trans   │ Profile │
    │ View   │ View   │  Chat   │ View    │ View    │
    └────────┴────────┴─────────┴─────────┴─────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │ AI Chat     │
                    │ ViewModel   │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Message    │
                    │   Model     │
                    └─────────────┘
```

## MVVM Pattern (на примере AI Chat)

```
┌─────────────────────────────────────────────────────────────┐
│                          VIEW LAYER                          │
│                       (AIChatView.swift)                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────────────────────────────────────────┐    │
│  │             ScrollView (Messages List)              │    │
│  │  ┌──────────────────────────────────────────────┐  │    │
│  │  │  MessageBubble (User) ─────────────────┐     │  │    │
│  │  │  MessageBubble (AI)   ──────────┐      │     │  │    │
│  │  │  TypingIndicator      ───┐      │      │     │  │    │
│  │  └───────────────────────────┴──────┴──────┴─────┘  │    │
│  └────────────────────────────────────────────────────┘    │
│                                                               │
│  ┌────────────────────────────────────────────────────┐    │
│  │              Input Area (Bottom)                    │    │
│  │  ┌────┐  ┌──────────────────┐  ┌────────┐         │    │
│  │  │📎  │  │  TextField       │  │  ➤    │         │    │
│  │  └────┘  └──────────────────┘  └────────┘         │    │
│  └────────────────────────────────────────────────────┘    │
│                                                               │
└───────────────────────┬───────────────────────────────────┘
                        │ @StateObject
                        │ Bindings ($messageText)
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                      VIEWMODEL LAYER                         │
│                  (AIChatViewModel.swift)                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  @Published var messages: [Message] = []                    │
│  @Published var messageText: String = ""                    │
│  @Published var isTyping: Bool = false                      │
│                                                               │
│  func sendMessage() {                                        │
│      1. Create user message                                  │
│      2. Add to messages array                                │
│      3. Set isTyping = true                                  │
│      4. Task { await sleep(1.5s) }                          │
│      5. Generate AI response                                 │
│      6. Add AI message                                       │
│      7. Set isTyping = false                                 │
│  }                                                            │
│                                                               │
│  func generateAIResponse(for text: String) -> String         │
│                                                               │
└───────────────────────┬───────────────────────────────────┘
                        │ Uses
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                       MODEL LAYER                            │
│                      (Message.swift)                         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  struct Message: Identifiable, Equatable {                  │
│      let id: UUID                                            │
│      let text: String                                        │
│      let isUser: Bool                                        │
│      let timestamp: Date                                     │
│  }                                                            │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow (Поток данных)

### Отправка сообщения:

```
1. User types in TextField
   │
   ▼
2. TextField binds to viewModel.messageText ($messageText)
   │
   ▼
3. User taps Send button
   │
   ▼
4. AIChatView calls viewModel.sendMessage()
   │
   ▼
5. AIChatViewModel.sendMessage():
   ├─ Creates Message(text: messageText, isUser: true)
   ├─ Appends to messages array
   ├─ Sets isTyping = true
   ├─ Clears messageText
   └─ Starts async Task
      │
      ▼
6. Task sleeps 1.5 seconds
   │
   ▼
7. Generates AI response
   │
   ▼
8. Creates Message(text: response, isUser: false)
   │
   ▼
9. Appends to messages array
   │
   ▼
10. Sets isTyping = false
    │
    ▼
11. View automatically updates (SwiftUI reactivity)
    │
    ▼
12. ScrollView scrolls to bottom
```

### State Management:

```
@Published Property          Effect on View
─────────────────────────────────────────────
messages: [Message]     →    ForEach rebuilds message list
messageText: String     →    TextField updates
isTyping: Bool         →    TypingIndicator shows/hides
```

## Component Hierarchy

```
M10CloneApp
│
└── ContentView (TabView)
    ├── HomeView
    │   ├── BalanceCard
    │   ├── QuickActionButton (x4)
    │   └── TransactionRow (x3)
    │
    ├── PaymentsView
    │   ├── SearchBar
    │   ├── PaymentCategoryCard (x6)
    │   └── RecentPaymentRow (x2)
    │
    ├── AIChatView ⭐ (MAIN FEATURE)
    │   ├── ScrollView
    │   │   ├── MessageBubble (user)
    │   │   ├── MessageBubble (AI)
    │   │   └── TypingIndicator
    │   │
    │   └── Input Area
    │       ├── AttachmentButton
    │       ├── TextField
    │       └── SendButton
    │
    ├── TransfersView
    │   ├── TransferTypePicker
    │   ├── RecipientInput
    │   ├── ContactButton (x4)
    │   └── TransferTemplateRow (x2)
    │
    └── ProfileView
        ├── ProfileHeader
        ├── CardRow (x2)
        ├── SettingsSection (x3)
        └── LogoutButton
```

## File Dependencies

```
M10CloneApp.swift
└── imports: SwiftUI

ContentView.swift
├── imports: SwiftUI
└── uses: All View files, AppColors

AIChatView.swift
├── imports: SwiftUI
├── uses: AIChatViewModel
├── uses: Message
└── uses: AppColors

AIChatViewModel.swift
├── imports: Foundation, SwiftUI
├── uses: Message
└── conforms to: ObservableObject

Message.swift
├── imports: Foundation
└── conforms to: Identifiable, Equatable

Colors.swift
└── imports: SwiftUI

All other View files
├── import: SwiftUI
└── use: AppColors
```

## Color System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  Extensions/Colors.swift                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  struct AppColors {                                          │
│      // Primary M10 purple                                   │
│      static let primary = Color(hex: "7B3FF2")   ◄────┐     │
│      static let primaryLight = Color(hex: "9D6FF5")   │     │
│      static let primaryDark = Color(hex: "5E2FBF")    │     │
│                                                        │     │
│      // Chat bubbles                                  │     │
│      static let userBubble = Color(hex: "7B3FF2") ────┘     │
│      static let aiBubble = Color(hex: "F3F4F6")             │
│                                                               │
│      // Text                                                 │
│      static let textPrimary = Color(hex: "1F2937")          │
│      static let textSecondary = Color(hex: "6B7280")        │
│  }                                                            │
│                                                               │
│  extension Color {                                           │
│      init(hex: String) { /* HEX → RGB conversion */ }       │
│  }                                                            │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ Used by
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    All View Files                            │
│  .foregroundColor(AppColors.primary)                        │
│  .background(AppColors.userBubble)                          │
└─────────────────────────────────────────────────────────────┘
```

## Navigation Structure

```
TabView (contentView)
│
├── Tab 1: HomeView
│   └── NavigationView
│       ├── Title: "Главная"
│       └── Toolbar: Bell icon
│
├── Tab 2: PaymentsView
│   └── NavigationView
│       └── Title: "Платежи"
│
├── Tab 3: AIChatView ⭐
│   └── NavigationView
│       ├── Title: "AI Ассистент"
│       └── Toolbar: More options icon
│
├── Tab 4: TransfersView
│   └── NavigationView
│       ├── Title: "Переводы"
│       └── Toolbar: QR code icon
│
└── Tab 5: ProfileView
    └── NavigationView
        ├── Title: "Профиль"
        └── Toolbar: Settings icon
```

## State Management Pattern

### ObservableObject (ViewModel)
```swift
@MainActor
class AIChatViewModel: ObservableObject {
    // Published properties notify views of changes
    @Published var messages: [Message] = []
    @Published var messageText: String = ""
    @Published var isTyping: Bool = false

    // Methods modify published properties
    func sendMessage() {
        messages.append(newMessage) // ← View updates automatically
    }
}
```

### View (Observing ViewModel)
```swift
struct AIChatView: View {
    // Creates and owns the ViewModel
    @StateObject private var viewModel = AIChatViewModel()

    // Two-way binding to ViewModel property
    TextField("Message", text: $viewModel.messageText)

    // Reads ViewModel properties
    ForEach(viewModel.messages) { message in
        MessageBubble(message: message)
    }
}
```

## Async/Await Pattern (AI Response)

```
┌─────────────────────────────────────────────────────────────┐
│                     Main Thread (@MainActor)                 │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  User taps Send                                              │
│  ↓                                                            │
│  viewModel.sendMessage() called                              │
│  ↓                                                            │
│  1. Add user message (UI updates immediately)                │
│  2. Set isTyping = true (UI shows typing indicator)         │
│  ↓                                                            │
│  Task { ← Creates async task                                 │
│      ↓                                                        │
│      try? await Task.sleep(nanoseconds: 1_500_000_000)      │
│      ↓                                                        │
│      [1.5 seconds pass - UI remains responsive]             │
│      ↓                                                        │
│      let response = generateAIResponse(for: message)         │
│      ↓                                                        │
│      3. Add AI message (UI updates)                          │
│      4. Set isTyping = false (UI hides typing indicator)    │
│  }                                                            │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## SwiftUI Lifecycle

```
App Launch
│
├── M10CloneApp.init()
│   │
│   └── body: some Scene
│       │
│       └── WindowGroup
│           │
│           └── ContentView()
│               │
│               ├── Tab 1: HomeView()
│               ├── Tab 2: PaymentsView()
│               ├── Tab 3: AIChatView()
│               │           │
│               │           └── @StateObject viewModel = AIChatViewModel()
│               │                       │
│               │                       └── init() {
│               │                               messages.append(welcomeMessage)
│               │                           }
│               ├── Tab 4: TransfersView()
│               └── Tab 5: ProfileView()
│
User taps AI tab
│
└── AIChatView appears
    │
    └── body: some View is evaluated
        │
        └── ScrollView renders messages
            │
            └── ForEach(viewModel.messages) { message in
                    MessageBubble(message: message)
                }
```

## Key Design Patterns

### 1. Protocol-Oriented Programming
```swift
// Identifiable protocol for ForEach
struct Message: Identifiable {
    let id: UUID  // Required by Identifiable
    // ...
}

// Usage:
ForEach(messages) { message in  // ← No need for id: \.id
    MessageBubble(message: message)
}
```

### 2. Composition over Inheritance
```swift
// Small, reusable components
struct MessageBubble: View { /* ... */ }
struct TypingIndicator: View { /* ... */ }

// Composed into larger view
struct AIChatView: View {
    var body: some View {
        VStack {
            ForEach(messages) { message in
                MessageBubble(message: message)  // ← Reusable
            }
            TypingIndicator()  // ← Reusable
        }
    }
}
```

### 3. Declarative UI
```swift
// Describes WHAT, not HOW
MessageBubble(message: message)
    .padding()
    .background(color)
    .cornerRadius(20)

// SwiftUI figures out HOW to render it
```

### 4. Single Source of Truth
```swift
// ViewModel holds the truth
@Published var messages: [Message] = []

// View reflects the truth
ForEach(viewModel.messages) { message in
    MessageBubble(message: message)
}

// Changes to truth automatically update view
viewModel.messages.append(newMessage)  // ← View updates
```

## Performance Optimizations

### LazyVStack (Chat Messages)
```swift
ScrollView {
    LazyVStack {  // ← Only renders visible messages
        ForEach(messages) { message in
            MessageBubble(message: message)
        }
    }
}
```

### ScrollViewReader (Auto-scroll)
```swift
ScrollViewReader { proxy in
    // ...
    .onChange(of: messages.count) { _, _ in
        withAnimation {
            proxy.scrollTo(lastMessage.id)  // ← Smooth scroll
        }
    }
}
```

### @MainActor (UI Safety)
```swift
@MainActor  // ← All methods run on main thread
class AIChatViewModel: ObservableObject {
    // Safe to update @Published properties
}
```

## Summary

**Architecture:** MVVM
**UI Framework:** SwiftUI
**State Management:** Combine (@Published, @StateObject)
**Concurrency:** Swift Concurrency (async/await)
**Design:** Protocol-oriented, Compositional
**Performance:** Lazy loading, Main thread safety

---

**Ключевая особенность:** Реактивная архитектура - изменения в ViewModel автоматически обновляют UI.
