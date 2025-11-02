# 🌐 Развертывание M10 Backend в облаке

## 🚀 Быстрое развертывание (10 минут)

### Вариант 1: Railway (Рекомендуется - БЕСПЛАТНО)

1. **Подготовка файлов**
   - Убедитесь, что в папке `backend` есть все файлы
   - Создайте `railway.json`:
   ```json
   {
     "$schema": "https://railway.app/railway.schema.json",
     "build": {
       "builder": "NIXPACKS"
     },
     "deploy": {
       "startCommand": "uvicorn main:app --host 0.0.0.0 --port $PORT"
     }
   }
   ```

2. **Развертывание**
   ```bash
   # Установите Railway CLI
   npm install -g @railway/cli
   
   # Войдите
   railway login
   
   # Инициализируйте проект
   cd backend
   railway init
   
   # Добавьте переменные окружения
   railway variables set KIMI_API_KEY=sk-Gy14TH6AScKZTSHODjldvYPINh1ezbuX3JMpRKYNQsJwpEiG
   
   # Разверните
   railway up
   ```

3. **Получите URL**
   ```bash
   railway domain
   ```

### Вариант 2: Render.com (БЕСПЛАТНО)

1. Зайдите на [render.com](https://render.com)
2. New > Web Service
3. Connect GitHub repo
4. Настройки:
   - Name: `m10-backend`
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
5. Add Environment Variables:
   - `KIMI_API_KEY` = `sk-Gy14TH6AScKZTSHODjldvYPINh1ezbuX3JMpRKYNQsJwpEiG`

### Вариант 3: Локальный VPS

Если у вас есть VPS (DigitalOcean, Linode, etc):

```bash
# 1. Подключитесь к серверу
ssh root@your-server-ip

# 2. Установите Docker
curl -fsSL https://get.docker.com | sh

# 3. Клонируйте репозиторий
git clone https://github.com/your-username/m10-backend.git
cd m10-backend/backend

# 4. Создайте .env файл
nano .env
# Вставьте содержимое .env

# 5. Запустите
docker-compose up -d

# 6. Настройте Nginx (опционально)
apt install nginx
nano /etc/nginx/sites-available/m10
```

Nginx конфигурация:
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 📱 Обновление iOS приложения

После развертывания обновите `APIConfig.swift`:

```swift
// Замените на ваш URL
static let baseURL = "https://your-app.railway.app/api/v1"
static let useMockMode = false
```

## 🔒 Безопасность

1. **Используйте HTTPS** (Railway и Render предоставляют автоматически)
2. **Скройте API ключи** в production
3. **Добавьте rate limiting**:
   ```python
   from slowapi import Limiter
   limiter = Limiter(key_func=lambda: "global")
   app.state.limiter = limiter
   ```

## 📊 Мониторинг

### Railway
- Встроенные метрики в дашборде
- Логи: `railway logs`

### Render
- Встроенный мониторинг в дашборде
- Автоматические алерты

### Собственный VPS
```bash
# Просмотр логов
docker-compose logs -f

# Мониторинг ресурсов
docker stats

# Проверка здоровья
curl http://localhost:8000/
```

## 🛠️ Отладка проблем

### "502 Bad Gateway"
```bash
# Проверьте, запущен ли контейнер
docker ps

# Перезапустите
docker-compose restart
```

### "Connection timeout"
- Проверьте firewall правила
- Убедитесь, что порт 8000 открыт

### API ключ не работает
- Проверьте переменные окружения
- Убедитесь, что ключ действителен

## 📈 Масштабирование

Когда ваше приложение растет:

1. **Добавьте кеширование Redis**
2. **Используйте CDN для статики**
3. **Настройте автомасштабирование**
4. **Добавьте load balancer**

## ✅ Чеклист запуска

- [ ] Backend развернут и доступен
- [ ] API отвечает на запросы
- [ ] iOS приложение подключено
- [ ] Тесты пройдены
- [ ] HTTPS настроен
- [ ] Мониторинг включен

Готово! Ваш backend теперь доступен из интернета! 🎉
