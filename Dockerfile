FROM pytorch/pytorch:2.7.1-cuda12.8-cudnn9-runtime

# SSH Base Image with PyTorch and CUDA

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
# Ensure PATH includes Conda binaries
ENV PATH="/opt/conda/bin:$PATH"

# Install SSH server and necessary packages
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

# Force "python3" to be the conda Python
RUN ln -sf /opt/conda/bin/python /usr/local/bin/python3

# Configure SSH
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/' /etc/ssh/sshd_config

# SSH access files (empty authorized_keys)
RUN mkdir -p /root/.ssh/ && echo '' > /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys

# Activate Conda environment on shell startup (for interactive shells)
RUN echo "source /opt/conda/etc/profile.d/conda.sh && conda activate base" >> /root/.bashrc

WORKDIR /app

# Base SSH image - no application packages installed
# Application-specific packages should be installed in derived images

EXPOSE 22 27015

# Default command: SSH daemon
CMD ["/usr/sbin/sshd", "-D"]