# LLM WebUI Docker Container con s6-overlay

Este contenedor Docker proporciona una solución completa para ejecutar un servidor LLM con interfaz web, incluyendo:

- **vLLM**: Servidor de LLM con soporte GPU
- **Open WebUI**: Interfaz web moderna para interactuar con el LLM
- **SSH**: Acceso remoto al contenedor
- **s6-overlay**: Gestión avanzada de servicios con dependencias

## Características

- ✅ Múltiples servicios gestionados con s6-overlay
- ✅ Dependencias automáticas entre servicios
- ✅ Soporte completo para GPU NVIDIA
- ✅ Reinicio automático de servicios
- ✅ Logs centralizados
- ✅ Configuración flexible mediante variables de entorno
- ✅ Verificación automática de configuración

## Requisitos

- Docker
- Docker Compose
- GPU NVIDIA con drivers instalados (opcional)
- NVIDIA Container Toolkit (si usas GPU)

## Instalación

### 1. Clonar el repositorio
```bash
git clone <tu-repositorio>
cd <tu-repositorio>
```

### 2. Verificar configuración (recomendado)
```bash
./test-s6-config.sh
```

### 3. Construir y ejecutar automáticamente
```bash
./build-and-deploy.sh
```

### 4. Construir manualmente
```bash
docker build -t llm-webui .
docker-compose up -d
```

## Acceso a los servicios

### SSH
- **Puerto**: 4444 (mapeado desde 22 interno)
- **Usuario**: `root` / `root123`

```bash
ssh root@localhost -p 4444
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

## Gestión de servicios con s6-overlay

### Orden de inicio de servicios:
1. **SSH** (puerto 22 interno) - Se inicia primero
2. **vLLM** (puerto 8000) - Espera a que SSH esté listo
3. **Open WebUI** (puerto 27015) - Espera a que SSH y vLLM estén listos

### Dependencias configuradas:
- vLLM depende de SSH
- Open WebUI depende de SSH y vLLM

### Estructura de servicios
```
SSH (puerto 22) ← independiente
vLLM (puerto 8000) ← depende de SSH
Open WebUI (puerto 27015) ← depende de vLLM y SSH
```

## Logs

Para ver los logs de todos los servicios:
```bash
docker-compose logs -f
```

Para ver logs específicos:
```bash
# SSH
docker exec llm-webui-container cat /var/log/s6/01-ssh/current

# vLLM
docker exec llm-webui-container cat /var/log/s6/02-vllm/current

# Open WebUI
docker exec llm-webui-container cat /var/log/s6/03-openwebui/current
```

## Comandos útiles

### Verificar configuración de s6-overlay
```bash
./test-s6-config.sh
```

### Ver logs en tiempo real
```bash
docker-compose logs -f
```

### Detener servicios
```bash
docker-compose down
```

### Reconstruir imagen
```bash
docker-compose build --no-cache
```

### Acceder al contenedor
```bash
docker exec -it llm-webui-container bash
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
# Verificar configuración de s6-overlay
./test-s6-config.sh

# Verificar logs
docker-compose logs

# Reiniciar contenedor
docker-compose restart
```

### Problemas con s6-overlay
```bash
# Verificar permisos de scripts
chmod +x s6-overlay/s6-rc.d/user/*/run

# Verificar configuración
./test-s6-config.sh
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
RUN echo 'root:tu-password' | chpasswd
```

### Agregar más modelos
Modificar la variable `VLLM_MODEL` en docker-compose.yml o como variable de entorno.

## Estructura del proyecto

```
.
├── Dockerfile                 # Configuración del contenedor
├── docker-compose.yml         # Configuración de servicios
├── docker-entrypoint.sh       # Script de inicialización
├── requirements.txt           # Dependencias de Python
├── build-and-deploy.sh        # Script de construcción y despliegue
├── test-s6-config.sh          # Script de verificación de s6-overlay
├── s6-overlay/                # Configuración de s6-overlay
│   └── s6-rc.d/
│       └── user/
│           ├── 01-ssh/        # Servicio SSH
│           ├── 02-vllm/       # Servicio vLLM
│           ├── 03-openwebui/  # Servicio Open WebUI
│           ├── contents.d/    # Definición de servicios
│           └── dependencies.d/ # Dependencias entre servicios
└── README.md
```

## Contribuir

1. Fork el repositorio
2. Crear una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Crear un Pull Request 