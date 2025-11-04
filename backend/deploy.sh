#!/bin/bash

# Simple deployment script for VPS/Cloud server

echo "🚀 Starting M10 Backend Deployment..."

# Pull latest changes
echo "📥 Pulling latest changes..."
git pull origin main

# Build and restart containers
echo "🔨 Building Docker containers..."
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Check if services are running
echo "✅ Checking services..."
docker-compose ps

# Show logs
echo "📋 Recent logs:"
docker-compose logs --tail=50

echo "✨ Deployment complete!"
echo "🌐 API available at: http://localhost:8000"
echo "📚 API docs: http://localhost:8000/docs"
