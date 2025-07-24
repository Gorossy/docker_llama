# Usar la misma imagen base que tu proyecto principal
FROM pytorch/pytorch:2.7.1-cuda12.8-cudnn9-runtime

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Asegurar que PATH incluya Conda binaries
ENV PATH="/opt/conda/bin:$PATH"

# Instalar dependencias del sistema
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

# Forzar "python3" para usar el conda Python
RUN ln -sf /opt/conda/bin/python /usr/local/bin/python3

# Instalar s6-overlay v3
ARG S6_OVERLAY_VERSION=3.1.6.2
RUN curl -L "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" | tar -C / -Jxpf - \
    && curl -L "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz" | tar -C / -Jxpf -

# Crear usuario para SSH
RUN useradd -m -s /bin/bash dockeruser && \
    echo "dockeruser:password123" | chpasswd && \
    usermod -aG sudo dockeruser

# Configurar SSH
RUN mkdir -p /var/run/sshd && \
    echo 'root:root123' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Crear directorio de trabajo
WORKDIR /app

# Copiar requirements y instalar dependencias PRIMERO
COPY requirements.txt /app/
RUN conda install -c conda-forge -y numpy==1.24.3 && \
    pip install --no-cache-dir -r requirements.txt && \
    pip cache purge

# Copiar configuración s6-overlay DESPUÉS
COPY s6-overlay-fixed/ /etc/s6-overlay/

# Dar permisos de ejecución a los scripts
RUN find /etc/s6-overlay/s6-rc.d -name "run" -type f -exec chmod +x {} \; \
    && find /etc/s6-overlay/s6-rc.d -name "finish" -type f -exec chmod +x {} \;

# Variables de entorno para s6-overlay
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_LOGGING=1 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_KEEP_ENV=1

# Variables de entorno por defecto para servicios
ENV OPENAI_API_BASE_URL=http://localhost:8000/v1 \
    OPENAI_API_KEY=sk-fake-key \
    PORT=27015 \
    DATA_DIR=/app/open-webui-data \
    VLLM_HOST=0.0.0.0 \
    VLLM_PORT=8000 \
    VLLM_GPU_MEMORY_UTILIZATION=0.85 \
    VLLM_MODEL=NousResearch/Meta-Llama-3-8B-Instruct

# Crear directorio de datos
RUN mkdir -p /app/open-webui-data

# Exponer puertos
EXPOSE 22 8000 27015

# CRÍTICO: ENTRYPOINT debe ser /init para s6-overlay
ENTRYPOINT ["/init"]