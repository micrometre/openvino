#!/usr/bin/env bash
# ============================================
# llama.cpp Global Installation Script
# Installs pre-built OpenVINO binaries globally
# ============================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCHIVE_NAME="llama-b9994-bin-ubuntu-openvino-2026.2.1-x64.tar.gz"
ARCHIVE_PATH="${SCRIPT_DIR}/${ARCHIVE_NAME}"
EXTRACT_DIR="${SCRIPT_DIR}/llama-b9994"
DOWNLOAD_URL="https://release-assets.githubusercontent.com/github-production-release-asset/612354784/4e91db18-cfe5-4745-a60e-b0a81f5d84ce?sp=r&sv=2018-11-09&sr=b&spr=https&se=2026-07-14T07%3A47%3A57Z&rscd=attachment%3B+filename%3Dllama-b9994-bin-ubuntu-openvino-2026.2.1-x64.tar.gz&rsct=application%2Foctet-stream&skoid=96c2d410-5711-43a1-aedd-ab1947aa7ab0&sktid=398a6654-997b-47e9-b12b-9515b896b4de&skt=2026-07-14T06%3A47%3A12Z&ske=2026-07-14T07%3A47%3A57Z&sks=b&skv=2018-11-09&sig=GBD1NcaZQXbdzoAQzO49dv3JE4LjreDZWlcXs9%2BSEoA%3D&jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmVsZWFzZS1hc3NldHMuZ2l0aHVidXNlcmNvbnRlbnQuY29tIiwia2V5Ijoia2V5MSIsImV4cCI6MTc4NDAxNTAxNCwibmJmIjoxNzg0MDEzMjE0LCJwYXRoIjoicmVsZWFzZWFzc2V0cHJvZHVjdGlvbi5ibG9iLmNvcmUud2luZG93cy5uZXQifQ.ItRso_2l9B1HEb2fTFqbecZbwedAc2L1pXto4rUzUbw&response-content-disposition=attachment%3B%20filename%3Dllama-b9994-bin-ubuntu-openvino-2026.2.1-x64.tar.gz&response-content-type=application%2Foctet-stream"

echo "============================================"
echo "llama.cpp Global Installation"
echo "============================================"

# Download archive if not present
if [[ ! -f "${ARCHIVE_PATH}" ]]; then
    echo "Archive not found. Downloading from GitHub..."
    curl -L -o "${ARCHIVE_PATH}" "${DOWNLOAD_URL}"
    echo "Download complete."
fi

# Extract archive if not already extracted
if [[ ! -d "${EXTRACT_DIR}" ]]; then
    echo "Extracting ${ARCHIVE_NAME}..."
    tar -xzf "${ARCHIVE_PATH}" -C "${SCRIPT_DIR}"
    echo "Extraction complete."
else
    echo "Archive already extracted at ${EXTRACT_DIR}"
fi

# Install binaries
echo "============================================"
echo "Installing binaries to /usr/local/bin/..."
echo "============================================"
sudo cp "${EXTRACT_DIR}"/llama-* /usr/local/bin/
sudo chmod +x /usr/local/bin/llama-*

# Install libraries
echo "============================================"
echo "Installing libraries to /usr/local/lib/..."
echo "============================================"
sudo cp "${EXTRACT_DIR}"/lib*.so* /usr/local/lib/

# Update library cache
echo "============================================"
echo "Updating library cache..."
echo "============================================"
sudo ldconfig

echo "============================================"
echo "Installation complete!"
echo "============================================"
echo "Binaries installed: /usr/local/bin/"
echo "Libraries installed: /usr/local/lib/"
echo
echo "To use OpenVINO acceleration:"
echo "  export GGML_OPENVINO_DEVICE=CPU  # or GPU / NPU"
echo "  llama-cli -m model.gguf"
