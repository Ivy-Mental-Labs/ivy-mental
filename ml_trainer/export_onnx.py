from pathlib import Path

import onnx
import torch

from app.config import MODEL_DIR
from app.model import DistilBERTForMoodAndEmotions


def export_to_onnx():
    model = DistilBERTForMoodAndEmotions()
    state_dict_path = MODEL_DIR / "best.pt"
    if not state_dict_path.exists():
        print(f"Error: no trained model found at {state_dict_path}. Run train.py first.")
        return

    state_dict = torch.load(state_dict_path, weights_only=True)
    model.load_state_dict(state_dict)
    model.eval()

    dummy_input_ids = torch.randint(0, 119547, (1, 128))
    dummy_attention_mask = torch.ones(1, 128, dtype=torch.long)

    output_path = MODEL_DIR / "model.onnx"
    temp_output_path = MODEL_DIR / "model_fp32.onnx"
    MODEL_DIR.mkdir(parents=True, exist_ok=True)

    torch.onnx.export(
        model,
        (dummy_input_ids, dummy_attention_mask),
        str(temp_output_path),
        input_names=["input_ids", "attention_mask"],
        output_names=["mood", "emotions"],
        dynamic_axes={
            "input_ids": {0: "batch_size"},
            "attention_mask": {0: "batch_size"},
            "mood": {0: "batch_size"},
            "emotions": {0: "batch_size"},
        },
        opset_version=18,
    )

    onnx_model = onnx.load(str(temp_output_path))
    onnx.save(onnx_model, str(temp_output_path))

    import onnxruntime.quantization.quant_utils as _qu
    _qu.load_model_with_shape_infer = lambda model_path: onnx.load(str(model_path))
    _qu.save_and_reload_model_with_shape_infer = lambda model: model

    from onnxruntime.quantization import quantize_dynamic, QuantType
    quantize_dynamic(
        model_input=str(temp_output_path),
        model_output=str(output_path),
        weight_type=QuantType.QInt8,
        extra_options={"DefaultTensorType": onnx.TensorProto.FLOAT}
    )
    temp_output_path.unlink(missing_ok=True)
    print(f"Quantized INT8 ONNX model exported to {output_path}")


if __name__ == "__main__":
    export_to_onnx()
