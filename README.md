# LLM WebUI Docker Container

Este contenedor Docker proporciona una solución completa para ejecutar un servidor LLM con interfaz web, incluyendo:

- **vLLM**: Servidor de LLM con soporte GPU
- **Open WebUI**: Interfaz web moderna para interactuar con el LLM
- **SSH**: Acceso remoto al contenedor

## Características

- ✅ Múltiples servicios gestionados con s6-overlay
- ✅ Dependencias automáticas entre servicios
- ✅ Soporte completo para GPU NVIDIA
- ✅ Reinicio automático de servicios
- ✅ Logs centralizados
- ✅ Configuración flexible mediante variables de entorno

## Requisitos

- Docker
- Docker Compose
- GPU NVIDIA con drivers instalados
- NVIDIA Container Toolkit

## Instalación

### 1. Clonar el repositorio
```bash
git clone <tu-repositorio>
cd <tu-repositorio>
```

### 2. Construir la imagen
```bash
docker build -t llm-webui .
```

### 3. Ejecutar con Docker Compose
```bash
docker-compose up -d
```

### 4. Ejecutar con Docker directamente
```bash
docker run -d \
  --name llm-webui \
  --gpus all \
  -p 22:22 \
  -p 8000:8000 \
  -p 27015:27015 \
  -v $(pwd)/data:/app/open-webui-data \
  llm-webui
```

## Acceso a los servicios

### SSH
- **Puerto**: 22
- **Usuario**: `dockeruser` / `password123`
- **Root**: `root` / `root123`

```bash
ssh dockeruser@localhost -p 22
```

### Open WebUI
- **URL**: http://localhost:27015
- **Puerto**: 27015

### vLLM API
- **URL**: http://localhost:8000/v1
- **Puerto**: 8000

## Variables de entorno

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| `OPENAI_API_BASE_URL` | URL base de la API vLLM | `http://localhost:8000/v1` |
| `OPENAI_API_KEY` | Clave API (fake para vLLM) | `sk-fake-key` |
| `PORT` | Puerto de Open WebUI | `27015` |
| `DATA_DIR` | Directorio de datos | `./open-webui-data` |
| `VLLM_HOST` | Host de vLLM | `0.0.0.0` |
| `VLLM_PORT` | Puerto de vLLM | `8000` |
| `VLLM_GPU_MEMORY_UTILIZATION` | Utilización de memoria GPU | `0.85` |
| `VLLM_MODEL` | Modelo LLM a cargar | `NousResearch/Meta-Llama-3-8B-Instruct` |

## Estructura de servicios

```
SSH (puerto 22) ← independiente
vLLM (puerto 8000) ← depende de SSH
Open WebUI (puerto 27015) ← depende de vLLM
```

## Logs

Para ver los logs de todos los servicios:
```bash
docker logs llm-webui
```

Para ver logs específicos:
```bash
# SSH
docker exec llm-webui cat /var/log/s6/01-ssh/current

# vLLM
docker exec llm-webui cat /var/log/s6/02-vllm/current

# Open WebUI
docker exec llm-webui cat /var/log/s6/03-openwebui/current
```

## Solución de problemas

### GPU no detectada
```bash
# Verificar drivers NVIDIA
nvidia-smi

# Verificar NVIDIA Container Toolkit
docker run --rm --gpus all nvidia/cuda:12.1-base-ubuntu22.04 nvidia-smi
```

### Servicios no inician
```bash
# Verificar logs
docker logs llm-webui

# Reiniciar contenedor
docker-compose restart
```

### Cambiar modelo LLM
```bash
# Editar docker-compose.yml
environment:
  - VLLM_MODEL=tu-modelo-aqui

# Reconstruir y ejecutar
docker-compose down
docker-compose up -d --build
```

## Personalización

### Cambiar credenciales SSH
Editar el Dockerfile y cambiar las líneas:
```dockerfile
RUN useradd -m -s /bin/bash dockeruser && \
    echo "dockeruser:tu-password" | chpasswd
```

### Agregar más modelos
Modificar la variable `VLLM_MODEL` en docker-compose.yml o como variable de entorno.

## Contribuir

1. Fork el repositorio
2. Crear una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Crear un Pull Request 