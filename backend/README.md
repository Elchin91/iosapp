# M10 Support Backend

AI-powered support system backend for M10 mobile application.

## Features

- 🤖 AI-powered chat support using Kimi K2 API
- 💬 Real-time conversation management
- 🗄️ MongoDB for chat history storage
- 🚀 FastAPI for high-performance API
- 🔄 Docker support for easy deployment
- 📱 iOS app integration ready

## Quick Start

### Option 1: Using Docker (Recommended)

1. Clone the repository and navigate to backend folder:
```bash
cd backend
```

2. Create `.env` file (already created with your API keys)

3. Start the services:
```bash
docker-compose up -d
```

The API will be available at `http://localhost:8000`

### Option 2: Local Development

1. Install Python 3.11+

2. Install MongoDB locally or use Docker:
```bash
docker run -d -p 27017:27017 --name mongodb mongo:7.0
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Run the server:
```bash
python main.py
```

## API Endpoints

### Health Check
```
GET /
```

### Create Session
```
POST /api/v1/chat/ios/session
```

Response:
```json
{
  "session_id": "uuid-string"
}
```

### Send Message
```
POST /api/v1/chat/ios/message
```

Request:
```json
{
  "session_id": "uuid-string",
  "message": "User message",
  "timestamp": "2024-01-01T00:00:00Z",
  "platform": "ios",
  "device_info": {
    "model": "iPhone",
    "os_version": "17.0",
    "app_version": "1.0"
  }
}
```

Response:
```json
{
  "session_id": "uuid-string",
  "message_id": "uuid-string",
  "answer": "AI response",
  "language": "az",
  "sources": [...],
  "timestamp": "2024-01-01T00:00:00Z",
  "metadata": {...}
}
```

### Get Chat History
```
GET /api/v1/chat/ios/history/{session_id}?limit=50
```

## Configuration

Edit `.env` file to configure:
- Kimi API credentials
- MongoDB connection
- Server settings
- CORS origins

## Development

### Running Tests
```bash
pytest
```

### API Documentation
Visit `http://localhost:8000/docs` for interactive API documentation.

## Deployment

### Using Docker on VPS/Cloud

1. Copy the backend folder to your server

2. Install Docker and Docker Compose

3. Configure `.env` with production values

4. Run:
```bash
docker-compose up -d
```

### Using a Cloud Platform

#### Heroku
1. Create `Procfile`:
```
web: uvicorn main:app --host 0.0.0.0 --port $PORT
```

2. Deploy using Heroku CLI

#### AWS/GCP/Azure
Use container services or deploy Docker image

## iOS App Configuration

Update `APIConfig.swift` in your iOS app:
```swift
static let baseURL = "https://your-backend-url.com/api/v1"
static let useMockMode = false
```

## Security Notes

⚠️ **Important**: 
- Never commit `.env` file with real API keys
- Use environment variables in production
- Enable HTTPS in production
- Implement rate limiting for production use

## Support

For issues or questions, check the documentation in `@Ai Confluence` folder.
