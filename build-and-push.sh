#!/bin/bash
set -e

# Docker Hub repository name
REPO_NAME="dmaldonadob/llm-webui-qwen2.5-72b"
TAG="latest"

echo "🔨 Building lightweight Docker image (model downloads at runtime)..."
echo "Build time: ~5-10 minutes (no model download during build)..."
docker build -t $REPO_NAME:$TAG .

echo "📊 Image size:"
docker images $REPO_NAME:$TAG

echo "🚀 Pushing to Docker Hub..."
docker push $REPO_NAME:$TAG

echo "✅ Image available at: docker pull $REPO_NAME:$TAG"
echo ""
echo "🏃 To run:"
echo "docker run -d --gpus all -p 4444:22 -p 8000:8000 -p 27015:27015 $REPO_NAME:$TAG"
echo ""
echo "📋 Services will be available at:"
echo "  • SSH: localhost:4444 (root/root123)"
echo "  • vLLM API: localhost:8000"  
echo "  • Open WebUI: localhost:27015"