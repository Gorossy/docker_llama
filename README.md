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

### Hardware Requirements
- **GPU**: NVIDIA GPU with minimum 16GB VRAM (RTX 4090, A6000+ recommended)
- **Memory**: Minimum 16GB RAM (32GB recommended)  
- **Storage**: Minimum 10GB for image + 30GB for model cache
- **CPU**: 4+ cores recommended
- **Network**: Required for initial model download (~28GB)

### Software Requirements
- Docker Engine 20.10+
- Docker Compose v2.0+
- NVIDIA GPU drivers (525+)
- NVIDIA Container Toolkit

### Template Metadata
This image includes embedded template metadata for deployment validation:
- Model: DeepSeek-R1-Distill-Qwen-14B (14B parameters)
- Embedded weights: No (runtime download with persistent cache)
- Download strategy: Industry standard runtime caching
- Ports: SSH (4444), vLLM API (8000), Web UI (27015)

## Installation

### Option 1: Pull from Docker Hub (Recommended)
```bash
# Pull lightweight image (model downloads at runtime)
docker pull dmaldonadob/llm-webui-deepseek-r1-14b:latest

# Create cache directories
mkdir -p ./data ./hf-cache

# Run with persistent HuggingFace cache (industry standard)
docker run -d --gpus all \
  --name llm-webui-container \
  -p 4444:22 \
  -p 8000:8000 \
  -p 27015:27015 \
  -v ./data:/app/open-webui-data \
  -v ./hf-cache:/root/.cache/huggingface \
  dmaldonadob/llm-webui-deepseek-r1-14b:latest
```

### Option 2: Build from source
```bash
# Clone repository
git clone <repository-url>
cd <repository>

# Build and push to Docker Hub
./build-and-push.sh

# Or build locally
docker build -t llm-webui-deepseek .
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
| `VLLM_MODEL` | LLM model to load | `deepseek-ai/DeepSeek-R1-Distill-Qwen-14B` |

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