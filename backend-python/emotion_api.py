# from flask import Flask, request, jsonify
# import tensorflow as tf
# import numpy as np
# from PIL import Image
# import io

# app = Flask(__name__)

# # Load your TensorFlow Lite model
# interpreter = tf.lite.Interpreter(model_path="emotion_model.tflite")
# interpreter.allocate_tensors()
# input_details = interpreter.get_input_details()
# output_details = interpreter.get_output_details()

# @app.route("/detect_emotion", methods=["POST"])
# def detect_emotion():
#     file = request.files["image"]
#     image = Image.open(io.BytesIO(file.read())).convert("L").resize((48, 48))
#     img_array = np.expand_dims(np.array(image, dtype=np.float32) / 255.0, axis=(0, -1))

#     interpreter.set_tensor(input_details[0]["index"], img_array)
#     interpreter.invoke()
#     output_data = interpreter.get_tensor(output_details[0]["index"])
#     emotion_index = int(np.argmax(output_data))

#     emotions = ["Angry", "Disgust", "Fear", "Happy", "Sad", "Surprise", "Neutral"]
#     return jsonify({"emotion": emotions[emotion_index]})

# if __name__ == "__main__":
#     app.run(host="0.0.0.0", port=5000)
