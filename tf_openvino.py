#!/usr/bin/env python3
"""
Minimal OpenVINO TensorFlow Example
Demonstrates basic OpenVINO inference on Intel Iris Xe GPU
"""

import tensorflow as tf
import openvino as ov





# load TensorFlow model into memory
model = tf.keras.applications.MobileNetV2(weights='imagenet')


core = ov.Core()

def main():
    devices = core.available_devices
    for device in devices:
        device_name = core.get_property(device, "FULL_DEVICE_NAME")
        print(f"  • {device}: {device_name}")
    print()
    
    


if __name__ == "__main__":
    main()
