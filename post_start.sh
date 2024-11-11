#!/usr/bin/env bash

# Navigate to the SimpleTuner directory
cd /workspace/simpletuner

# Create or overwrite the config.env file in the config directory
cat <<EOL > config/config.env
# Accelerate configuration settings
TRAINING_NUM_PROCESSES=1
TRAINING_NUM_MACHINES=1
MIXED_PRECISION=bf16
TRAINING_DYNAMO_BACKEND=no

# Additional optional settings
DISABLE_UPDATES=true
DISABLE_LD_OVERRIDE=false
ACCELERATE_EXTRA_ARGS="--num_cpu_threads_per_process 1"
EOL

echo "config.env file created successfully at /workspace/simpletuner/config/config.env"

# Activate the virtual environment
source .venv/bin/activate

# Install the required package
pip install optimum-quanto

# Keep the virtual environment active
exec "$SHELL"
