import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// ⚙️ Address of your Flask server (phone and computer must be on the same Wi-Fi).
const String kServerBaseUrl = "http://192.168.100.122:5000";

/// Turns one camera frame into an upright grey JPEG.
/// Runs in a background isolate so the screen never freezes.
Uint8List _encodeFrameToJpeg(Map<String, dynamic> args) {
  final int width = args['width'] as int;
  final int height = args['height'] as int;
  final int bytesPerRow = args['bytesPerRow'] as int;
  final Uint8List bytes = args['bytes'] as Uint8List;
  final int rotation = args['rotation'] as int;

  final img.Image gray = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int v = bytes[y * bytesPerRow + x];
      gray.setPixelRgba(x, y, v, v, v, 255);
    }
  }

  // Phone cameras deliver frames sideways. Turn them upright.
  final img.Image upright =
      rotation == 0 ? gray : img.copyRotate(gray, angle: rotation);
  return Uint8List.fromList(img.encodeJpg(upright, quality: 90));
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // 🎨 Same calm palette as the rest of the app
  static const Color _primary = Color(0xFF5C6BC0);
  static const Color _primaryDark = Color(0xFF3F51B5);
  static const Color _bgTop = Color(0xFFE8EAF6);
  static const Color _bgBottom = Color(0xFFF3E5F5);

  // ⏱️ Capture settings
  static const int _captureSeconds = 5; // how long we watch and listen
  static const int _maxFrames = 4; // pictures sent to the server
  static const int _frameIntervalMs = 1000;

  // 📷 Camera
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _permissionDenied = false;

  // 🎤 One recorder only (no speech_to_text, so the microphone is never shared)
  final AudioRecorder _recorder = AudioRecorder();

  // Frame capture
  final List<Future<Uint8List>> _frameJobs = [];
  DateTime _lastFrameTime = DateTime.now();

  // State shown on screen
  bool _busy = false;
  int _countdown = 0;
  String _statusText =
      "Look at the camera and say how you feel, then tap Start.";
  String? _errorMessage;

  Map<String, dynamic>? _face;
  Map<String, dynamic>? _voice;
  Map<String, dynamic>? _text;
  Map<String, dynamic>? _final;

  bool get _cameraReady => _controller?.value.isInitialized ?? false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  // ───────────────────────── setup ─────────────────────────

  Future<void> _boot() async {
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    if (!cam.isGranted || !mic.isGranted) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _errorMessage = "No camera found on this phone.");
        return;
      }
      final front =
          _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      _cameraIndex = front >= 0 ? front : 0;
      await _startCamera(_cameraIndex);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Could not start the camera: $e");
    }
  }

  Future<void> _startCamera(int index) async {
    final old = _controller;
    if (old != null) {
      if (mounted) setState(() => _controller = null);
      await old.dispose();
    }

    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await controller.initialize();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Could not start the camera: $e");
      return;
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _errorMessage = null;
    });
  }

  Future<void> _flipCamera() async {
    if (_busy || _cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startCamera(_cameraIndex);
  }

  // ───────────────────────── capture ─────────────────────────

  void _onCameraImage(CameraImage image) {
    if (_frameJobs.length >= _maxFrames) return;
    final now = DateTime.now();
    if (now.difference(_lastFrameTime).inMilliseconds < _frameIntervalMs) return;
    _lastFrameTime = now;

    final plane = image.planes[0]; // brightness plane = grey picture
    _frameJobs.add(
      compute(_encodeFrameToJpeg, {
        'width': image.width,
        'height': image.height,
        'bytesPerRow': plane.bytesPerRow,
        'bytes': Uint8List.fromList(plane.bytes),
        'rotation': _controller!.description.sensorOrientation,
      }),
    );
  }

  void _resetResults() {
    _face = null;
    _voice = null;
    _text = null;
    _final = null;
    _errorMessage = null;
  }

  Future<void> _runAnalysis() async {
    if (_busy || !_cameraReady) return;

    if (!await _recorder.hasPermission()) {
      setState(() => _errorMessage = "Please allow the microphone.");
      return;
    }

    setState(() {
      _busy = true;
      _resetResults();
      _statusText = "Recording... look at the camera and speak.";
    });

    final tempDir = await Directory.systemTemp.createTemp('emotion_');
    final String audioPath = '${tempDir.path}/voice.wav';
    bool recording = false;

    try {
      // 1️⃣ Start recording ONE wav file: mono, 16 kHz (what the voice model wants)
      try {
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: audioPath,
        );
        recording = true;
      } catch (e) {
        debugPrint("Recorder error: $e");
      }

      // 2️⃣ Start collecting pictures
      _frameJobs.clear();
      _lastFrameTime = DateTime.now();
      await _controller!.startImageStream(_onCameraImage);

      // 3️⃣ Count down
      for (int s = _captureSeconds; s > 0; s--) {
        if (!mounted) return;
        setState(() => _countdown = s);
        await Future.delayed(const Duration(seconds: 1));
      }
      if (!mounted) return;
      setState(() {
        _countdown = 0;
        _statusText = "Thinking...";
      });

      // 4️⃣ Stop everything
      try {
        await _controller!.stopImageStream();
      } catch (e) {
        debugPrint("stopImageStream: $e");
      }
      String? recordedPath;
      if (recording) {
        try {
          recordedPath = await _recorder.stop();
        } catch (e) {
          debugPrint("Recorder stop error: $e");
        }
      }

      final List<Uint8List> frames = await Future.wait(_frameJobs);

      // 5️⃣ Send to the server
      await _sendToServer(frames, recordedPath ?? (recording ? audioPath : null));
    } catch (e, st) {
      debugPrint("Analysis error: $e\n$st");
      if (mounted) setState(() => _errorMessage = "Something went wrong: $e");
    } finally {
      try {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _busy = false;
          _countdown = 0;
          if (_final != null) _statusText = "Done. Tap Start to try again.";
        });
      }
    }
  }

  Future<void> _sendToServer(List<Uint8List> frames, String? audioPath) async {
    if (frames.isEmpty) {
      setState(() => _errorMessage = "No pictures were captured. Please try again.");
      return;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$kServerBaseUrl/detect_combined'),
      );
      for (int i = 0; i < frames.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes('images', frames[i], filename: 'frame_$i.jpg'),
        );
      }
      if (audioPath != null && await File(audioPath).exists()) {
        request.files.add(
          await http.MultipartFile.fromPath('audio', audioPath, filename: 'voice.wav'),
        );
      }

      final streamed = await request.send().timeout(const Duration(seconds: 90));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        if (mounted) {
          setState(() => _errorMessage = "Server error (code ${response.statusCode}).");
        }
        return;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _face = (data['face'] as Map?)?.cast<String, dynamic>();
        _voice = (data['voice'] as Map?)?.cast<String, dynamic>();
        _text = (data['text'] as Map?)?.cast<String, dynamic>();
        _final = (data['final'] as Map?)?.cast<String, dynamic>();
      });
    } on TimeoutException {
      if (mounted) {
        setState(() => _errorMessage =
            "The server took too long. The first run can be slow because models are loading. Try again.");
      }
    } on SocketException {
      if (mounted) {
        setState(() => _errorMessage =
            "Cannot reach the server at $kServerBaseUrl. Is it running, and is the phone on the same Wi-Fi?");
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Connection problem: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // ───────────────────────── text helpers ─────────────────────────

  String _percent(dynamic v) => "${(((v as num?) ?? 0) * 100).round()}%";

  Color _accentFor(String? emotion) {
    switch ((emotion ?? '').toLowerCase()) {
      case 'happy':
        return const Color(0xFF43A047);
      case 'angry':
        return const Color(0xFFE53935);
      case 'fear':
        return const Color(0xFFFB8C00);
      case 'surprise':
        return const Color(0xFF8E24AA);
      case 'sad':
        return const Color(0xFF3949AB);
      case 'disgust':
        return const Color(0xFF00897B);
      case 'neutral':
        return const Color(0xFF607D8B);
      default:
        return _primary;
    }
  }

  String _faceText() {
    final f = _face;
    if (f == null) return "Not checked yet";
    switch (f['status']) {
      case 'ok':
        return "${f['emotion']} (${_percent(f['confidence'])})";
      case 'no_face':
        return "No face found. Look at the camera in good light.";
      default:
        return "The face could not be checked.";
    }
  }

  String? _faceSub() {
    final f = _face;
    if (f == null || f['status'] != 'ok') return null;
    return "Used ${f['frames_used']} of ${f['frames_total']} pictures";
  }

  String _voiceText() {
    final v = _voice;
    if (v == null) return "Not checked yet";
    switch (v['status']) {
      case 'ok':
        return "${v['emotion']} (${_percent(v['confidence'])})";
      case 'silent':
        return "No voice heard. Speak closer to the phone.";
      case 'missing':
        return "No recording was made.";
      default:
        return "The voice could not be checked.";
    }
  }

  String? _voiceSub() {
    final v = _voice;
    if (v == null || v['status'] != 'ok') return null;
    return "Voice level: ${(((v['level'] as num?) ?? 0) * 100).toStringAsFixed(1)}";
  }

  String _wordsText() {
    final t = _text;
    if (t == null) return "Not checked yet";
    switch (t['status']) {
      case 'ok':
        return "\"${t['transcript']}\"";
      case 'empty':
        return "No words were heard.";
      default:
        return "The words could not be checked.";
    }
  }

  String? _wordsSub() {
    final t = _text;
    if (t == null || t['status'] != 'ok') return null;
    return "Sounds like: ${t['emotion']} (${_percent(t['confidence'])})";
  }

  String _usedText() {
    final used = (_final?['used'] as List?)?.cast<String>() ?? [];
    final names = used.map((u) => u == 'text' ? 'words' : u).toList();
    if (names.isEmpty) return "";
    return "Based on: ${names.join(', ')}";
  }

  // ───────────────────────── widgets ─────────────────────────

  Widget _decorCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _gradientScaffold({required Widget child, PreferredSizeWidget? appBar}) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
                top: -70, right: -60, child: _decorCircle(220, _primary.withOpacity(0.12))),
            Positioned(
                bottom: -90, left: -60, child: _decorCircle(240, _primary.withOpacity(0.10))),
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }

  AppBar _appBar({List<Widget>? actions}) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: _primaryDark,
      title: const Text("Emotion Camera",
          style: TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: actions,
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    bool dim = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: dim ? Colors.grey.shade600 : const Color(0xFF263238),
                    height: 1.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 The unified result card
  Widget _buildFinalCard() {
    final f = _final;
    final bool hasResult = f != null && f['status'] == 'ok';
    final String? emotion = hasResult ? f['emotion'] as String? : null;
    final double confidence = hasResult ? ((f['confidence'] as num?)?.toDouble() ?? 0) : 0;
    final Color accent = _accentFor(emotion);
    final List top = hasResult ? ((f['top'] as List?) ?? []) : [];
    final String note = (f?['note'] as String?) ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.psychology_alt_rounded, color: accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Unified result (face + voice + words)",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasResult
                          ? "$emotion (${_percent(confidence)})"
                          : (f != null ? "Could not tell" : "Tap Start below"),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasResult) ...[
            const SizedBox(height: 8),
            Text(
              [
                _usedText(),
                if (confidence < 0.5) "Not very sure, it may be wrong.",
              ].where((s) => s.isNotEmpty).join("  •  "),
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            ...top.map((t) {
              final String name = t['emotion'] as String;
              final double p = (t['probability'] as num).toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(name,
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: p.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation(_accentFor(name)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 38,
                      child: Text(_percent(p),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(note,
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
          ],
        ],
      ),
    );
  }

  Widget _buildViewfinder() {
    final controller = _controller!;
    // controller.value.aspectRatio is always the LANDSCAPE ratio (width / height).
    // In portrait we must flip it, otherwise the picture is stretched sideways.
    final bool portrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final double previewRatio =
        portrait ? 1 / controller.value.aspectRatio : controller.value.aspectRatio;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _busy ? _primary : Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.25),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.black,
                // Fill the whole frame (crops a little at the edges, no black bars)
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: previewRatio * 1000,
                    height: 1000,
                    child: CameraPreview(controller),
                  ),
                ),
              ),
              if (_busy)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_countdown > 0) ...[
                          const Icon(Icons.fiber_manual_record,
                              color: Colors.redAccent, size: 14),
                          const SizedBox(width: 6),
                          Text("Recording  $_countdown",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ] else ...[
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Text("Thinking...",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFinalCard(),
                  const SizedBox(height: 10),
                  _infoTile(
                    icon: Icons.face_rounded,
                    label: "From your face",
                    value: _faceText(),
                    subtitle: _faceSub(),
                    dim: _face == null || _face!['status'] != 'ok',
                  ),
                  const SizedBox(height: 8),
                  _infoTile(
                    icon: Icons.mic_rounded,
                    label: "From your voice",
                    value: _voiceText(),
                    subtitle: _voiceSub(),
                    dim: _voice == null || _voice!['status'] != 'ok',
                  ),
                  const SizedBox(height: 8),
                  _infoTile(
                    icon: Icons.record_voice_over_rounded,
                    label: "From your words",
                    value: _wordsText(),
                    subtitle: _wordsSub(),
                    dim: _text == null || _text!['status'] != 'ok',
                  ),
                  const SizedBox(height: 10),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600),
                    )
                  else
                    Text(
                      _statusText,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: _busy ? Colors.grey : _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _busy ? null : _runAnalysis,
            icon: Icon(_busy ? Icons.autorenew_rounded : Icons.play_arrow_rounded),
            label: Text(
              _busy ? "Please wait..." : "Start Analysis",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🚫 Permissions refused
    if (_permissionDenied) {
      return _gradientScaffold(
        appBar: _appBar(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 56, color: _primary),
                const SizedBox(height: 16),
                const Text(
                  "Camera and microphone are needed",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF283593)),
                ),
                const SizedBox(height: 8),
                Text(
                  "Please allow both in the phone settings.",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: openAppSettings,
                  child: const Text("Open settings"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ⏳ Camera is starting
    if (!_cameraReady) {
      return _gradientScaffold(
        appBar: _appBar(),
        child: Center(
          child: _errorMessage != null
              ? Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.red.shade700, fontWeight: FontWeight.w600),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withOpacity(0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const SizedBox(
                        height: 44,
                        width: 44,
                        child: CircularProgressIndicator(
                            strokeWidth: 3.5, color: _primary),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Getting things ready...",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF283593)),
                    ),
                  ],
                ),
        ),
      );
    }

    // ✅ Main screen
    return _gradientScaffold(
      appBar: _appBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded),
            tooltip: "Switch camera",
            onPressed: _busy ? null : _flipCamera,
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(flex: 9, child: _buildViewfinder()),
          Expanded(flex: 5, child: _buildResultsPanel()),
        ],
      ),
    );
  }
}