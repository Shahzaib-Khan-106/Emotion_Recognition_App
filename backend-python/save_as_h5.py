import tensorflow as tf

# Load the Keras model
model = tf.keras.models.load_model("finalfacialemotionmodel.keras")

# Save as HDF5
model.save("fer_model.h5")

print("✅ Model saved as fer_model.h5")
