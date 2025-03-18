#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -o pipefail  # Prevent errors in a pipeline from being masked

echo "Updating package list..."
sudo apt update

# echo "Installing Python 3.11 and virtual environment tools..."
# sudo apt -y install python3.11 python3.11-venv python3.11-dev git build-essential

echo "Cloning SimpleTuner repository..."
git clone --branch=release https://github.com/bghira/SimpleTuner.git

cd SimpleTuner

echo "Creating and activating virtual environment..."
python -m venv .venv
source .venv/bin/activate

echo "Upgrading pip and installing Poetry..."
pip install -U poetry pip

echo "Configuring Poetry to disable automatic virtual environments..."
poetry config virtualenvs.create false

echo "Installing project dependencies with Poetry..."
poetry install

echo "Environment setup complete!"
echo "Run 'source .venv/bin/activate' to activate the virtual environment."
echo "Run 'wandb login' to login to wandb"
echo "Run 'huggingface-cli login' to login to huggingface"
echo "Run 'cd SimpleTuner' to go to the project directory"
echo "Run './train.sh' to start training"