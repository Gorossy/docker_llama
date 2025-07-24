#!/bin/bash

echo "=== Verificando configuración de s6-overlay ==="

# Verificar estructura de directorios
echo "1. Verificando estructura de directorios..."
if [ -d "s6-overlay/s6-rc.d/user" ]; then
    echo "✓ Directorio user encontrado"
else
    echo "✗ Directorio user no encontrado"
    exit 1
fi

# Verificar servicios
echo "2. Verificando servicios..."
services=("01-ssh" "02-vllm" "03-openwebui")
for service in "${services[@]}"; do
    if [ -d "s6-overlay/s6-rc.d/user/$service" ]; then
        echo "✓ Servicio $service encontrado"
        
        # Verificar script run
        if [ -f "s6-overlay/s6-rc.d/user/$service/run" ]; then
            if [ -x "s6-overlay/s6-rc.d/user/$service/run" ]; then
                echo "  ✓ Script run ejecutable"
            else
                echo "  ✗ Script run no es ejecutable"
            fi
        else
            echo "  ✗ Script run no encontrado"
        fi
    else
        echo "✗ Servicio $service no encontrado"
    fi
done

# Verificar contents.d
echo "3. Verificando contents.d..."
for service in "${services[@]}"; do
    if [ -f "s6-overlay/s6-rc.d/user/contents.d/$service" ]; then
        echo "✓ Content file para $service encontrado"
    else
        echo "✗ Content file para $service no encontrado"
    fi
done

# Verificar dependencies.d
echo "4. Verificando dependencies.d..."
if [ -f "s6-overlay/s6-rc.d/user/dependencies.d/02-vllm/01-ssh" ]; then
    echo "✓ vLLM depende de SSH"
else
    echo "✗ vLLM no tiene dependencia de SSH"
fi

if [ -f "s6-overlay/s6-rc.d/user/dependencies.d/03-openwebui/02-vllm" ]; then
    echo "✓ Open WebUI depende de vLLM"
else
    echo "✗ Open WebUI no tiene dependencia de vLLM"
fi

if [ -f "s6-overlay/s6-rc.d/user/dependencies.d/03-openwebui/01-ssh" ]; then
    echo "✓ Open WebUI depende de SSH"
else
    echo "✗ Open WebUI no tiene dependencia de SSH"
fi

echo "=== Verificación completada ===" 