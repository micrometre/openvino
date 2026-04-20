import numpy as np
import openvino as ov
import tensorflow as tf

# Load TensorFlow model into memory
model = tf.keras.applications.MobileNetV2(weights='imagenet')

# Workaround for Keras 3 + OpenVINO incompatibility:
# In Keras 3, model.input.name returns 'keras_tensor' instead of the actual
# input layer name (e.g. 'input_layer'). OpenVINO's tracing wrapper uses
# model.input.name as the dict key, which causes a mismatch. Fix: manually
# trace to a ConcreteFunction using a TensorSpec named after the real input
# layer, then pass that ConcreteFunction to convert_model.
input_layer_name = model.layers[0].name          # e.g. 'input_layer'
input_shape = list(model.input.shape)        # [None, 224, 224, 3]
input_dtype = model.input.dtype                  # float32

input_spec = tf.TensorSpec(shape=input_shape, dtype=input_dtype, name=input_layer_name)

@tf.function(input_signature=[input_spec])
def serving_fn(x):
    return model(x)

concrete_func = serving_fn.get_concrete_function()

# Convert the ConcreteFunction (OpenVINO handles this path without Keras 3 issues)
ov_model = ov.convert_model(concrete_func)

# Save the model to disk as OpenVINO IR format (.xml graph + .bin weights)
ov.save_model(ov_model, "mobilenetv2.xml")
print("Model saved to mobilenetv2.xml / mobilenetv2.bin")

# Compile the model for CPU device
core = ov.Core()
compiled_model = core.compile_model(ov_model, 'GPU')

# Infer the model on random data
data = np.random.rand(1, 224, 224, 3).astype(np.float32)
output = compiled_model({0: data})
print("Inference successful, output shape:", output[0].shape)