#!/usr/bin/env bash

# Log file path
LOG_FILE="/workspace/SimpleTuner/train.log"
# Empty the log file
touch "$LOG_FILE"

# Redirect stdout and stderr to both the console and the log file
exec > >(while read -r line; do echo "$(date '+%Y-%m-%d %H:%M:%S') $line"; done | tee -a "$LOG_FILE") 2>&1

# Navigate to the SimpleTuner directory
cd /workspace/SimpleTuner

# Activate the virtual environment
source .venv/bin/activate

# Login to WandB using the environment variable if not already logged in
if [ -n "${WANDB_API_KEY}" ] && [ ! -f "$HOME/.netrc" ]; then
    echo "Logging into WandB..."
    wandb login "${WANDB_API_KEY}" --relogin
else
    echo "WANDB_API_KEY is not set or WandB is already logged in."
fi

# Login to Hugging Face using the environment variable if not already logged in
if [ -n "${HUGGING_FACE_HUB_TOKEN}" ]; then
    # Ensure Hugging Face CLI is logged in by checking token presence
    if [ ! -f "$HOME/.huggingface/token" ]; then
        echo "Logging into Hugging Face..."
        huggingface-cli login --token "${HUGGING_FACE_HUB_TOKEN}"
        if [ $? -ne 0 ]; then
            echo "Error: Hugging Face login failed. Check your HUGGING_FACE_HUB_TOKEN."
            exit 1
        fi
    else
        echo "Hugging Face CLI is already logged in."
    fi
else
    echo "Error: HUGGING_FACE_HUB_TOKEN is not set."
    exit 1
fi


# Pull config from config.env
[ -f "config/config.env" ] && source config/config.env

# If the user has not provided VENV_PATH, we will assume $(pwd)/.venv
if [ -z "${VENV_PATH}" ]; then
    # what if we have VIRTUAL_ENV? use that instead
    if [ -n "${VIRTUAL_ENV}" ]; then
        export VENV_PATH="${VIRTUAL_ENV}"
    else
        export VENV_PATH="$(pwd)/.venv"
    fi
fi
if [ -z "${DISABLE_LD_OVERRIDE}" ]; then
    export NVJITLINK_PATH="$(find "${VENV_PATH}" -name nvjitlink -type d)/lib"
    # if it's not empty, we will add it to LD_LIBRARY_PATH at the front:
    if [ -n "${NVJITLINK_PATH}" ]; then
        export LD_LIBRARY_PATH="${NVJITLINK_PATH}:${LD_LIBRARY_PATH}"
    fi
fi

export TOKENIZERS_PARALLELISM=false
export PLATFORM
PLATFORM=$(uname -s)
if [[ "$PLATFORM" == "Darwin" ]]; then
    export MIXED_PRECISION="no"
fi

if [ -z "${ACCELERATE_EXTRA_ARGS}" ]; then
    ACCELERATE_EXTRA_ARGS=""
fi

if [ -z "${TRAINING_NUM_PROCESSES}" ]; then
    echo "Set custom env vars permanently in config/config.env:"
    printf "TRAINING_NUM_PROCESSES not set, defaulting to 1.\n"
    TRAINING_NUM_PROCESSES=1
fi

if [ -z "${TRAINING_NUM_MACHINES}" ]; then
    printf "TRAINING_NUM_MACHINES not set, defaulting to 1.\n"
    TRAINING_NUM_MACHINES=1
fi

if [ -z "${MIXED_PRECISION}" ]; then
    printf "MIXED_PRECISION not set, defaulting to bf16.\n"
    MIXED_PRECISION=bf16
fi

if [ -z "${TRAINING_DYNAMO_BACKEND}" ]; then
    printf "TRAINING_DYNAMO_BACKEND not set, defaulting to no.\n"
    TRAINING_DYNAMO_BACKEND="no"
fi

if [ -z "${ENV}" ]; then
    printf "ENV not set, defaulting to default.\n"
    export ENV="default"
fi
export ENV_PATH=""
if [[ "$ENV" != "default" ]]; then
    export ENV_PATH="${ENV}/"
fi

if [ -z "${CONFIG_BACKEND}" ]; then
    if [ -n "${CONFIG_TYPE}" ]; then
        export CONFIG_BACKEND="${CONFIG_TYPE}"
    fi
fi

if [ -z "${CONFIG_BACKEND}" ]; then
    export CONFIG_BACKEND="env"
    export CONFIG_PATH="config/${ENV_PATH}config"
    if [ -f "${CONFIG_PATH}.json" ]; then
        export CONFIG_BACKEND="json"
    elif [ -f "${CONFIG_PATH}.toml" ]; then
        export CONFIG_BACKEND="toml"
    elif [ -f "${CONFIG_PATH}.env" ]; then
        export CONFIG_BACKEND="env"
    fi
    echo "Using ${CONFIG_BACKEND} backend: ${CONFIG_PATH}.${CONFIG_BACKEND}"
fi

# Update dependencies
if [ -z "${DISABLE_UPDATES}" ]; then
    echo 'Updating dependencies. Set DISABLE_UPDATES to prevent this.'
    if [ -f "pyproject.toml" ] && [ -f "poetry.lock" ]; then
        nvidia-smi 2> /dev/null && poetry install
        uname -s | grep -q Darwin && poetry install -C install/apple
        rocm-smi 2> /dev/null && poetry install -C install/rocm
    fi
fi
# Run the training script.
if [[ -z "${ACCELERATE_CONFIG_PATH}" ]]; then
    ACCELERATE_CONFIG_PATH="${HOME}/.cache/huggingface/accelerate/default_config.yaml"
fi
if [ -f "${ACCELERATE_CONFIG_PATH}" ]; then
    echo "Using Accelerate config file: ${ACCELERATE_CONFIG_PATH}"
    accelerate launch --config_file="${ACCELERATE_CONFIG_PATH}" train.py
else
    echo "Accelerate config file not found: ${ACCELERATE_CONFIG_PATH}. Using values from config.env."
    accelerate launch ${ACCELERATE_EXTRA_ARGS} --mixed_precision="${MIXED_PRECISION}" --num_processes="${TRAINING_NUM_PROCESSES}" --num_machines="${TRAINING_NUM_MACHINES}" --dynamo_backend="${TRAINING_DYNAMO_BACKEND}" train.py

fi

# Verify successful training and write status
if [ $? -eq 0 ]; then
    echo "Training completed successfully at $(date)" >> "$LOG_FILE"
    echo "Writing TRAINING_COMPLETE to /workspace/SimpleTuner/status.txt"
    echo "TRAINING_COMPLETE" >> "/workspace/SimpleTuner/status.txt"

else
    echo "Training failed at $(date). Check logs for details." >> "$LOG_FILE"
    echo "Writing TRAINING_FAILED to /workspace/SimpleTuner/status.txt"
    echo "TRAINING_FAILED" >> "/workspace/SimpleTuner/status.txt"
    exit 1
fi

exit 0
