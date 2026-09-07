from flask import Flask, request, jsonify
import tensorflow as tf
import numpy as np
from PIL import Image
import io
import os
import uuid
from transformers import pipeline

app = Flask(__name__)

# ---------------------------
# Load Face Emotion Model (TFLite)
# ---------------------------
interpreter_face = tf.lite.Interpreter(model_path="emotion_model.tflite")
interpreter_face.allocate_tensors()
input_details_face = interpreter_face.get_input_details()
output_details_face = interpreter_face.get_output_details()

face_emotions = ["Angry", "Disgust", "Fear", "Happy", "Sad", "Surprise", "Neutral"]

# ---------------------------
# Load HuggingFace Models
# ---------------------------
text_model = pipeline("text-classification", model="bhadresh-savani/bert-base-uncased-emotion")
audio_model = pipeline("audio-classification", model="superb/wav2vec2-base-superb-er")

# ---------------------------
# Routes
# ---------------------------

@app.route("/detect_emotion", methods=["POST"])
def detect_emotion():
    """Face emotion detection from single image"""
    file = request.files["image"]
    image = Image.open(io.BytesIO(file.read())).convert("L").resize((48, 48))
    img_array = np.expand_dims(np.array(image, dtype=np.float32) / 255.0, axis=(0, -1))

    interpreter_face.set_tensor(input_details_face[0]["index"], img_array)
    interpreter_face.invoke()
    output_data = interpreter_face.get_tensor(output_details_face[0]["index"])
    emotion_index = int(np.argmax(output_data))
    confidence = float(np.max(output_data))

    return jsonify({"emotion": face_emotions[emotion_index], "confidence": confidence})


@app.route("/detect_emotion_batch", methods=["POST"])
def detect_emotion_batch():
    """Process multiple face images in one request"""
    results = []
    files = request.files.getlist("images")

    for file in files:
        image = Image.open(file).convert("L").resize((48, 48))
        img_array = np.expand_dims(np.array(image, dtype=np.float32) / 255.0, axis=(0, -1))
        interpreter_face.set_tensor(input_details_face[0]["index"], img_array)
        interpreter_face.invoke()
        output_data = interpreter_face.get_tensor(output_details_face[0]["index"])
        emotion_index = int(np.argmax(output_data))
        confidence = float(np.max(output_data))
        results.append({"emotion": face_emotions[emotion_index], "confidence": confidence})

    final = max(results, key=lambda e: e["confidence"]) if results else {"emotion": "Unknown", "confidence": 0.0}
    return jsonify({"results": results, "final": final})


@app.route("/detect_voice", methods=["POST"])
def detect_voice():
    """Voice + text emotion detection (single audio)"""
    audio_file = request.files.get("audio")
    text_input = request.form.get("text", "")

    print("---- /detect_voice called ----")
    print("Received audio:", audio_file)
    print("Transcript:", text_input)

    voice_result, text_result = None, None

    if audio_file:
        temp_path = f"temp_audio_{uuid.uuid4().hex}.wav"
        audio_file.save(temp_path)
        try:
            voice_result = audio_model(temp_path)
        except Exception as e:
            voice_result = [{"label": "Error", "score": 0.0}]
            print(f"Voice model error: {e}")
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)

    if text_input:
        try:
            text_result = text_model(text_input)
        except Exception as e:
            text_result = [{"label": "Error", "score": 0.0}]
            print(f"Text model error: {e}")

    return jsonify({"voice": voice_result, "text": text_result})


@app.route("/detect_voice_batch", methods=["POST"])
def detect_voice_batch():
    """Process multiple audio files in one request"""
    results = []
    files = request.files.getlist("audios")
    text_input = request.form.get("text", "")

    for audio_file in files:
        temp_path = f"temp_audio_{uuid.uuid4().hex}.wav"
        audio_file.save(temp_path)
        try:
            voice_result = audio_model(temp_path)
            results.append(voice_result[0])
        except Exception as e:
            results.append({"label": "Error", "score": 0.0})
            print(f"Voice model error: {e}")
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)

    text_result = None
    if text_input:
        try:
            text_result = text_model(text_input)
        except Exception as e:
            text_result = [{"label": "Error", "score": 0.0}]
            print(f"Text model error: {e}")

    return jsonify({"voice_batch": results, "text": text_result})


@app.route("/detect_context", methods=["POST"])
def detect_context():
    """Text-only emotion detection"""
    text_input = request.form.get("text", "")
    try:
        result = text_model(text_input)
    except Exception as e:
        result = [{"label": "Error", "score": 0.0}]
        print(f"Context model error: {e}")
    return jsonify(result)


@app.route("/detect_combined", methods=["POST"])
def detect_combined():
    """Fuse multiple face + voice + context results"""
    print("---- /detect_combined called ----")
    print("Received images:", request.files.getlist("images"))
    print("Received audios:", request.files.getlist("audios"))
    print("Transcript:", request.form.get("text"))

    # --- Face batch ---
    face_results = []
    image_files = request.files.getlist("images")
    for image_file in image_files:
        image = Image.open(image_file).convert("L").resize((48, 48))
        img_array = np.expand_dims(np.array(image, dtype=np.float32) / 255.0, axis=(0, -1))
        interpreter_face.set_tensor(input_details_face[0]["index"], img_array)
        interpreter_face.invoke()
        output_data = interpreter_face.get_tensor(output_details_face[0]["index"])
        face_index = int(np.argmax(output_data))
        face_conf = float(np.max(output_data))
        face_results.append({"emotion": face_emotions[face_index], "confidence": face_conf})

    # --- Voice batch ---
    voice_results = []
    audio_files = request.files.getlist("audios")
    for audio_file in audio_files:
        temp_path = f"temp_audio_{uuid.uuid4().hex}.wav"
        audio_file.save(temp_path)
        try:
            voice_result = audio_model(temp_path)
            voice_results.append({"emotion": voice_result[0]["label"], "confidence": voice_result[0]["score"]})
        except Exception as e:
            voice_results.append({"emotion": "Error", "confidence": 0.0})
            print(f"Voice model error: {e}")
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)

    # --- Context ---
    text_input = request.form.get("text", "")
    context_emotion, context_conf = None, 0.0
    if text_input:
        try:
            context_result = text_model(text_input)
            context_emotion = context_result[0]["label"]
            context_conf = context_result[0]["score"]
        except Exception as e:
            context_emotion, context_conf = "Error", 0.0
            print(f"Context model error: {e}")

    # --- Fusion
    emotions = []
    emotions.extend(face_results)
    emotions.extend(voice_results)
    if context_emotion:
        emotions.append({"emotion": context_emotion, "confidence": context_conf})

    final = max(emotions, key=lambda e: e["confidence"]) if emotions else {"emotion": "Unknown", "confidence": 0.0}

    return jsonify({
        "faces": face_results,
        "voices": voice_results,
        "context": {"emotion": context_emotion, "confidence": context_conf},
        "final": final
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
