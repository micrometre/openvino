import numpy as np
import openvino as ov
import sys
import os
try:
    import pkg_resources
except ImportError:
    from packaging.version import Version
    sys.modules['pkg_resources'] = type('pkg_resources', (), {'parse_version': staticmethod(Version)})()
import tensorflow as tf
import tensorflow_hub as hub

model_url = "https://kaggle.com/models/google/mobilenet-v2/TensorFlow1/openimages-v4-ssd-mobilenet-v2/1"
detector = hub.load(model_url)
print("Loaded detector from hub")

try:
    print("Trying convert_model on detector directly with input shape")
    ov_model = ov.convert_model(detector, input=[1, 320, 320, 3])
    print("Success 1!")
    sys.exit(0)
except Exception as e:
    print(f"Failed 1: {e}")

try:
    print("Trying convert_model on signatures['default']")
    ov_model = ov.convert_model(detector.signatures['default'], input=[1, 320, 320, 3])
    print("Success 2!")
    sys.exit(0)
except Exception as e:
    print(f"Failed 2: {e}")

try:
    print("Trying tf.function wrap")
    @tf.function(input_signature=[tf.TensorSpec(shape=[1, 320, 320, 3], dtype=tf.float32, name="images")])
    def serving_fn(images):
        return detector.signatures['default'](images)
    
    concrete_func = serving_fn.get_concrete_function()
    ov_model = ov.convert_model(concrete_func)
    print("Success 3!")
    sys.exit(0)
except Exception as e:
    print(f"Failed 3: {e}")
