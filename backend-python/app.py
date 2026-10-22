"""
Emotion server: face + voice + words -> one unified result.

Run:   python app.py
Needs: emotion_model.tflite in the same folder (see requirements.txt for packages).

What is different from the old version
--------------------------------------
* FACE: finds and crops the face (OpenCV) before the 48x48 model, tries rotated
  versions of the picture if no face is found, and AVERAGES the frames.
* VOICE: reads the WAV properly (mono, 16 kHz), checks for silence (so a silent
  recording is reported as "silent" instead of a fake "Neutral"), and keeps the
  full probability list.
* WORDS: the words are transcribed here with Whisper from the same recording,
  so the phone does not need speech_to_text and the recorder at the same time.
* FUSION: every model is mapped to the same 7 emotions and combined with a
  weighted average instead of "highest confidence number wins".
"""

import io
import os
import threading
import wave

import numpy as np
import tensorflow as tf
from flask import Flask, jsonify, request
from PIL import Image, ImageOps
from transformers import pipeline

try:
    import cv2
except ImportError:  # the server still runs, but face cropping is much weaker
    cv2 = None

try:
    import soundfile as sf
except ImportError:
    sf = None

app = Flask(__name__)
MODEL_LOCK = threading.Lock()

# ---------------------------------------------------------------------------
# SETTINGS you can tune
# ---------------------------------------------------------------------------

# The 7 emotions used everywhere.
EMOTIONS = ["Angry", "Disgust", "Fear", "Happy", "Sad", "Surprise", "Neutral"]

# Order of the outputs of YOUR face model.
# FER2013 csv order (default):  Angry, Disgust, Fear, Happy, Sad, Surprise, Neutral
# Alphabetical folder order:    Angry, Disgust, Fear, Happy, Neutral, Sad, Surprise
# If your model was trained with Keras flow_from_directory, it is probably the
# alphabetical one. Run evaluate_face.py to find out which order is correct.
FACE_CLASS_ORDER = ["Angry", "Disgust", "Fear", "Happy", "Sad", "Surprise", "Neutral"]
# FACE_CLASS_ORDER = ["Angry", "Disgust", "Fear", "Happy", "Neutral", "Sad", "Surprise"]

# How much each source counts in the final answer (they are re-balanced
# automatically when a source is missing, for example when nobody speaks).
WEIGHTS = {"face": 0.50, "voice": 0.20, "text": 0.30}

# The voice model likes to answer "neutral". Lowering it a little corrects this.
VOICE_NEUTRAL_SCALE = 0.6
FACE_NEUTRAL_SCALE = 1.0

SAMPLE_RATE = 16000
SILENCE_RMS = 0.005  # quieter than this = nobody is speaking

USE_WHISPER = os.environ.get("USE_WHISPER", "1") == "1"
WHISPER_MODEL = os.environ.get("WHISPER_MODEL", "openai/whisper-tiny.en")

# Names the models use -> our 7 emotions
VOICE_MAP = {"neu": "Neutral", "hap": "Happy", "ang": "Angry", "sad": "Sad"}
TEXT_MAP = {
    "joy": "Happy",
    "love": "Happy",
    "anger": "Angry",
    "sadness": "Sad",
    "fear": "Fear",
    "surprise": "Surprise",
}

# ---------------------------------------------------------------------------
# Load models
# ---------------------------------------------------------------------------

interpreter_face = tf.lite.Interpreter(model_path="emotion_model.tflite")
interpreter_face.allocate_tensors()
input_details_face = interpreter_face.get_input_details()
output_details_face = interpreter_face.get_output_details()
FACE_INPUT_SHAPE = input_details_face[0]["shape"]
FACE_H = int(FACE_INPUT_SHAPE[1])
FACE_W = int(FACE_INPUT_SHAPE[2])
FACE_C = int(FACE_INPUT_SHAPE[3]) if len(FACE_INPUT_SHAPE) == 4 else 1

text_model = pipeline(
    "text-classification", model="bhadresh-savani/bert-base-uncased-emotion"
)
audio_model = pipeline("audio-classification", model="superb/wav2vec2-base-superb-er")

asr_model = None
if USE_WHISPER:
    try:
        asr_model = pipeline("automatic-speech-recognition", model=WHISPER_MODEL)
        print(f"Whisper loaded: {WHISPER_MODEL}")
    except Exception as e:  # noqa: BLE001
        print(f"Could not load Whisper ({e}). Words will only work if the app sends text.")

_face_cascade = None
if cv2 is not None:
    _face_cascade = cv2.CascadeClassifier(
        cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
    )
    if _face_cascade.empty():
        _face_cascade = None
if _face_cascade is None:
    print("WARNING: OpenCV face detector not available. Install opencv-python-headless.")


# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------

def normalize(probs):
    total = sum(probs.values())
    if total <= 0:
        return probs
    return {k: v / total for k, v in probs.items()}


def top_of(probs):
    emotion = max(probs, key=probs.get)
    return emotion, float(probs[emotion])


def round_probs(probs):
    return {k: round(float(v), 4) for k, v in probs.items()}


def labels_to_probs(scores, mapping):
    """[{'label': 'hap', 'score': 0.7}, ...] -> {'Happy': 0.7, ...} over EMOTIONS."""
    probs = {e: 0.0 for e in EMOTIONS}
    for item in scores:
        emotion = mapping.get(str(item["label"]).lower())
        if emotion:
            probs[emotion] += float(item["score"])
    if sum(probs.values()) <= 0:
        return None
    return normalize(probs)


# ---------------------------------------------------------------------------
# FACE
# ---------------------------------------------------------------------------

def _center_square(gray):
    h, w = gray.shape[:2]
    side = min(h, w)
    y0 = (h - side) // 2
    x0 = (w - side) // 2
    crop = gray[y0:y0 + side, x0:x0 + side]
    return np.array(Image.fromarray(crop).resize((FACE_W, FACE_H)))


def _detect_and_crop(gray):
    """Returns a FACE_H x FACE_W face crop, or None if no face is found."""
    if _face_cascade is None:
        return _center_square(gray)

    min_dim = min(gray.shape[:2])
    min_size = max(40, int(min_dim * 0.15))
    equalized = cv2.equalizeHist(gray)
    faces = _face_cascade.detectMultiScale(
        equalized, scaleFactor=1.1, minNeighbors=5, minSize=(min_size, min_size)
    )
    if len(faces) == 0:
        return None

    x, y, w, h = max(faces, key=lambda f: f[2] * f[3])  # biggest face
    margin = int(0.1 * w)
    x0 = max(0, x - margin)
    y0 = max(0, y - margin)
    x1 = min(gray.shape[1], x + w + margin)
    y1 = min(gray.shape[0], y + h + margin)
    crop = gray[y0:y1, x0:x1]
    return cv2.resize(crop, (FACE_W, FACE_H), interpolation=cv2.INTER_AREA)


def extract_face(image_bytes):
    """Returns (face_crop, rotation_used). Tries 4 rotations in case the phone
    sent the picture sideways."""
    img = ImageOps.exif_transpose(Image.open(io.BytesIO(image_bytes))).convert("L")
    gray = np.array(img, dtype=np.uint8)
    for k in (0, 1, 3, 2):
        rotated = np.ascontiguousarray(np.rot90(gray, k))
        face = _detect_and_crop(rotated)
        if face is not None:
            return face, k
    return None, None


def predict_face(face_gray):
    x = face_gray.astype(np.float32) / 255.0
    x = x.reshape(1, FACE_H, FACE_W, 1)
    if FACE_C == 3:
        x = np.repeat(x, 3, axis=3)

    with MODEL_LOCK:
        interpreter_face.set_tensor(input_details_face[0]["index"], x)
        interpreter_face.invoke()
        out = interpreter_face.get_tensor(output_details_face[0]["index"])[0]

    out = out.astype(np.float64)
    if out.min() < 0 or abs(out.sum() - 1.0) > 0.05:  # not probabilities yet
        e = np.exp(out - out.max())
        out = e / e.sum()
    return out


def face_vector_to_probs(vec):
    probs = {e: 0.0 for e in EMOTIONS}
    for i, p in enumerate(vec):
        if i < len(FACE_CLASS_ORDER):
            probs[FACE_CLASS_ORDER[i]] += float(p)
    probs["Neutral"] *= FACE_NEUTRAL_SCALE
    return normalize(probs)


def analyze_faces(image_blobs):
    total = len(image_blobs)
    if total == 0:
        return {"status": "missing", "frames_total": 0, "frames_used": 0}

    vectors = []
    for blob in image_blobs:
        try:
            face, rotation = extract_face(blob)
        except Exception as e:  # noqa: BLE001
            print(f"Could not read a picture: {e}")
            continue
        if face is None:
            continue
        vectors.append(face_vector_to_probs(predict_face(face)))

    if not vectors:
        return {"status": "no_face", "frames_total": total, "frames_used": 0}

    # average the frames (more stable than picking one)
    mean = {e: float(np.mean([v[e] for v in vectors])) for e in EMOTIONS}
    mean = normalize(mean)
    emotion, confidence = top_of(mean)
    return {
        "status": "ok",
        "emotion": emotion,
        "confidence": round(confidence, 4),
        "probs": round_probs(mean),
        "frames_total": total,
        "frames_used": len(vectors),
    }


# ---------------------------------------------------------------------------
# VOICE and WORDS
# ---------------------------------------------------------------------------

def load_audio(data):
    """WAV bytes -> mono float32 array at 16 kHz, or None."""
    audio, rate = None, None
    try:
        with wave.open(io.BytesIO(data), "rb") as w:
            channels = w.getnchannels()
            width = w.getsampwidth()
            rate = w.getframerate()
            raw = w.readframes(w.getnframes())
        if width == 2:
            arr = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
        elif width == 1:
            arr = (np.frombuffer(raw, dtype=np.uint8).astype(np.float32) - 128) / 128.0
        elif width == 4:
            arr = np.frombuffer(raw, dtype=np.int32).astype(np.float32) / 2147483648.0
        else:
            raise ValueError(f"unsupported sample width {width}")
        if channels > 1:
            arr = arr[: len(arr) // channels * channels].reshape(-1, channels).mean(axis=1)
        audio = arr
    except Exception as e:  # noqa: BLE001
        print(f"wave module could not read the audio ({e}); trying soundfile")
        if sf is not None:
            try:
                arr, rate = sf.read(io.BytesIO(data), dtype="float32", always_2d=False)
                if arr.ndim > 1:
                    arr = arr.mean(axis=1)
                audio = arr
            except Exception as e2:  # noqa: BLE001
                print(f"soundfile could not read the audio either: {e2}")

    if audio is None or len(audio) == 0:
        return None

    if rate != SAMPLE_RATE:
        x_old = np.linspace(0, 1, len(audio), endpoint=False)
        n_new = max(1, int(len(audio) * SAMPLE_RATE / rate))
        x_new = np.linspace(0, 1, n_new, endpoint=False)
        audio = np.interp(x_new, x_old, audio)
    return audio.astype(np.float32)


def analyze_audio(data):
    """Returns (voice_result_dict, audio_array_or_None). The array is only given
    back when somebody really spoke, so we never transcribe silence."""
    audio = load_audio(data)
    if audio is None:
        return {"status": "error", "message": "Could not read the audio file."}, None

    rms = float(np.sqrt(np.mean(audio ** 2)))
    peak = float(np.max(np.abs(audio)))
    info = {"level": round(rms, 4), "seconds": round(len(audio) / SAMPLE_RATE, 2)}
    print(f"Audio: {info['seconds']}s, level={rms:.4f}, peak={peak:.3f}")

    if rms < SILENCE_RMS:
        return {"status": "silent", **info}, None

    if peak > 0:
        audio = audio / peak * 0.9  # make quiet recordings a bit louder

    try:
        scores = audio_model({"raw": audio, "sampling_rate": SAMPLE_RATE}, top_k=4)
    except Exception as e:  # noqa: BLE001
        print(f"Voice model error: {e}")
        return {"status": "error", "message": str(e), **info}, audio

    probs = labels_to_probs(scores, VOICE_MAP)
    if probs is None:
        return {"status": "error", "message": "Unexpected voice model labels.", **info}, audio
    probs["Neutral"] *= VOICE_NEUTRAL_SCALE
    probs = normalize(probs)
    emotion, confidence = top_of(probs)
    return {
        "status": "ok",
        "emotion": emotion,
        "confidence": round(confidence, 4),
        "probs": round_probs(probs),
        **info,
    }, audio


def transcribe(audio):
    if asr_model is None:
        return ""
    try:
        out = asr_model({"raw": audio, "sampling_rate": SAMPLE_RATE})
        text = str(out.get("text", "")).strip()
    except Exception as e:  # noqa: BLE001
        print(f"Whisper error: {e}")
        return ""
    if len(text) < 2:
        return ""
    if text.startswith("[") and text.endswith("]"):  # e.g. [BLANK_AUDIO]
        return ""
    return text


def run_text_model(text):
    try:
        scores = text_model(text, top_k=None)
    except TypeError:
        scores = text_model(text, return_all_scores=True)
    if scores and isinstance(scores[0], list):
        scores = scores[0]
    return scores


def analyze_text(text):
    text = (text or "").strip()
    if not text:
        return {"status": "empty", "transcript": ""}
    try:
        probs = labels_to_probs(run_text_model(text), TEXT_MAP)
    except Exception as e:  # noqa: BLE001
        print(f"Text model error: {e}")
        return {"status": "error", "transcript": text, "message": str(e)}
    if probs is None:
        return {"status": "error", "transcript": text, "message": "Unexpected text labels."}
    emotion, confidence = top_of(probs)
    return {
        "status": "ok",
        "transcript": text,
        "emotion": emotion,
        "confidence": round(confidence, 4),
        "probs": round_probs(probs),
    }


# ---------------------------------------------------------------------------
# FUSION
# ---------------------------------------------------------------------------

def fuse(results):
    """results = {'face': dict, 'voice': dict, 'text': dict}. Only 'ok' ones count."""
    total = {e: 0.0 for e in EMOTIONS}
    used = []
    weight_sum = 0.0
    for name, result in results.items():
        if result.get("status") != "ok":
            continue
        w = WEIGHTS[name]
        weight_sum += w
        used.append(name)
        for e in EMOTIONS:
            total[e] += w * result["probs"][e]

    if weight_sum == 0:
        return {
            "status": "none",
            "emotion": "Unknown",
            "confidence": 0.0,
            "used": [],
            "top": [],
        }

    total = {e: v / weight_sum for e, v in total.items()}
    emotion, confidence = top_of(total)
    ranked = sorted(total.items(), key=lambda kv: kv[1], reverse=True)[:3]
    return {
        "status": "ok",
        "emotion": emotion,
        "confidence": round(confidence, 4),
        "probs": round_probs(total),
        "used": used,
        "top": [{"emotion": e, "probability": round(p, 4)} for e, p in ranked],
    }


def build_note(results):
    notes = []
    if results["face"].get("status") == "no_face":
        notes.append("No face was found, so the face was not used.")
    if results["voice"].get("status") == "silent":
        notes.append("The recording was silent, so voice and words were not used.")
    if results["voice"].get("status") == "error":
        notes.append("The voice could not be analysed.")
    if results["text"].get("status") == "empty" and results["voice"].get("status") == "ok":
        notes.append("No clear words were heard.")
    return " ".join(notes)


# ---------------------------------------------------------------------------
# ROUTES
# ---------------------------------------------------------------------------

@app.route("/health", methods=["GET"])
def health():
    return jsonify(
        {
            "ok": True,
            "face_detector": _face_cascade is not None,
            "whisper": asr_model is not None,
            "face_class_order": FACE_CLASS_ORDER,
        }
    )


@app.route("/detect_combined", methods=["POST"])
def detect_combined():
    """Main endpoint used by the app: pictures + one audio recording."""
    image_blobs = [f.read() for f in request.files.getlist("images")]
    audio_blobs = [
        f.read()
        for f in request.files.getlist("audio") + request.files.getlist("audios")
    ]
    client_text = request.form.get("text", "").strip()
    print(f"/detect_combined: {len(image_blobs)} pictures, {len(audio_blobs)} audio files")

    face = analyze_faces(image_blobs)

    voice, audio = {"status": "missing"}, None
    if audio_blobs:
        voice, audio = analyze_audio(max(audio_blobs, key=len))

    transcript = transcribe(audio) if audio is not None else ""
    if not transcript:
        transcript = client_text  # only if the app sent real text
    text = analyze_text(transcript)

    results = {"face": face, "voice": voice, "text": text}
    final = fuse(results)
    final["note"] = build_note(results)

    print(
        "Result:",
        {k: v.get("emotion", v.get("status")) for k, v in results.items()},
        "->",
        final["emotion"],
        final["confidence"],
    )
    return jsonify({"face": face, "voice": voice, "text": text, "final": final})


# --- older endpoints, kept so other screens keep working -------------------

@app.route("/detect_emotion", methods=["POST"])
def detect_emotion():
    blob = request.files["image"].read()
    face, _ = extract_face(blob)
    if face is None:
        return jsonify({"emotion": "No face", "confidence": 0.0})
    probs = face_vector_to_probs(predict_face(face))
    emotion, confidence = top_of(probs)
    return jsonify({"emotion": emotion, "confidence": confidence})


@app.route("/detect_emotion_batch", methods=["POST"])
def detect_emotion_batch():
    results = []
    for f in request.files.getlist("images"):
        face, _ = extract_face(f.read())
        if face is None:
            continue
        emotion, confidence = top_of(face_vector_to_probs(predict_face(face)))
        results.append({"emotion": emotion, "confidence": confidence})
    final = (
        max(results, key=lambda e: e["confidence"])
        if results
        else {"emotion": "Unknown", "confidence": 0.0}
    )
    return jsonify({"results": results, "final": final})


@app.route("/detect_voice", methods=["POST"])
def detect_voice():
    audio_file = request.files.get("audio")
    text_input = request.form.get("text", "")
    voice_result, text_result = None, None

    if audio_file:
        voice, _ = analyze_audio(audio_file.read())
        if voice["status"] == "ok":
            voice_result = [
                {"label": e, "score": p}
                for e, p in sorted(voice["probs"].items(), key=lambda kv: -kv[1])
            ]
        else:
            voice_result = [{"label": voice["status"], "score": 0.0}]

    if text_input:
        try:
            text_result = run_text_model(text_input)
        except Exception as e:  # noqa: BLE001
            print(f"Text model error: {e}")
            text_result = [{"label": "Error", "score": 0.0}]

    return jsonify({"voice": voice_result, "text": text_result})


@app.route("/detect_voice_batch", methods=["POST"])
def detect_voice_batch():
    results = []
    for f in request.files.getlist("audios"):
        voice, _ = analyze_audio(f.read())
        if voice["status"] == "ok":
            results.append({"label": voice["emotion"], "score": voice["confidence"]})
        else:
            results.append({"label": voice["status"], "score": 0.0})

    text_input = request.form.get("text", "")
    text_result = None
    if text_input:
        try:
            text_result = run_text_model(text_input)
        except Exception as e:  # noqa: BLE001
            print(f"Text model error: {e}")
            text_result = [{"label": "Error", "score": 0.0}]
    return jsonify({"voice_batch": results, "text": text_result})


@app.route("/detect_context", methods=["POST"])
def detect_context():
    text_input = request.form.get("text", "")
    try:
        result = run_text_model(text_input)
    except Exception as e:  # noqa: BLE001
        print(f"Context model error: {e}")
        result = [{"label": "Error", "score": 0.0}]
    return jsonify(result)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, threaded=True)