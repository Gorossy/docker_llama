# LLM WebUI Docker Container with s6-overlay

Docker container providing a complete solution for running an LLM server with web interface, including:

- **vLLM**: High-speed LLM inference server
- **Open WebUI**: Modern web interface for LLM interaction
- **SSH**: Remote access to container
- **s6-overlay**: Advanced service management with dependencies

## Features

- ✅ Multiple services managed with s6-overlay
- ✅ Automatic dependencies between services
- ✅ Full NVIDIA GPU support
- ✅ Automatic service restart
- ✅ Centralized logging
- ✅ Flexible configuration via environment variables

## Requirements

- Docker
- Docker Compose
- NVIDIA GPU with drivers (optional)
- NVIDIA Container Toolkit (if using GPU)

## Installation

### 1. Clone repository
```bash
git clone <repository-url>
cd <repository>
```

### 2. Build and run automatically
```bash
./build-and-deploy.sh
```

### 3. Manual build
```bash
docker build -t llm-webui .
docker-compose up -d
```

## Access to services

### SSH
- **Port**: 4444 (mapped from internal 22)
- **User**: `root` / `root123`

```bash
ssh root@localhost -p 4444
```

### Open WebUI
- **URL**: http://localhost:27015
- **Port**: 27015

### vLLM API
- **URL**: http://localhost:8000/v1
- **Port**: 8000

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENAI_API_BASE_URL` | vLLM API base URL | `http://localhost:8000/v1` |
| `OPENAI_API_KEY` | API key (fake for vLLM) | `sk-fake-key` |
| `PORT` | Open WebUI port | `27015` |
| `DATA_DIR` | Data directory | `./open-webui-data` |
| `VLLM_HOST` | vLLM host | `0.0.0.0` |
| `VLLM_PORT` | vLLM port | `8000` |
| `VLLM_GPU_MEMORY_UTILIZATION` | GPU memory utilization | `0.85` |
| `VLLM_MODEL` | LLM model to load | `NousResearch/Meta-Llama-3-8B-Instruct` |

## Service Management with s6-overlay

### Service startup order:
1. **SSH** (internal port 22) - Starts first
2. **vLLM** (port 8000) - Waits for SSH
3. **Open WebUI** (port 27015) - Waits for SSH and vLLM

### Service structure
```
SSH (port 22) ← independent
vLLM (port 8000) ← depends on SSH
Open WebUI (port 27015) ← depends on vLLM and SSH
```

## Useful Commands

### View logs
```bash
docker-compose logs -f
```

### Stop services
```bash
docker-compose down
```

### Rebuild image
```bash
docker-compose build --no-cache
```

### Access container
```bash
docker exec -it llm-webui-container bash
```

## Troubleshooting

### GPU not detected
```bash
nvidia-smi
docker run --rm --gpus all nvidia/cuda:12.1-base-ubuntu22.04 nvidia-smi
```

### Services not starting
```bash
docker-compose logs
docker-compose restart
```

### Change LLM model
```bash
# Edit docker-compose.yml
environment:
  - VLLM_MODEL=your-model-here

# Rebuild and run
docker-compose down
docker-compose up -d --build
```

## Project Structure

```
.
├── Dockerfile                 # Container configuration
├── docker-compose.yml         # Service configuration
├── requirements.txt           # Python dependencies
├── s6-overlay/                # s6-overlay configuration
│   └── s6-rc.d/
│       └── user/
│           ├── 01-ssh/        # SSH service
│           ├── 02-vllm/       # vLLM service
│           ├── 03-openwebui/  # Open WebUI service
│           ├── contents.d/    # Service definitions
│           └── dependencies.d/ # Service dependencies
└── README.md
```

## Contributing

1. Fork repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request 