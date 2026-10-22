"""
Measure how accurate your face model really is, and find out which class order
it uses.

Usage:
    python evaluate_face.py path/to/test_folder [images_per_class]

The folder must have one sub-folder per emotion, named like the FER2013 dataset:
    test_folder/angry/*.png
    test_folder/disgust/*.png
    test_folder/fear/*.png
    test_folder/happy/*.png
    test_folder/neutral/*.png
    test_folder/sad/*.png
    test_folder/surprise/*.png

The pictures should already be small face crops (like the FER2013 test set).
The script tries two possible class orders and tells you which one matches your
model. Put the winning order into FACE_CLASS_ORDER in app.py.
"""

import os
import sys

import numpy as np
import tensorflow as tf
from PIL import Image

ORDERS = {
    "FER csv order (Angry, Disgust, Fear, Happy, Sad, Surprise, Neutral)": [
        "angry", "disgust", "fear", "happy", "sad", "surprise", "neutral",
    ],
    "Alphabetical order (Angry, Disgust, Fear, Happy, Neutral, Sad, Surprise)": [
        "angry", "disgust", "fear", "happy", "neutral", "sad", "surprise",
    ],
}

IMAGE_EXTENSIONS = (".png", ".jpg", ".jpeg", ".bmp")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return
    folder = sys.argv[1]
    per_class = int(sys.argv[2]) if len(sys.argv) > 2 else 200

    interpreter = tf.lite.Interpreter(model_path="emotion_model.tflite")
    interpreter.allocate_tensors()
    inp = interpreter.get_input_details()[0]
    out = interpreter.get_output_details()[0]
    h, w = int(inp["shape"][1]), int(inp["shape"][2])
    channels = int(inp["shape"][3]) if len(inp["shape"]) == 4 else 1

    true_labels, predicted = [], []
    for class_name in sorted(os.listdir(folder)):
        class_dir = os.path.join(folder, class_name)
        if not os.path.isdir(class_dir):
            continue
        files = [f for f in sorted(os.listdir(class_dir)) if f.lower().endswith(IMAGE_EXTENSIONS)]
        for name in files[:per_class]:
            img = Image.open(os.path.join(class_dir, name)).convert("L").resize((w, h))
            x = (np.array(img, dtype=np.float32) / 255.0).reshape(1, h, w, 1)
            if channels == 3:
                x = np.repeat(x, 3, axis=3)
            interpreter.set_tensor(inp["index"], x)
            interpreter.invoke()
            probs = interpreter.get_tensor(out["index"])[0]
            true_labels.append(class_name.lower())
            predicted.append(int(np.argmax(probs)))

    if not true_labels:
        print("No pictures found. Check the folder path and names.")
        return

    best_name, best_acc, best_order = None, -1.0, None
    print(f"\nTested {len(true_labels)} pictures.\n")
    for name, order in ORDERS.items():
        correct = sum(1 for t, p in zip(true_labels, predicted) if order[p] == t)
        acc = correct / len(true_labels)
        print(f"{acc * 100:5.1f}%  with {name}")
        if acc > best_acc:
            best_name, best_acc, best_order = name, acc, order

    print(f"\nBest match: {best_name}  ({best_acc * 100:.1f}% accuracy)")

    classes = sorted(set(true_labels))
    print("\nPer-emotion accuracy with the best order:")
    for c in classes:
        idx = [i for i, t in enumerate(true_labels) if t == c]
        ok = sum(1 for i in idx if best_order[predicted[i]] == c)
        print(f"  {c:9s} {ok / len(idx) * 100:5.1f}%  ({len(idx)} pictures)")

    print("\nMost common mistakes (true -> predicted):")
    mistakes = {}
    for t, p in zip(true_labels, predicted):
        if best_order[p] != t:
            key = (t, best_order[p])
            mistakes[key] = mistakes.get(key, 0) + 1
    for (t, p), n in sorted(mistakes.items(), key=lambda kv: -kv[1])[:8]:
        print(f"  {t} -> {p}: {n}")


if __name__ == "__main__":
    main()