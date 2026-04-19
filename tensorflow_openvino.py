#!/usr/bin/env python3
"""
Minimal OpenVINO Hello World Example
Demonstrates basic OpenVINO inference on Intel Iris Xe GPU with TensorFlow
"""

import numpy as np
import tensorflow as tf
try:
    # OpenVINO 2024+ style
    from openvino import Core, Model, opset13
except ImportError:
    # Backward-compatible imports for older runtime layouts
    from openvino.runtime import Core  # type: ignore
    from openvino.runtime import Model  # type: ignore
    from openvino.runtime import opset13  # type: ignore

def main():
    print("=" * 60)
    print("Intel OpenVINO TensorFlow Hello World Example")
    print("=" * 60)
    print()
    
    # Initialize OpenVINO Core
    print("📦 Initializing OpenVINO Core...")
    core = Core()
    print("✓ OpenVINO Core initialized")
    print() 
    
    # List available devices
    print("🖥️  Available devices:")
    devices = core.available_devices
    for device in devices:
        device_name = core.get_property(device, "FULL_DEVICE_NAME")
        print(f"  • {device}: {device_name}")
    print()
    
    # Create a simple TensorFlow model
    print("🧠 Creating a simple TensorFlow model...")   
