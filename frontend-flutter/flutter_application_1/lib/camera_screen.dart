// import 'dart:io';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:http/http.dart' as http;
// import 'package:image/image.dart' as img;
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:permission_handler/permission_handler.dart'; // ✅ for runtime permissions
// import 'voice_screen.dart'; // import helper

// class CameraScreen extends StatefulWidget {
//   const CameraScreen({super.key});

//   @override
//   State<CameraScreen> createState() => _CameraScreenState();
// }

// class _CameraScreenState extends State<CameraScreen> {
//   CameraController? _controller;
//   List<CameraDescription>? _cameras;
//   int _selectedCameraIndex = 1;

//   String _faceEmotion = "Unknown";
//   String _voiceEmotion = "Unknown";
//   String _finalEmotion = "Unknown";
//   String _transcript = "";

//   bool _isProcessing = false;
//   final VoiceHelper _voiceHelper = VoiceHelper();

//   // ✅ Buffers for batching
//   final List<File> _frameBuffer = [];
//   final List<File> _voiceBuffer = [];

//   stt.SpeechToText _speech = stt.SpeechToText();
//   bool _recordingStarted = false;
//   DateTime _lastFrameTime = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions().then((granted) {
//       if (granted) {
//         _setupCamera();
//         _initSpeech();
//         _startListening();
//       } else {
//         print("Permissions denied — cannot start camera or mic");
//       }
//     });
//   }

//   Future<bool> _requestPermissions() async {
//     var micStatus = await Permission.microphone.request();
//     var camStatus = await Permission.camera.request();

//     if (micStatus.isGranted && camStatus.isGranted) {
//       print("Microphone and Camera permissions granted");
//       return true;
//     } else {
//       print("Permissions denied");
//       return false;
//     }
//   }

//   Future<void> _initSpeech() async {
//     bool available = await _speech.initialize();
//     if (available) {
//       print("Speech recognition available");
//     } else {
//       print("Speech recognition not available");
//     }
//   }

//   void _startListening() async {
//     await _speech.listen(onResult: (result) {
//       if (!mounted) return;
//       setState(() {
//         _transcript = result.recognizedWords;
//       });

//       if (_transcript.isNotEmpty && !_recordingStarted) {
//         _voiceHelper.startPeriodicRecording((emotion, audioFile, transcript) {
//           if (!mounted) return;
//           setState(() {
//             _voiceEmotion = emotion;
//             _voiceBuffer.add(audioFile);
//             _transcript = transcript;
//           });

//           // ✅ Trigger combined send when both buffers are ready
//           if (_voiceBuffer.length >= 2 && _frameBuffer.length >= 3) {
//             _sendCombinedToBackend(_frameBuffer, _voiceBuffer, _transcript);
//             _voiceBuffer.clear();
//             _frameBuffer.clear();
//           }
//         }, _transcript);

//         _recordingStarted = true;
//       }
//     });
//   }

//   void _stopListening() async {
//     await _speech.stop();
//   }

//   Future<void> _setupCamera() async {
//     _cameras = await availableCameras();
//     _initCamera(_selectedCameraIndex);
//   }

//   void _initCamera(int cameraIndex) {
//     final camera = _cameras![cameraIndex];
//     _controller = CameraController(
//       camera,
//       ResolutionPreset.medium,
//       enableAudio: false,
//     );

//     _controller!.initialize().then((_) {
//       if (!mounted) return;

//       _controller!.startImageStream((CameraImage image) {
//         final now = DateTime.now();
//         if (!_isProcessing && now.difference(_lastFrameTime).inMilliseconds > 1500) {
//           _lastFrameTime = now;
//           _isProcessing = true;
//           _collectFrame(image).then((_) {
//             _isProcessing = false;
//           });
//         }
//       });

//       setState(() {});
//     });
//   }

//   Future<void> _collectFrame(CameraImage image) async {
//     final bytes = _convertYUV420toImage(image);
//     final tempFile = await _bytesToFile(bytes);
//     _frameBuffer.add(tempFile);

//     if (_frameBuffer.length >= 3 && _voiceBuffer.length >= 2) {
//       await _sendCombinedToBackend(_frameBuffer, _voiceBuffer, _transcript);
//       _frameBuffer.clear();
//       _voiceBuffer.clear();
//     }
//   }

//   Future<void> _sendCombinedToBackend(List<File> imageFiles, List<File> audioFiles, String transcript) async {
//     try {
//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse("http://192.168.100.81:5000/detect_combined"),
//       );

//       for (var img in imageFiles) {
//         request.files.add(await http.MultipartFile.fromPath('images', img.path));
//       }
//       for (var aud in audioFiles) {
//         request.files.add(await http.MultipartFile.fromPath('audios', aud.path));
//       }

//       request.fields['text'] = transcript;

//       var response = await request.send();
//       var responseData = await http.Response.fromStream(response);
//       var decoded = json.decode(responseData.body);

//       if (!mounted) return;
//       setState(() {
//         _faceEmotion = decoded['final']['emotion'];
//         _voiceEmotion = decoded['final']['emotion'];
//         _finalEmotion = decoded['final']['emotion'];
//       });

//       print("Final Emotion: $_finalEmotion");
//     } catch (e) {
//       print("Error sending combined batch: $e");
//     }
//   }

//   Uint8List _convertYUV420toImage(CameraImage image) {
//     final int width = image.width;
//     final int height = image.height;
//     final img.Image convertedImage = img.Image(width: width, height: height);

//     final plane = image.planes[0];
//     final bytesPerRow = plane.bytesPerRow;
//     for (int y = 0; y < height; y++) {
//       for (int x = 0; x < width; x++) {
//         final pixelValue = plane.bytes[y * bytesPerRow + x];
//         convertedImage.setPixelRgba(x, y, pixelValue, pixelValue, pixelValue, 255);
//       }
//     }

//     return Uint8List.fromList(img.encodeJpg(convertedImage));
//   }

//   Future<File> _bytesToFile(Uint8List bytes) async {
//     final tempDir = await Directory.systemTemp.createTemp();
//     final file = File('${tempDir.path}/frame.jpg');
//     await file.writeAsBytes(bytes);
//     return file;
//   }

//   void _flipCamera() {
//     if (_cameras == null || _cameras!.length < 2) return;
//     _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
//     _initCamera(_selectedCameraIndex);
//   }

//   @override
//   void reassemble() {
//     super.reassemble();
//     _controller?.dispose();
//   }

//   @override
//   void dispose() {
//     _controller?.stopImageStream();
//     _controller?.dispose();
//     _speech.stop();
//     _voiceHelper.stopRecording();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_controller == null || !_controller!.value.isInitialized) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Real‑Time Multimodal Emotion Detection"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.flip_camera_android),
//             onPressed: _flipCamera,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(child: CameraPreview(_controller!)),
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Text(
//               "Face Emotion: $_faceEmotion\n"
//               "Voice Emotion: $_voiceEmotion\n"
//               "Transcript: $_transcript\n"
//               "Final Emotion: $_finalEmotion",
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               textAlign: TextAlign.center,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
