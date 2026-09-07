import tensorflow as tf

# Load the HDF5 model
model = tf.keras.models.load_model("fer_model.h5")

# Export as SavedModel (new Keras API requires export)
model.export("saved_model")

# Convert from SavedModel to TensorFlow Lite
converter = tf.lite.TFLiteConverter.from_saved_model("saved_model")
converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS,
    tf.lite.OpsSet.SELECT_TF_OPS
]

# Optional: disable optimizations if they cause issues
converter.optimizations = []

# Perform conversion
tflite_model = converter.convert()

# Save the converted model
with open("emotion_model.tflite", "wb") as f:
    f.write(tflite_model)

print("✅ Conversion complete! Saved as emotion_model.tflite")
