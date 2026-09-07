import tensorflow as tf

# Load your HDF5 model
model = tf.keras.models.load_model("fer_model.h5")

# Export as TensorFlow SavedModel
model.export("saved_model")

print("✅ Exported model to SavedModel format")
