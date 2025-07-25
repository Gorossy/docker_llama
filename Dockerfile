FROM pytorch/pytorch:2.7.1-cuda12.8-cudnn9-runtime

# Template metadata for frontend deployment requirements
LABEL template.name="LLM WebUI with vLLM and DeepSeek-R1-Distill-Qwen-14B"
LABEL template.description="Multi-service container with SSH, vLLM (14B model), and Open WebUI"
LABEL template.version="2.0"
LABEL template.gpu.required=true
LABEL template.gpu.min_vram="16GB"
LABEL template.gpu.recommended="RTX 4090, A6000, or better"
LABEL template.memory.min="16GB"
LABEL template.memory.recommended="32GB"
LABEL template.storage.min="10GB"
LABEL template.cache.huggingface="30GB"
LABEL template.ports.ssh="4444"
LABEL template.ports.vllm="8000"
LABEL template.ports.webui="27015"
LABEL template.model="deepseek-ai/DeepSeek-R1-Distill-Qwen-14B"
LABEL template.model_size="14B"
LABEL template.embedded_weights=false
LABEL template.download_strategy="runtime_with_cache"

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
    echo "dockeruser:password123" | chpasswd && \
    usermod -aG sudo dockeruser

RUN mkdir -p /var/run/sshd && \
    echo 'root:root123' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

WORKDIR /app

COPY requirements.txt /app/
RUN conda install -c conda-forge -y numpy==1.24.3 && \
    pip install --no-cache-dir -r requirements.txt && \
    pip cache purge

# Create cache directory for HuggingFace models (runtime download)
RUN mkdir -p /root/.cache/huggingface

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
    VLLM_MODEL=deepseek-ai/DeepSeek-R1-Distill-Qwen-14B

RUN mkdir -p /app/open-webui-data

EXPOSE 22 8000 27015

ENTRYPOINT ["/init"]