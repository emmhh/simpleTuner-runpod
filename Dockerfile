# Use the RunPod PyTorch image as the base
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# /workspace is the default volume for Runpod & other hosts
WORKDIR /workspace

# Update apt-get
RUN apt-get update -y

# Prevents different commands from being stuck by waiting
# on user input during build
ENV DEBIAN_FRONTEND=noninteractive

# Install libg dependencies
RUN apt install libgl1-mesa-glx -y
RUN apt-get install 'ffmpeg'\
    'libsm6'\
    'libxext6'  -y

    RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
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
        7zip \
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

# Set up git to support LFS, and to store credentials; useful for Huggingface Hub
RUN git config --global credential.helper store && \
    git lfs install

# # Install Python VENV
# RUN apt-get install -y python3.10-venv

#setup port for jupyter notebook    
EXPOSE 8888 22

# # Python
# RUN apt-get update -y && apt-get install -y python3.11 python3.11-pip
# RUN python3.11 -m pip install pip --upgrade

# HF
ENV HF_HOME=/workspace/huggingface

RUN pip install "huggingface_hub[cli]"

# WanDB
RUN pip install wandb

# Clone SimpleTuner
RUN git clone https://github.com/chrevdog/SimpleTuner --branch clean-poetry
# RUN git clone https://github.com/bghira/SimpleTuner --branch main # Uncomment to use latest (possibly unstable) version

# Install SimpleTuner
RUN pip install poetry
RUN cd SimpleTuner && python -m venv .venv && poetry install --no-root
RUN chmod +x SimpleTuner/train.sh

# Copy the custom start script
COPY docker-start.sh /start.sh

# Explicitly set execution permissions
RUN chmod +x /start.sh

# Dummy entrypoint
ENTRYPOINT [ "/start.sh" ]
