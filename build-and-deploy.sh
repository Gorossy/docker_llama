#!/bin/bash
set -e

echo "=== LLM WebUI Docker Build & Deploy ==="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Verificar configuración de s6-overlay
print_info "Verificando configuración de s6-overlay..."
if [ -f "./test-s6-config.sh" ]; then
    ./test-s6-config.sh
    if [ $? -ne 0 ]; then
        print_error "Error en la configuración de s6-overlay"
        exit 1
    fi
else
    print_warning "Script de verificación no encontrado, continuando..."
fi

# Verificar que Docker esté instalado
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado. Por favor instala Docker primero."
    exit 1
fi

# Verificar que Docker Compose esté instalado
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose no está instalado. Por favor instala Docker Compose primero."
    exit 1
fi

# Verificar GPU NVIDIA
print_status "Verificando GPU NVIDIA..."
if command -v nvidia-smi &> /dev/null; then
    print_status "GPU NVIDIA detectada:"
    nvidia-smi --query-gpu=name,memory.total --format=csv
else
    print_warning "No se detectó GPU NVIDIA. El contenedor funcionará con CPU (más lento)."
fi

# Crear directorio de datos si no existe
mkdir -p data

# Construir la imagen
print_status "Construyendo imagen Docker..."
docker build -t llm-webui .

if [ $? -eq 0 ]; then
    print_status "Imagen construida exitosamente!"
else
    print_error "Error al construir la imagen."
    exit 1
fi

# Detener contenedor existente si está corriendo
print_status "Deteniendo contenedor existente si está corriendo..."
docker-compose down 2>/dev/null || true

# Iniciar el contenedor
print_status "Iniciando contenedor..."
docker-compose up -d

if [ $? -eq 0 ]; then
    print_status "Contenedor iniciado exitosamente!"
else
    print_error "Error al iniciar el contenedor."
    exit 1
fi

# Esperar un momento y mostrar logs
sleep 15
print_status "Mostrando logs iniciales..."
docker-compose logs --tail=30

print_status "=== Despliegue completado ==="
echo ""
print_status "Servicios disponibles:"
echo "  - SSH: localhost:4444 (usuario: root, password: root123)"
echo "  - vLLM API: http://localhost:8000/v1"
echo "  - Open WebUI: http://localhost:27015"
echo ""
print_status "Para ver logs en tiempo real:"
echo "  docker-compose logs -f"
echo ""
print_status "Para detener el contenedor:"
echo "  docker-compose down" 