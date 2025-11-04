# AI Integration Guide for M10Clone

## Обзор интеграции

Приложение M10Clone интегрирует AI-поддержку через следующие компоненты:

### 1. Kimi K2 API
- **API Key**: `sk-Gy14TH6AScKZTSHODjldvYPINh1ezbuX3JMpRKYNQsJwpEiG`
- **Base URL**: `https://api.moonshot.cn/v1/chat/completions`
- **Model**: `kimi-k2-turbo-preview`

### 2. Telegram Bot (для уведомлений)
- **Bot Token**: `8445924679:AAEFxGjFjCjUg8coV7vNyvV8OimUN_jw3wA`

## Архитектура

```
iOS App → Backend API → Kimi AI API
                    ↓
             Confluence API
```

## Конфигурация

### Mock Mode (для тестирования)

По умолчанию приложение работает в mock режиме для тестирования без backend.

Чтобы переключиться на реальный API:

1. Откройте `Config/APIConfig.swift`
2. Измените `useMockMode = true` на `useMockMode = false`
3. Укажите реальный URL вашего backend в `baseURL`

### Backend Requirements

Backend должен реализовать следующие endpoints:

1. **POST** `/api/v1/chat/ios/session` - Создание новой сессии
2. **POST** `/api/v1/chat/ios/message` - Отправка сообщения
3. **GET** `/api/v1/chat/ios/history/{session_id}` - История чата

## Использование

### Инициализация чата

```swift
// ViewModel автоматически создает сессию при инициализации
@StateObject private var viewModel = AIChatViewModel()
```

### Отправка сообщения

```swift
// ViewModel автоматически обрабатывает отправку
viewModel.sendMessage()
```

### Mock ответы

В mock режиме поддерживаются следующие темы:
- BakıKART (пополнение карты)
- Баланс (проверка баланса)
- Платежи (оплата услуг)
- Переводы (денежные переводы)
- Кредит (кредитные услуги)

## Безопасность

⚠️ **ВАЖНО**: 
- Не храните API ключи в коде для production версии
- Используйте переменные окружения или secure storage
- Настройте SSL pinning для защиты соединения

## Тестирование

1. Запустите приложение в mock режиме
2. Проверьте базовую функциональность чата
3. Переключитесь на реальный API когда backend готов
4. Протестируйте интеграцию с Kimi AI

## Troubleshooting

### Проблемы с подключением
- Проверьте правильность URL backend
- Убедитесь что backend запущен
- Проверьте сетевое соединение

### Проблемы с ответами AI
- Проверьте валидность API ключа Kimi
- Убедитесь что модель `kimi-k2-turbo-preview` доступна
- Проверьте лимиты API

## Контакты

При возникновении вопросов обращайтесь к документации в папке `@Ai Confluence`.
