import wave

file_path = "test_voice.wav"

with wave.open(file_path, "rb") as wav_file:
    sample_rate = wav_file.getframerate()
    channels = wav_file.getnchannels()
    duration = wav_file.getnframes() / sample_rate

print(f"Sample rate: {sample_rate} Hz")
print(f"Channels: {channels}")
print(f"Duration: {duration:.2f} seconds")
