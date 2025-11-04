# M10Clone - iOS Support Chat App

iOS приложение с интеграцией Telegram Bot и AI ассистента на базе Confluence.

## Функционал

- **Чат интерфейс** для службы поддержки
- **Telegram Bot** интеграция - двусторонняя синхронизация сообщений
- **AI ассистент** на основе Kimi AI с доступом к FAQ из Confluence
- **Реальные данные** - без мокапов, только реальные API

## Структура проекта

```
.
├── M10Clone/           # iOS приложение
│   ├── M10Clone/       # Исходный код
│   └── project.yml     # XcodeGen конфигурация
├── backend/            # FastAPI backend
└── .github/workflows/  # CI/CD
```

## Сборка

### GitHub Actions (рекомендуется)

Push в main ветку автоматически запускает сборку. IPA доступен в Artifacts.

### Локально (требуется Mac)

```bash
cd M10Clone
xcodegen generate
open M10Clone.xcodeproj
```

## Backend

```bash
cd backend
cp .env.example .env
# Отредактируйте .env с вашими credentials
pip install -r requirements.txt
python main.py
```

## Установка

1. Скачайте IPA из GitHub Actions Artifacts
2. Установите через TrollStore или Sideloadly

## Конфигурация

- **Telegram Bot Token**: настроен в APIConfig.swift
- **Confluence API**: настроен в backend/.env
- **Kimi AI**: настроен в backend/.env

## Требования

- iOS 15.0+
- Xcode 15.0+
- Python 3.9+ (для backend)
- MongoDB (для backend)
