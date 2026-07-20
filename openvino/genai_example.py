import huggingface_hub as hf_hub
import openvino_genai as ov_genai

device = "GPU"  # or "CPU"
model_id = "OpenVINO/TinyLlama-1.1B-Chat-v1.0-fp16-ov"
model_path = "TinyLlama-1.1B-Chat-v1.0-fp16-ov"

hf_hub.snapshot_download(model_id, local_dir=model_path)

pipe = ov_genai.LLMPipeline(model_path, device)
print(pipe.generate("What is OpenVINO?", max_length=200))
