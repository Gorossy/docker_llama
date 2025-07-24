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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Forzar "python3" para usar el conda Python
RUN ln -sf /opt/conda/bin/python /usr/local/bin/python3

# Crear usuario para SSH
RUN useradd -m -s /bin/bash dockeruser && \
    echo "dockeruser:password123" | chpasswd && \
    usermod -aG sudo dockeruser

# Configurar SSH
RUN mkdir -p /var/run/sshd && \
    echo 'root:root123' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Instalar s6-overlay
RUN wget -qO- https://github.com/just-containers/s6-overlay/releases/download/v3.1.6.2/s6-overlay-noarch.tar.xz | tar -Jxpf - -C / && \
    wget -qO- https://github.com/just-containers/s6-overlay/releases/download/v3.1.6.2/s6-overlay-x86_64.tar.xz | tar -Jxpf - -C /

# Configurar variables de entorno
ENV S6_OVERLAY_VERSION=3.1.6.2
ENV S6_KEEP_ENV=1
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

# Crear directorio de trabajo
WORKDIR /app

# Copiar archivos de configuración
COPY s6-overlay/ /etc/s6-overlay/
COPY requirements.txt /app/
COPY docker-entrypoint.sh /app/

# Dar permisos de ejecución a los scripts de s6-overlay
RUN chmod +x /etc/s6-overlay/s6-rc.d/user/*/run /etc/s6-overlay/s6-rc.d/user/*/finish

# Instalar dependencias de Python usando conda
RUN conda install -c conda-forge -y numpy==1.24.3 && \
    pip install --no-cache-dir -r requirements.txt && \
    pip cache purge

# Hacer ejecutable el script de entrada
RUN chmod +x /app/docker-entrypoint.sh

# Exponer puertos
EXPOSE 22 8000 27015

# Configurar el punto de entrada
ENTRYPOINT ["/app/docker-entrypoint.sh"] 