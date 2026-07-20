#!/usr/bin/env python3
"""
MobileNetV2 object detection example with OpenVINO.

This script downloads and converts the Open Model Zoo model
`ssd_mobilenet_v2_coco`, runs inference on a sample image, and prints
detections above a confidence threshold.
"""

from __future__ import annotations

import argparse
import importlib
import shutil
import subprocess
from pathlib import Path
from typing import Any

import numpy as np

try:
    import openvino as ov
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "OpenVINO is not installed in this environment. "
        "Run: pip install -U openvino"
    ) from exc


MODEL_NAME_CANDIDATES = [
    "ssd_mobilenet_v1_fpn_coco",
    "ssd_mobilenet_v1_coco",
    "ssdlite_mobilenet_v2",
]
MODELS_ROOT = Path("models")
ANNOTATED_IMAGE = Path("detections.jpg")


def run_cmd(args: list[str]) -> None:
    print(f"$ {' '.join(args)}")
    subprocess.run(args, check=True)


def pick_available_model_name(downloader_bin: str, requested: str | None) -> str:
    result = subprocess.run(
        [downloader_bin, "--print_all"],
        check=True,
        capture_output=True,
        text=True,
    )
    available = {line.strip() for line in result.stdout.splitlines() if line.strip()}

    if requested:
        if requested in available:
            return requested
        raise SystemExit(
            f"Requested model '{requested}' is not available in this OMZ package.\n"
            "Run `omz_downloader --print_all` to list supported names."
        )

    for candidate in MODEL_NAME_CANDIDATES:
        if candidate in available:
            return candidate

    raise SystemExit(
        "No supported MobileNet SSD model was found in this OMZ package.\n"
        "Tried: " + ", ".join(MODEL_NAME_CANDIDATES)
    )


def ensure_omz_model(model_name: str | None, output_root: Path, precision: str) -> Path:
    downloader = shutil.which("omz_downloader")
    converter = shutil.which("omz_converter")
    if not downloader or not converter:
        raise SystemExit(
            "Open Model Zoo tools are not available.\n"
            "Install them with: pip install -U openvino-dev"
        )

    output_root.mkdir(parents=True, exist_ok=True)
    chosen_model = pick_available_model_name(downloader, model_name)
    print(f"Using OMZ model: {chosen_model}")

    candidate_paths = [
        output_root / "intel" / chosen_model / precision / f"{chosen_model}.xml",
        output_root / "public" / chosen_model / precision / f"{chosen_model}.xml",
    ]
    for model_xml in candidate_paths:
        if model_xml.exists():
            print(f"Using existing converted model: {model_xml}")
            return model_xml

    run_cmd(
        [
            downloader,
            "--name",
            chosen_model,
            "--output_dir",
            str(output_root),
        ]
    )
    run_cmd(
        [
            converter,
            "--name",
            chosen_model,
            "--download_dir",
            str(output_root),
            "--output_dir",
            str(output_root),
            "--precisions",
            precision,
        ]
    )

    for model_xml in candidate_paths:
        if model_xml.exists():
            return model_xml

    looked_up = "\n".join(str(path) for path in candidate_paths)
    raise SystemExit(f"Converted model not found. Checked:\n{looked_up}")


def load_rgb_with_pillow(image_path: Path) -> np.ndarray:
    try:
        image_module = importlib.import_module("PIL.Image")
    except ImportError:
        image_module = None

    if image_module is not None:
        image = image_module.open(image_path).convert("RGB")
        return np.array(image, dtype=np.uint8)

    # Fallback: decode via TensorFlow if available.
    try:
        tf = importlib.import_module("tensorflow")
    except ImportError as exc:
        raise SystemExit(
            "Reading --image requires either Pillow or TensorFlow.\n"
            "Install one of them: pip install -U Pillow  OR  pip install -U tensorflow"
        ) from exc

    data = tf.io.read_file(str(image_path))
    image = tf.io.decode_image(data, channels=3, expand_animations=False)
    return image.numpy().astype(np.uint8)


def resize_rgb_nearest(image: np.ndarray, target_h: int, target_w: int) -> np.ndarray:
    src_h, src_w = image.shape[:2]
    if src_h == target_h and src_w == target_w:
        return image
    y_idx = np.linspace(0, src_h - 1, target_h).astype(np.int32)
    x_idx = np.linspace(0, src_w - 1, target_w).astype(np.int32)
    return image[y_idx][:, x_idx]


def preprocess(
    input_shape: list[int], source_image: np.ndarray | None = None, input_dtype: np.dtype = np.float32
) -> tuple[np.ndarray, np.ndarray]:
    if len(input_shape) != 4:
        raise SystemExit(f"Unexpected input shape: {input_shape}")

    n, d1, d2, d3 = input_shape
    if n != 1:
        raise SystemExit(f"Only batch size 1 is supported in this example: {input_shape}")

    # Handle both NHWC and NCHW model layouts.
    if d3 == 3:
        if source_image is None:
            frame = np.random.randint(0, 255, size=(d1, d2, 3), dtype=np.uint8)
        else:
            frame = resize_rgb_nearest(source_image, d1, d2)
        data = frame[np.newaxis, ...]
    elif d1 == 3:
        if source_image is None:
            frame = np.random.randint(0, 255, size=(d2, d3, 3), dtype=np.uint8)
        else:
            frame = resize_rgb_nearest(source_image, d2, d3)
        data = np.transpose(frame, (2, 0, 1))[np.newaxis, ...]
    else:
        raise SystemExit(f"Unsupported input layout: {input_shape}")

    return data.astype(input_dtype), frame


def parse_single_output_ssd(
    output: np.ndarray, threshold: float
) -> list[tuple[int, float, float, float, float, float]]:
    # SSD detection output is typically [1, 1, N, 7]:
    # [image_id, label_id, score, xmin, ymin, xmax, ymax]
    detections = []
    data = output.reshape(-1, 7)
    for row in data:
        _, label, score, xmin, ymin, xmax, ymax = row
        if score >= threshold:
            detections.append((int(label), float(score), float(xmin), float(ymin), float(xmax), float(ymax)))
    return detections


def parse_multi_output_ssd(
    outputs: dict[Any, np.ndarray], threshold: float
) -> list[tuple[int, float, float, float, float, float]]:
    named = {str(key): value for key, value in outputs.items()}
    boxes = named.get("detection_boxes")
    scores = named.get("detection_scores")
    classes = named.get("detection_classes")

    if boxes is None or scores is None or classes is None:
        # Fallback for models where output tensor names differ.
        if len(outputs) == 1:
            only = next(iter(outputs.values()))
            return parse_single_output_ssd(only, threshold)
        raise SystemExit(
            "Unsupported detection output format. Expected either [1,1,N,7] "
            "or detection_boxes/detection_scores/detection_classes outputs."
        )

    boxes = np.squeeze(boxes)
    scores = np.squeeze(scores)
    classes = np.squeeze(classes)

    if boxes.ndim != 2 or boxes.shape[-1] != 4:
        raise SystemExit(f"Unexpected detection_boxes shape: {boxes.shape}")

    detections: list[tuple[int, float, float, float, float, float]] = []
    count = min(len(scores), len(classes), len(boxes))
    for i in range(count):
        score = float(scores[i])
        if score < threshold:
            continue
        ymin, xmin, ymax, xmax = boxes[i]
        label = int(classes[i])
        detections.append((label, score, float(xmin), float(ymin), float(xmax), float(ymax)))
    return detections


def debug_print_outputs(outputs: dict[Any, np.ndarray]) -> None:
    print("\n[debug] Output tensors:")
    for key, value in outputs.items():
        print(f"  - {key}: shape={tuple(value.shape)} dtype={value.dtype}")

    if len(outputs) == 1:
        only = next(iter(outputs.values())).reshape(-1, 7)
        print("[debug] Top 10 rows from single SSD output [img_id, label, score, xmin, ymin, xmax, ymax]:")
        order = np.argsort(only[:, 2])[::-1]
        for i in order[:10]:
            row = only[i]
            print(
                "  "
                f"label={int(row[1])} score={float(row[2]):.4f} "
                f"box=[{float(row[3]):.3f}, {float(row[4]):.3f}, {float(row[5]):.3f}, {float(row[6]):.3f}]"
            )


def max_detection_score(outputs: dict[Any, np.ndarray]) -> float:
    if len(outputs) == 1:
        only = next(iter(outputs.values())).reshape(-1, 7)
        return float(np.max(only[:, 2]))
    named = {str(key): value for key, value in outputs.items()}
    scores = named.get("detection_scores")
    if scores is not None:
        return float(np.max(np.squeeze(scores)))
    return 0.0


def draw_detections_with_pillow(
    rgb_image: np.ndarray, detections: list[tuple[int, float, float, float, float, float]]
) -> Any | None:
    try:
        image_module = importlib.import_module("PIL.Image")
        draw_module = importlib.import_module("PIL.ImageDraw")
    except ImportError:
        return None

    image = image_module.fromarray(rgb_image)
    draw = draw_module.Draw(image)
    width, height = image.size
    for label, score, xmin, ymin, xmax, ymax in detections:
        x1 = int(max(0, xmin) * width)
        y1 = int(max(0, ymin) * height)
        x2 = int(min(1, xmax) * width)
        y2 = int(min(1, ymax) * height)
        draw.rectangle([x1, y1, x2, y2], outline="red", width=2)
        draw.text((x1 + 2, max(0, y1 - 12)), f"id={label} {score:.2f}", fill="red")
    return image


def main() -> None:
    parser = argparse.ArgumentParser(description="Run MobileNetV2 SSD object detection with OpenVINO.")
    parser.add_argument("--device", default="CPU", help="Target device, e.g. CPU or GPU.")
    parser.add_argument("--precision", default="FP16", choices=["FP16", "FP32"], help="Model precision.")
    parser.add_argument("--threshold", type=float, default=0.5, help="Detection confidence threshold.")
    parser.add_argument(
        "--model-name",
        default=None,
        help=(
            "Optional OMZ model name. If omitted, auto-selects the first available from: "
            + ", ".join(MODEL_NAME_CANDIDATES)
        ),
    )
    parser.add_argument(
        "--image",
        type=Path,
        default=None,
        help="Path to an input image. If omitted, uses synthetic random input.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=ANNOTATED_IMAGE,
        help="Path to save annotated image (requires Pillow).",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Print model I/O metadata and top raw detection scores.",
    )
    args = parser.parse_args()

    model_xml = ensure_omz_model(args.model_name, MODELS_ROOT, args.precision)
    print(f"Loading model: {model_xml}")
    core = ov.Core()
    model = core.read_model(model=str(model_xml))
    compiled = core.compile_model(model, args.device)

    input_port = compiled.input(0)
    input_shape = list(input_port.shape)
    if args.debug:
        print(
            f"[debug] input: name={input_port.get_any_name()} shape={input_shape} "
            f"dtype={input_port.element_type}"
        )
        print("[debug] outputs:")
        for out in compiled.outputs:
            print(f"  - name={out.get_any_name()} shape={list(out.shape)} dtype={out.element_type}")

    source_image = None
    if args.image is not None:
        if not args.image.exists():
            raise SystemExit(f"Input image does not exist: {args.image}")
        source_image = load_rgb_with_pillow(args.image)
    else:
        print("No --image supplied; using synthetic random input (detections may be empty).")

    input_type_name = str(input_port.element_type).lower()
    input_dtype = np.uint8 if "u8" in input_type_name else np.float32
    input_tensor, prepared_image = preprocess(input_shape, source_image, input_dtype=input_dtype)

    outputs = compiled([input_tensor])
    if args.debug:
        debug_print_outputs(outputs)
    peak_score = max_detection_score(outputs)
    if peak_score == 0.0:
        print(
            "Warning: model returned zero confidence for all detections. "
            "Try --model-name ssd_mobilenet_v1_fpn_coco (or ssd_mobilenet_v1_coco)."
        )
    detections = parse_multi_output_ssd(outputs, args.threshold)

    print(f"\nDetections (threshold={args.threshold}): {len(detections)}")
    for idx, (label, score, xmin, ymin, xmax, ymax) in enumerate(detections, start=1):
        print(
            f"{idx:02d}. label_id={label:2d} score={score:.3f} "
            f"box=[{xmin:.3f}, {ymin:.3f}, {xmax:.3f}, {ymax:.3f}]"
        )

    if detections:
        annotated = draw_detections_with_pillow(prepared_image, detections)
        if annotated is not None:
            annotated.save(args.output)
            print(f"\nAnnotated image saved to: {args.output}")
        else:
            print("\nInstall Pillow to save/read image files: pip install -U Pillow")
    else:
        print("\nNo detections above threshold.")


if __name__ == "__main__":
    main()
