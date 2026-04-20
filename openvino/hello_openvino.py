#!/usr/bin/env python3
"""
Minimal OpenVINO Hello World Example
Demonstrates basic OpenVINO inference on Intel Iris Xe GPU
"""

import numpy as np
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
    print("Intel OpenVINO Hello World Example")
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
    
    # Create a simple model using NumPy and OpenVINO's Model API
    print("🧠 Creating a simple model...")
    
    model = None
    input_param = None
    try:
        # Create a simple model: output = input + constant matrix
        input_param = opset13.parameter([2, 2], np.float32, name="input")
        const = opset13.constant(np.array([[1.0, 2.0], [3.0, 4.0]], dtype=np.float32))
        add = opset13.add(input_param, const)

        model = Model([add], [input_param], "simple_add")
        print("✓ Model created: Simple addition operation")
    except ImportError:
        # If graph ops are unavailable, continue with NumPy-only fallback.
        print("⚠️  Using simplified numpy demonstration instead...")
        print("✓ Ready for inference")
    
    print()
    
    # Create sample input data
    print("📊 Creating sample input data...")
    input_data = np.array([[1.0, 2.0], [3.0, 4.0]], dtype=np.float32)
    print(f"Input shape: {input_data.shape}")
    print(f"Input data:\n{input_data}")
    print()
    
    # Compile and infer
    print("⚡ Compiling model (GPU device preferred)...")
    try:
        if model is None or input_param is None:
            raise RuntimeError("No OpenVINO graph model available")

        # Try to use GPU (Iris Xe)
        device = "GPU" if "GPU" in devices else "CPU"
        print(f"Using device: {device}")

        compiled_model = core.compile_model(model, device)
        print(f"✓ Model compiled for {device}")
        print()

        # Run inference
        print("🚀 Running inference...")
        infer_request = compiled_model.create_infer_request()
        infer_request.infer({"input": input_data})
        output = infer_request.get_output_tensor().data

        print("✓ Inference complete")
        print()
        print(f"Output shape: {output.shape}")
        print(f"Output data:\n{output}")

    except Exception as e:
        print(f"⚠️  Could not run OpenVINO inference: {e}")
        print()
        print("📝 Simple NumPy demonstration:")
        result = input_data + np.array([[1.0, 2.0], [3.0, 4.0]])
        print(f"Result:\n{result}")
    
    print()
    print("=" * 60)
    print("✓ Hello World Complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
