#!/usr/bin/env bash

# Navigate to the SimpleTuner directory
cd /workspace/simpletuner

# Activate the virtual environment
source .venv/bin/activate

# Login to WandB using the environment variable
wandb login "${WANDB_API_KEY}" --relogin

# Login to Hugging Face using the environment variable
echo "${HUGGING_FACE_HUB_TOKEN}" | huggingface-cli login --token

# Install the required package
pip install optimum-quanto

# Keep the virtual environment active
exec "$SHELL"