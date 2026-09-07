import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;

class VoiceHelper {
  late final AudioRecorder _recorder;
  Timer? _timer;

  // ✅ Buffer for batching audio files
  final List<File> _voiceBuffer = [];

  VoiceHelper() {
    _recorder = AudioRecorder();
  }

  // Updated callback signature: (String emotion, File audioFile, String transcript)
  Future<void> startPeriodicRecording(
      Function(String emotion, File audioFile, String transcript) onEmotionDetected,
      String transcript) async {
    // Cancel any existing timer before starting a new one
    stopRecording();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (await _recorder.hasPermission()) {
        // ✅ Unique filename each time
        final path = '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';

        final config = RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: 128000,
          sampleRate: 16000,
        );

        // Start recording
        await _recorder.start(config, path: path);
        await Future.delayed(const Duration(seconds: 1));
        await _recorder.stop();

        // ✅ Wait briefly to ensure file is flushed
        await Future.delayed(const Duration(milliseconds: 200));

        final audioFile = File(path);

        // Add to buffer
        _voiceBuffer.add(audioFile);

        // ✅ Send batch once buffer has 2 recordings
        if (_voiceBuffer.length >= 2) {
          final emotion = await _sendAudioBatchToBackend(_voiceBuffer, transcript);

          // Pass last audio file + transcript to callback
          onEmotionDetected(emotion, _voiceBuffer.last, transcript);

          _voiceBuffer.clear(); // reset buffer
        }
      }
    });
  }

  // ✅ Stop the periodic timer safely
  void stopRecording() {
    _timer?.cancel();
    _timer = null;
    _voiceBuffer.clear();
  }

  Future<String> _sendAudioBatchToBackend(List<File> audioFiles, String transcript) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://192.168.100.81:5000/detect_voice_batch"),
      );

      // ✅ Send multiple audio files under "audios[]"
      for (var audio in audioFiles) {
        request.files.add(await http.MultipartFile.fromPath('audios', audio.path));
      }

      // ✅ Send transcript text
      request.fields['text'] = transcript;

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);
      return responseData.body;
    } catch (e) {
      print("Error: $e");
      return "Error";
    }
  }
}
