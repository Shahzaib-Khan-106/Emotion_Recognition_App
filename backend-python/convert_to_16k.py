from pydub import AudioSegment

# Load your existing WAV file
audio = AudioSegment.from_wav("test_voice.wav")

# Convert to mono and resample to 16 kHz
audio = audio.set_channels(1)
audio = audio.set_frame_rate(16000)

# Export the new file
audio.export("test_voice_16k.wav", format="wav")

print("Converted to 16 kHz mono successfully!")
