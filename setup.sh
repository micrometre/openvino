#!/bin/bash

set -e

echo "🖥️  Setting up "
echo "=================================================================="


# Create virtual environment
echo "📦 Creating virtual environment..."
python3.12 -m venv .venv
echo "✅ Virtual environment created in .venv/"

# Activate virtual environment
source .venv/bin/activate
echo "✅ Virtual environment activated"

# Upgrade pip
echo "⬆️  Upgrading pip..."
pip install --upgrade pip
pip install setuptools

# Install requirements 
echo "📥 Installing  dependencies..."
pip install -r requirements.txt
python -m pip install "optimum-intel[openvino]"@git+https://github.com/huggingface/optimum-intel.git



echo ""
echo "🎉 Setup completed successfully "
echo "=================================================================="
echo ""