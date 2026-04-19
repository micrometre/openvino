# Intel Iris Xe GPU with OpenVINO

Intel Raptor Lake-P [Iris Xe Graphics] setup for Ubuntu 24.04

## Overview

This repository provides a complete setup for leveraging Intel Iris Xe Graphics with OpenVINO on Ubuntu 24.04. It includes object detection examples using MobileNet models optimized for inference on Intel integrated GPUs.

## Features

- **OpenVINO Integration**: Latest OpenVINO 2024+ runtime for optimized inference
- **Intel Iris Xe Support**: GPU acceleration for compatible Intel processors
- **Object Detection**: Pre-configured MobileNet v1 and v2 models (SSD variants)
- **Easy Setup**: Automated installation and configuration scripts
- **Multi-Device Support**: CPU, GPU, and other device backends

## Requirements

- **OS**: Ubuntu 24.04 LTS
- **CPU**: Intel Raptor Lake or compatible processor with Iris Xe Graphics
- **RAM**: 4GB minimum (8GB recommended)
- **Python**: 3.8 or higher

## Installation

### 1. Clone and Setup

```bash
git clone <repository-url>
cd intel-iris
chmod +x *.sh
```

### 2. Automated Setup

Run the main setup script:

```bash
./setup.sh
```

This will:
- Create a Python virtual environment
- Install OpenVINO dependencies
- Download necessary models
- Configure GPU drivers if needed

### 3. Manual Component Installation

If you need to install components separately:

```bash
# Install OpenVINO only
./install_openvino.sh

# Install GPU drivers
./install_driver.sh
```

## Usage

### Hello World Example

Test your OpenVINO installation:

```bash
source .venv/bin/activate
python hello_openvino.py
```

### Object Detection

Run object detection on an image:

```bash
python mobilenetv2_object_detection.py \
  --device CPU \
  --image images/1.jpg \
  --threshold 0.3 \
  --debug
```

#### Arguments:
- `--device`: Target device (`CPU`, `GPU`, `AUTO`)
- `--image`: Path to input image
- `--threshold`: Detection confidence threshold (0.0-1.0)
- `--debug`: Enable debug output

### TensorFlow Integration

For TensorFlow-based inference:

```bash
python tensorflow_openvino.py
```

## Project Structure

```
intel-iris/
├── hello_openvino.py              # Hello World example
├── mobilenetv2_object_detection.py # MobileNet v2 object detection
├── tensorflow_openvino.py          # TensorFlow integration example
├── setup.sh                        # Main setup script
├── install_openvino.sh             # OpenVINO installation
├── install_driver.sh               # GPU driver installation
├── uninstall_*.sh                  # Cleanup scripts
├── requirements.txt                # Python dependencies
├── images/                         # Sample images for testing
└── models/
    └── public/
        ├── ssd_mobilenet_v1_fpn_coco/
        └── ssdlite_mobilenet_v2/
```

## Dependencies

- **openvino**: OpenVINO inference engine and runtime
- **openvino-dev**: OpenVINO development tools
- **numpy**: Numerical computing
- **tensorflow**: Optional, for TensorFlow model support

See `requirements.txt` for specific versions.

## Uninstallation

To remove OpenVINO or GPU drivers:

```bash
./uninstall_openvino.sh
./uninstall_driver.sh
```

## Troubleshooting

### GPU Not Detected

1. Check Intel GPU drivers:
   ```bash
   lspci | grep -i graphics
   ```

2. Verify OpenVINO can see the device:
   ```bash
   python hello_openvino.py --debug
   ```

3. Reinstall GPU drivers:
   ```bash
   ./install_driver.sh
   ```

### Memory Issues

- Use CPU backend instead of GPU for initial testing
- Reduce model complexity or input image size
- Check available system memory: `free -h`

### Import Errors

Ensure virtual environment is activated:

```bash
source .venv/bin/activate
pip install -r requirements.txt
```

## References

- [OpenVINO Official Documentation](https://docs.openvino.ai/)
- [Intel Iris Xe Graphics](https://www.intel.com/content/www/us/en/products/details/graphics/100-series.html)
- [MobileNet Models](https://github.com/openvinotoolkit/open_model_zoo)

## License

[Add your license information here]

## Contributing

Contributions are welcome! Please ensure:
- Code follows PEP 8 standards
- All scripts are tested on Ubuntu 24.04
- Documentation is updated for new features
