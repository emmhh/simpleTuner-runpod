# Use the RunPod PyTorch image as the base
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# Set the default working directory
WORKDIR /workspace

# Install common dependencies and utilities
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        git \
        wget \
        curl \
        vim \
        openssh-client \
        openssh-server \
        python3.11 \
        python3.11-venv \
        nvidia-cuda-toolkit \
        ocl-icd-libopencl1 \
        libgl1-mesa-dri && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# RUN apt-get install -y ca-certificates-java && \
#     /var/lib/dpkg/info/ca-certificates-java.postinst configure


# Install Python packages and Jupyter
# RUN python3.11 -m pip install --upgrade pip && \
# pip install jupyterlab simple-tuner 
# Add other required packages here

# # Install any common dependencies that should be baked into the image
# RUN apt-get update -y && \
#     apt-get install -y --no-install-recommends git wget curl vim

#setup port for jupyter notebook    
EXPOSE 8888 22

# Clone the SimpleTuner repository at build time if it doesn't change often
RUN git clone --branch=release https://github.com/chrevdog/SimpleTuner.git /workspace/SimpleTuner

# Install Python dependencies
RUN python3.11 -m venv /workspace/SimpleTuner/.venv && \
    /workspace/SimpleTuner/.venv/bin/pip install -U pip && \
    /workspace/SimpleTuner/.venv/bin/pip install poetry && \
    cd /workspace/SimpleTuner && \
    .venv/bin/poetry install --no-root

# Copy the custom start script
COPY docker-start.sh /start.sh

# Explicitly set execution permissions
RUN chmod +x /start.sh

# Set the entrypoint to your custom start script
ENTRYPOINT [ "/start.sh" ]

    # # Copy the custom start and post-start scripts with execution permissions
#COPY --chmod=755 docker-start.sh /start.sh
# # COPY --chmod=755 docker-post-start.sh /docker-post-start.sh

# # Set the entrypoint to your custom start script
# ENTRYPOINT [ "/start.sh" ]
