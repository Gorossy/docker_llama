#!/bin/bash
set -e

# Configurar variables de entorno por defecto
export OPENAI_API_BASE_URL=${OPENAI_API_BASE_URL:-"http://localhost:8000/v1"}
export OPENAI_API_KEY=${OPENAI_API_KEY:-"sk-fake-key"}
export PORT=${PORT:-27015}
export DATA_DIR=${DATA_DIR:-"./open-webui-data"}

# Crear directorio de datos si no existe
mkdir -p "$DATA_DIR"

# Configurar variables de entorno para vLLM
export VLLM_HOST=${VLLM_HOST:-"0.0.0.0"}
export VLLM_PORT=${VLLM_PORT:-8000}
export VLLM_GPU_MEMORY_UTILIZATION=${VLLM_GPU_MEMORY_UTILIZATION:-0.85}
export VLLM_MODEL=${VLLM_MODEL:-"NousResearch/Meta-Llama-3-8B-Instruct"}

echo "=== Configuración del contenedor ==="
echo "OpenAI API Base URL: $OPENAI_API_BASE_URL"
echo "Open WebUI Port: $PORT"
echo "Data Directory: $DATA_DIR"
echo "vLLM Host: $VLLM_HOST"
echo "vLLM Port: $VLLM_PORT"
echo "vLLM Model: $VLLM_MODEL"
echo "GPU Memory Utilization: $VLLM_GPU_MEMORY_UTILIZATION"
echo "====================================="

# Inicializar s6-overlay
exec /init 