#!/bin/bash

set -e

echo "🖥️  Setting up "
echo "=================================================================="


# Create virtual environment
echo "📦 Creating virtual environment..."
python3 -m venv .venv
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



echo ""
echo "🎉 Setup completed successfully "
echo "=================================================================="
echo ""