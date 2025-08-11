FROM pytorch/pytorch:2.7.1-cuda12.8-cudnn9-runtime

# LLM WebUI with vLLM and GPT-OSS-20B

LABEL template.name="llm-webui-gpt-oss-20b" \
      template.description="LLM WebUI with vLLM backend and GPT-OSS-20B model" \
      template.version="1.0" \
      template.model="openai/gpt-oss-20b" \
      template.storage.min="40GB" \
      template.gpu.required="true" \
      template.gpu.memory.min="16GB" \
      template.gpu.supported="RTX 4070,RTX 4080,RTX 4090,RTX A4000,RTX A5000,RTX A6000,L40,L40s,RTX 6000 Ada,RTX 5090,A100-40GB,A100-80GB,H100,H200,B200" \
      template.gpu.recommended="RTX 4080,RTX 4090,RTX A5000,RTX A6000,L40s,RTX 6000 Ada,RTX 5090" \
      template.ports.ssh="22" \
      template.ports.vllm="8000" \
      template.ports.webui="27015"

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


# Build argument for model URL (can be full URL or just repo_id)
ARG MODEL_URL

# Create model directory and download model during build time
RUN mkdir -p /app/models
RUN echo "Processing model URL: ${MODEL_URL}" && \
    REPO_ID=$(echo "${MODEL_URL}" | sed 's|^https://huggingface.co/||' | sed 's|/$||') && \
    MODEL_NAME=$(echo "${REPO_ID}" | cut -d'/' -f2) && \
    echo "Extracted repo_id: ${REPO_ID}" && \
    echo "Model name: ${MODEL_NAME}" && \
    python -c "from huggingface_hub import snapshot_download; repo_id='${REPO_ID}'; model_name=repo_id.split('/')[-1]; print(f'Downloading {repo_id} to /app/models/{model_name}'); snapshot_download(repo_id=repo_id, local_dir=f'/app/models/{model_name}', local_dir_use_symlinks=False)"

COPY s6-overlay/ /etc/s6-overlay/

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
    VLLM_MODEL="" \
    VLLM_DTYPE="auto"

RUN mkdir -p /app/open-webui-data

EXPOSE 22 8000 27015

ENTRYPOINT ["/init"]