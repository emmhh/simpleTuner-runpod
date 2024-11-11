#!/usr/bin/env bash

# Navigate to the SimpleTuner directory
cd /workspace/SimpleTuner

# Activate the virtual environment
source .venv/bin/activate

# Login to WandB using the environment variable
if [ -n "${WANDB_API_KEY}" ]; then
    wandb login "${WANDB_API_KEY}" --relogin
else
    echo "WANDB_API_KEY is not set."
fi

# Login to Hugging Face using the environment variable
if [ -n "${HUGGING_FACE_HUB_TOKEN}" ]; then
    echo "${HUGGING_FACE_HUB_TOKEN}" | huggingface-cli login --token
else
    echo "HUGGING_FACE_HUB_TOKEN is not set."
fi

# Install the required package
pip install optimum-quanto

# Keep the virtual environment active
exec "$SHELL"