import numpy as np
import openvino as ov
import tensorflow as tf

# Load TensorFlow model into memory
model = tf.keras.applications.MobileNetV2(weights='imagenet')

# OpenVINO 2024.x is incompatible with Keras 3.x direct model conversion:
# its internal wrapper passes inputs as {'keras_tensor': ...} but Keras 3.x
# expects the layer name as the key (e.g. 'input_layer').
# Workaround: trace to a concrete TF function first, then convert that.
@tf.function(input_signature=[tf.TensorSpec([1, 224, 224, 3], tf.float32)])
def model_fn(x):
    return model(x)

concrete_fn = model_fn.get_concrete_function()

# Convert the concrete function to an OpenVINO model
ov_model = ov.convert_model(concrete_fn)

# Compile the model for CPU device
core = ov.Core()
compiled_model = core.compile_model(ov_model, 'CPU')

# Infer the model on random data
data = np.random.rand(1, 224, 224, 3).astype(np.float32)
output = compiled_model({0: data})
print("Inference successful. Output shape:", list(output.values())[0].shape)
