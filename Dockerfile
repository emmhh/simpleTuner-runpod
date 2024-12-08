# Use the RunPod PyTorch image as the base
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# Set default working directory
WORKDIR /workspace

# Prevent interactive prompts during apt operations
ENV DEBIAN_FRONTEND=noninteractive

# Install apt dependencies and clean up
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        libgl1-mesa-glx \
        ffmpeg \
        libsm6 \
        libxext6 \
        openssh-server \
        openssh-client \
        git \
        git-lfs \
        wget \
        curl \
        tmux \
        tldr \
        nvtop \
        vim \
        rsync \
        net-tools \
        less \
        iputils-ping \
        p7zip-full \
        zip \
        unzip \
        htop \
        inotify-tools \
        python3.11 \
        python3.11-venv \
        nvidia-cuda-toolkit \
        ocl-icd-libopencl1 \
        libgl1-mesa-dri && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up git and install git-lfs
RUN git config --global credential.helper store && git lfs install

# Expose ports for Jupyter Notebook and SSH
EXPOSE 8888 22

# Install Python packages
RUN pip install --no-cache-dir \
    wandb \
    poetry \
    "huggingface_hub[cli]"

# Configure Poetry
RUN poetry config virtualenvs.create false

# Copy and set up the SimpleTuner application
COPY . /workspace/SimpleTuner
RUN cd /workspace/SimpleTuner && \
    python -m venv .venv && \
    poetry install --no-root && \
    chmod +x train.sh

# Copy custom scripts and set permissions
COPY docker-start.sh /start.sh
COPY post_start.sh /post_start.sh
RUN chmod +x /start.sh /post_start.sh
RUN apt-get update && apt-get install -y dos2unix && \
    dos2unix /start.sh /post_start.sh

# Set entrypoint
ENTRYPOINT [ "/start.sh" ]
