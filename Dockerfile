FROM pytorch/pytorch:2.7.1-cuda12.8-cudnn9-runtime

# Template metadata for frontend deployment requirements
LABEL template.name="LLM WebUI with vLLM and Qwen3-8B"
LABEL template.description="Multi-service container with SSH, vLLM (8B model), and Open WebUI"
LABEL template.version="2.0"
LABEL template.gpu.required=true
LABEL template.gpu.min_vram="16GB"
LABEL template.gpu.recommended="A6000, RTX 4090, or better"
LABEL template.memory.min="16GB"
LABEL template.memory.recommended="32GB"
LABEL template.storage.min="10GB"
LABEL template.cache.huggingface="20GB"
LABEL template.ports.ssh="4444"
LABEL template.ports.vllm="8000"
LABEL template.ports.webui="27015"
LABEL template.model="Qwen/Qwen3-8B"
LABEL template.model_size="8B"
LABEL template.embedded_weights=true
LABEL template.download_strategy="build_time"

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/conda/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    openssh-client \
    sudo \
    curl \
    wget \
    git \
    build-essential \
    xz-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN ln -sf /opt/conda/bin/python /usr/local/bin/python3

ARG S6_OVERLAY_VERSION=3.1.6.2
RUN curl -L "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" | tar -C / -Jxpf - \
    && curl -L "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz" | tar -C / -Jxpf -

RUN useradd -m -s /bin/bash dockeruser && \
    usermod -aG sudo dockeruser

RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/' /etc/ssh/sshd_config

# SSH access files (empty authorized_keys)
RUN mkdir -p /root/.ssh/ && echo '' > /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys

WORKDIR /app

COPY requirements.txt /app/
RUN conda install -c conda-forge -y numpy==1.24.3 && \
    pip install --no-cache-dir -r requirements.txt && \
    pip cache purge

# Create model directory and download model during build time
RUN mkdir -p /app/models
RUN python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='Qwen/Qwen3-8B', local_dir='/app/models/Qwen3-8B', local_dir_use_symlinks=False)"

COPY s6-overlay-fixed/ /etc/s6-overlay/

RUN find /etc/s6-overlay/s6-rc.d -name "run" -type f -exec chmod +x {} \; \
    && find /etc/s6-overlay/s6-rc.d -name "finish" -type f -exec chmod +x {} \;

ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_LOGGING=1 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_KEEP_ENV=1

ENV OPENAI_API_BASE_URL=http://localhost:8000/v1 \
    OPENAI_API_KEY=sk-fake-key \
    PORT=27015 \
    DATA_DIR=/app/open-webui-data \
    VLLM_HOST=0.0.0.0 \
    VLLM_PORT=8000 \
    VLLM_GPU_MEMORY_UTILIZATION=0.85 \
    VLLM_MODEL=/app/models/Qwen3-8B

RUN mkdir -p /app/open-webui-data

EXPOSE 22 8000 27015

ENTRYPOINT ["/init"]