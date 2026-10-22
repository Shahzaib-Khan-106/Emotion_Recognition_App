import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

// 🎨 Same calm palette as the rest of the app
const Color _kPrimary = Color(0xFF5C6BC0);
const Color _kPrimaryDark = Color(0xFF3F51B5);
const Color _kBgTop = Color(0xFFE8EAF6);
const Color _kBgBottom = Color(0xFFF3E5F5);
const Color _kInk = Color(0xFF263238);

// 🖼️ BACKGROUND IMAGE for the Calming Assistant screens (cc2.jpg)
const String _kBgAsset = 'assets/images/cc2.jpg';

// ─────────────────────────────────────────────────────────────
// 🖼️ REAL PHOTOS
// ─────────────────────────────────────────────────────────────
// Every photo below is a direct image link. To use your own photo,
// replace the link with any direct image link (it must open as just
// the picture, usually ending in .jpg or .png).
//
// loremflickr.com/WIDTH/HEIGHT/KEYWORDS?lock=N  -> real photo by keyword
//   (the same lock number always gives the same photo)
// randomuser.me/api/portraits/women|men/N.jpg    -> real portrait photos

class _Photos {
  // 😊 Feelings (mood photos)
  static const String sad = 'https://loremflickr.com/400/400/rain,window?lock=1';
  static const String angry = 'https://loremflickr.com/400/400/storm,lightning?lock=2';
  static const String overwhelmed = 'https://loremflickr.com/400/400/waves,sea?lock=3';
  static const String worried = 'https://loremflickr.com/400/400/clouds,sky?lock=4';
  static const String notSure = 'https://loremflickr.com/400/400/path,forest?lock=5';

  // 🧩 Activities
  static const String breathing = 'https://loremflickr.com/300/300/lake,calm?lock=6';
  static const String sounds = 'https://loremflickr.com/300/300/rain,forest?lock=7';
  static const String quietBreak = 'https://loremflickr.com/300/300/moon,night?lock=8';
  static const String animations = 'https://loremflickr.com/300/300/fish,aquarium?lock=9';
  static const String caregiver = 'https://randomuser.me/api/portraits/women/44.jpg';

  // 🎧 Sounds
  static const String rain = 'https://loremflickr.com/300/300/rain,leaves?lock=10';
  static const String ocean = 'https://loremflickr.com/300/300/ocean,waves?lock=11';
  static const String music = 'https://loremflickr.com/300/300/piano?lock=12';

  // ⏳ Quiet-break lengths
  static const String min1 = 'https://loremflickr.com/300/300/candle?lock=13';
  static const String min3 = 'https://loremflickr.com/300/300/lake,sunset?lock=14';
  static const String min5 = 'https://loremflickr.com/300/300/starry,night?lock=15';
  static const String moonBig = 'https://loremflickr.com/400/400/moon?lock=16';
  static const String sunriseBig = 'https://loremflickr.com/400/400/sunrise?lock=17';

  // 🐠 Scene backgrounds (tall photos)
  static const String sceneOcean = 'https://loremflickr.com/800/1400/ocean,underwater?lock=21';
  static const String sceneNight = 'https://loremflickr.com/800/1400/night,stars?lock=22';
  static const String sceneGarden = 'https://loremflickr.com/800/1400/flowers,garden?lock=23';
  static const String thumbOcean = 'https://loremflickr.com/120/120/ocean,underwater?lock=21';
  static const String thumbNight = 'https://loremflickr.com/120/120/night,stars?lock=22';
  static const String thumbGarden = 'https://loremflickr.com/120/120/flowers,garden?lock=23';

  // 🤗 People (real portraits)
  static const String mom = 'https://randomuser.me/api/portraits/women/44.jpg';
  static const String dad = 'https://randomuser.me/api/portraits/men/32.jpg';
  static const String teacher = 'https://randomuser.me/api/portraits/women/65.jpg';
  static const String caregiverPerson = 'https://randomuser.me/api/portraits/men/75.jpg';
}

// A network photo with a soft loading tile and an emoji fallback if it
// can't load (for example when there is no internet).
class _Photo extends StatelessWidget {
  final String url;
  final String fallback; // emoji shown only if the photo fails
  final double? width;
  final double? height;
  final double radius;
  final bool circle;

  const _Photo(
    this.url, {
    this.fallback = "🙂",
    this.width,
    this.height,
    this.radius = 16,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    final double base = width ?? height ?? 60;

    final Widget image = SizedBox(
      width: width,
      height: height,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: _kPrimary.withOpacity(0.10),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stack) => Container(
          color: _kPrimary.withOpacity(0.12),
          alignment: Alignment.center,
          child: Text(fallback, style: TextStyle(fontSize: base * 0.45)),
        ),
      ),
    );

    if (circle) return ClipOval(child: image);
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }
}

// ─────────────────────────────────────────────────────────────
// 🧩 Data: calming activities and feelings
// ─────────────────────────────────────────────────────────────

enum _CalmActivity { breathing, sounds, quietBreak, animations, caregiver }

class _ActivityInfo {
  final String emoji; // fallback only
  final String photo;
  final String title;
  final String subtitle;
  final Color color;

  const _ActivityInfo({
    required this.emoji,
    required this.photo,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

const Map<_CalmActivity, _ActivityInfo> _activityInfo = {
  _CalmActivity.breathing: _ActivityInfo(
    emoji: "🫁",
    photo: _Photos.breathing,
    title: "Breathing circle",
    subtitle: "Breathe slowly with a moving circle",
    color: Color(0xFF42A5F5),
  ),
  _CalmActivity.sounds: _ActivityInfo(
    emoji: "🎧",
    photo: _Photos.sounds,
    title: "Calming sounds",
    subtitle: "Rain, ocean waves or soft music",
    color: Color(0xFF26A69A),
  ),
  _CalmActivity.quietBreak: _ActivityInfo(
    emoji: "🌙",
    photo: _Photos.quietBreak,
    title: "Quiet break",
    subtitle: "Rest with a gentle timer",
    color: Color(0xFFAB47BC),
  ),
  _CalmActivity.animations: _ActivityInfo(
    emoji: "🐠",
    photo: _Photos.animations,
    title: "Calm scenes",
    subtitle: "Watch the ocean, stars or flowers",
    color: Color(0xFFFFA726),
  ),
  _CalmActivity.caregiver: _ActivityInfo(
    emoji: "🤗",
    photo: _Photos.caregiver,
    title: "I want my person",
    subtitle: "Ask a parent or trusted adult to come",
    color: Color(0xFFEF5350),
  ),
};

class _Feeling {
  final String emoji; // fallback only
  final String photo;
  final String label;
  final Color color;
  final String message;
  final List<_CalmActivity> suggestions;

  const _Feeling({
    required this.emoji,
    required this.photo,
    required this.label,
    required this.color,
    required this.message,
    required this.suggestions,
  });
}

const List<_Feeling> _feelings = [
  _Feeling(
    emoji: "😢",
    photo: _Photos.sad,
    label: "Sad",
    color: Color(0xFF42A5F5),
    message: "It is okay to feel sad. You are not alone.",
    suggestions: [
      _CalmActivity.breathing,
      _CalmActivity.sounds,
      _CalmActivity.animations,
      _CalmActivity.caregiver,
    ],
  ),
  _Feeling(
    emoji: "😠",
    photo: _Photos.angry,
    label: "Angry",
    color: Color(0xFFEF5350),
    message: "It is okay to feel angry. Let's help your body feel calm.",
    suggestions: [
      _CalmActivity.breathing,
      _CalmActivity.quietBreak,
      _CalmActivity.sounds,
      _CalmActivity.caregiver,
    ],
  ),
  _Feeling(
    emoji: "😵‍💫",
    photo: _Photos.overwhelmed,
    label: "Overwhelmed",
    color: Color(0xFFAB47BC),
    message: "Things feel like too much. That is okay. Let's slow down.",
    suggestions: [
      _CalmActivity.quietBreak,
      _CalmActivity.breathing,
      _CalmActivity.sounds,
      _CalmActivity.caregiver,
    ],
  ),
  _Feeling(
    emoji: "😟",
    photo: _Photos.worried,
    label: "Worried",
    color: Color(0xFFFFA726),
    message: "It is okay to feel worried. You are safe right now.",
    suggestions: [
      _CalmActivity.breathing,
      _CalmActivity.sounds,
      _CalmActivity.animations,
      _CalmActivity.caregiver,
    ],
  ),
  _Feeling(
    emoji: "😶",
    photo: _Photos.notSure,
    label: "Not sure",
    color: Color(0xFF26A69A),
    message: "That is okay. You can try anything you like.",
    suggestions: [
      _CalmActivity.breathing,
      _CalmActivity.sounds,
      _CalmActivity.quietBreak,
      _CalmActivity.animations,
      _CalmActivity.caregiver,
    ],
  ),
];

// ─────────────────────────────────────────────────────────────
// 🧱 Shared scaffold: gradient + beautiful merged background image
// ─────────────────────────────────────────────────────────────

class _CalmScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _CalmScaffold({required this.title, required this.child});

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _kPrimaryDark,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Base gradient (also shown if the image can't load)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kBgTop, _kBgBottom],
          ),
        ),
        child: Stack(
          children: [
            // 📷 Your background image (assets/images/cc2.jpg)
            Positioned.fill(
              child: Image.asset(
                _kBgAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
            ),

            // 🌫️ Soft color layer that merges the image into the app palette
            // (lower the numbers to show more of the image,
            //  raise them to make it softer)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _kBgTop.withOpacity(0.25),
                      _kBgTop.withOpacity(0.40),
                      _kBgBottom.withOpacity(0.75),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            Positioned(
                top: -70,
                right: -60,
                child: _circle(220, _kPrimary.withOpacity(0.12))),
            Positioned(
                bottom: -90,
                left: -60,
                child: _circle(240, _kPrimary.withOpacity(0.10))),
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🏠 Main Calming Assistant screen
// ─────────────────────────────────────────────────────────────

class CalmingAssistantScreen extends StatefulWidget {
  const CalmingAssistantScreen({super.key});

  @override
  State<CalmingAssistantScreen> createState() => _CalmingAssistantScreenState();
}

class _CalmingAssistantScreenState extends State<CalmingAssistantScreen> {
  _Feeling? _selected;

  Widget _screenFor(_CalmActivity activity) {
    switch (activity) {
      case _CalmActivity.breathing:
        return const _BreathingScreen();
      case _CalmActivity.sounds:
        return const _CalmingSoundsScreen();
      case _CalmActivity.quietBreak:
        return const _QuietBreakScreen();
      case _CalmActivity.animations:
        return const _CalmAnimationsScreen();
      case _CalmActivity.caregiver:
        return const _CaregiverScreen();
    }
  }

  void _openActivity(_CalmActivity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _screenFor(activity)),
    );
  }

  // 😊 Step 1: ask how the child feels (photo cards)
  Widget _buildFeelingPicker() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        children: [
          const Text(
            "How are you feeling?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF283593),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the one that fits best.",
            style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 22),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _feelings.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final f = _feelings[index];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: f.color.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _Photo(f.photo, fallback: f.emoji, radius: 0),
                      // dark fade so the label is easy to read
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.65),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Text(
                            f.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _selected = f),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🌿 Step 2: gentle message + options the child can choose (or skip)
  Widget _buildOptions(_Feeling feeling) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Supportive message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: feeling.color.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: feeling.color.withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _Photo(feeling.photo,
                    fallback: feeling.emoji, width: 76, height: 76, radius: 18),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    feeling.message,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _kInk,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Would you like to try something?",
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF283593),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "You choose. You can also skip.",
            style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),

          // Suggested activities
          ...feeling.suggestions.map((activity) {
            final info = _activityInfo[activity]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _OptionCard(
                photo: info.photo,
                fallback: info.emoji,
                title: info.title,
                subtitle: info.subtitle,
                color: info.color,
                onTap: () => _openActivity(activity),
              ),
            );
          }),

          const SizedBox(height: 6),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              foregroundColor: _kPrimaryDark,
              backgroundColor: Colors.white.withOpacity(0.9),
              side: const BorderSide(color: _kPrimary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text(
              "No thanks, I feel okay",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => setState(() => _selected = null),
            child: const Text(
              "Choose a different feeling",
              style: TextStyle(fontWeight: FontWeight.bold, color: _kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CalmScaffold(
      title: "Calming Assistant",
      child: _selected == null
          ? _buildFeelingPicker()
          : _buildOptions(_selected!),
    );
  }
}

// 🃏 Option card used on the options list
class _OptionCard extends StatelessWidget {
  final String photo;
  final String fallback;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OptionCard({
    required this.photo,
    required this.fallback,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _Photo(photo,
                    fallback: fallback, width: 68, height: 68, radius: 16),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _kInk,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🫁 1. Animated breathing exercise (with spoken voice)
// ─────────────────────────────────────────────────────────────

class _BreathingScreen extends StatefulWidget {
  const _BreathingScreen();

  @override
  State<_BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<_BreathingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final FlutterTts _tts = FlutterTts();
  String _label = "Breathe in";
  int _breaths = 0;
  bool _running = true;
  bool _voiceOn = true;

  @override
  void initState() {
    super.initState();
    _initTts();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // 4s in, 4s out
    );

    _controller.addStatusListener((status) {
      if (!mounted) return;
      if (status == AnimationStatus.forward) {
        setState(() => _label = "Breathe in");
        _speak("Breathe in");
      } else if (status == AnimationStatus.reverse) {
        setState(() {
          _label = "Breathe out";
          _breaths += 1;
        });
        _speak("Breathe out");
      }
    });

    _controller.repeat(reverse: true);
  }

  Future<void> _initTts() async {
    try {
      final engines = await _tts.getEngines;
      if (engines is List && engines.contains("com.google.android.tts")) {
        await _tts.setEngine("com.google.android.tts");
      }
      final available = await _tts.isLanguageAvailable("en-US");
      if (available == true) {
        await _tts.setLanguage("en-US");
      }
      await _tts.setSpeechRate(0.35); // slow and soothing
      await _tts.setPitch(0.9);
      await _tts.setVolume(1.0);
    } catch (e) {
      debugPrint("Breathing TTS setup error: $e");
    }
  }

  Future<void> _speak(String text) async {
    if (!_voiceOn || !_running) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint("Breathing TTS error: $e");
    }
  }

  void _togglePause() {
    setState(() {
      _running = !_running;
      if (_running) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _tts.stop();
      }
    });
  }

  void _toggleVoice() {
    setState(() => _voiceOn = !_voiceOn);
    if (!_voiceOn) {
      _tts.stop();
    } else {
      _speak(_label);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CalmScaffold(
      title: "Breathing",
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Follow the circle.\nBreathe slowly.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF283593),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 300,
              height: 300,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final double eased =
                      Curves.easeInOut.transform(_controller.value);
                  final double scale = 0.55 + 0.45 * eased;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF90CAF9).withOpacity(0.95),
                                _kPrimary.withOpacity(0.85),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kPrimary.withOpacity(0.35),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        _label,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Breaths: $_breaths",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 52),
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _togglePause,
              icon: Icon(
                  _running ? Icons.pause_rounded : Icons.play_arrow_rounded),
              label: Text(
                _running ? "Pause" : "Continue",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(220, 46),
                foregroundColor: _kPrimaryDark,
                backgroundColor: Colors.white.withOpacity(0.9),
                side: const BorderSide(color: _kPrimary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _toggleVoice,
              icon: Icon(
                  _voiceOn ? Icons.volume_up_rounded : Icons.volume_off_rounded),
              label: Text(
                _voiceOn ? "Voice: On" : "Voice: Off",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "I feel better",
                style: TextStyle(fontWeight: FontWeight.bold, color: _kPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🎧 2. Calming sounds
// ─────────────────────────────────────────────────────────────

class _SoundItem {
  final String emoji; // fallback only
  final String photo;
  final String title;
  final String assetPath; // relative to the assets/ folder

  const _SoundItem(this.emoji, this.photo, this.title, this.assetPath);
}

class _CalmingSoundsScreen extends StatefulWidget {
  const _CalmingSoundsScreen();

  @override
  State<_CalmingSoundsScreen> createState() => _CalmingSoundsScreenState();
}

class _CalmingSoundsScreenState extends State<_CalmingSoundsScreen> {
  static const List<_SoundItem> _sounds = [
    _SoundItem("🌧️", _Photos.rain, "Rain", "sounds/rain.mp3"),
    _SoundItem("🌊", _Photos.ocean, "Ocean waves", "sounds/ocean.mp3"),
    _SoundItem("🎵", _Photos.music, "Soft music", "sounds/soft_music.mp3"),
  ];

  final AudioPlayer _player = AudioPlayer();
  String? _playingTitle;
  double _volume = 0.6;

  Future<void> _toggle(_SoundItem sound) async {
    try {
      // Tap again to stop
      if (_playingTitle == sound.title) {
        await _player.stop();
        if (mounted) setState(() => _playingTitle = null);
        return;
      }

      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_volume);
      await _player.play(AssetSource(sound.assetPath));
      if (mounted) setState(() => _playingTitle = sound.title);
    } catch (e) {
      debugPrint("Sound error: $e");
      if (!mounted) return;
      setState(() => _playingTitle = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.orange,
          content: const Text(
            "This sound could not play. Check that the file is in assets/sounds/.",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color teal = Color(0xFF26A69A);

    return _CalmScaffold(
      title: "Calming Sounds",
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Choose a sound.\nTap again to stop.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF283593),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 22),
            ..._sounds.map((sound) {
              final bool isPlaying = _playingTitle == sound.title;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? const Color(0xFFE0F2F1)
                        : Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPlaying ? teal : teal.withOpacity(0.25),
                      width: isPlaying ? 3 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: teal.withOpacity(0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _toggle(sound),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            _Photo(sound.photo,
                                fallback: sound.emoji,
                                width: 76,
                                height: 76,
                                radius: 16),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                sound.title,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: _kInk,
                                ),
                              ),
                            ),
                            Icon(
                              isPlaying
                                  ? Icons.stop_circle_rounded
                                  : Icons.play_circle_fill_rounded,
                              color: teal,
                              size: 42,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.volume_down_rounded, color: Colors.grey.shade800),
                Expanded(
                  child: Slider(
                    value: _volume,
                    activeColor: teal,
                    onChanged: (v) {
                      setState(() => _volume = v);
                      _player.setVolume(v);
                    },
                  ),
                ),
                Icon(Icons.volume_up_rounded, color: Colors.grey.shade800),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "I feel better",
                style: TextStyle(fontWeight: FontWeight.bold, color: _kPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🌙 3. Quiet-break timer
// ─────────────────────────────────────────────────────────────

class _QuietBreakScreen extends StatefulWidget {
  const _QuietBreakScreen();

  @override
  State<_QuietBreakScreen> createState() => _QuietBreakScreenState();
}

class _QuietBreakScreenState extends State<_QuietBreakScreen> {
  static const Color _purple = Color(0xFFAB47BC);

  static const Map<int, String> _minutePhotos = {
    1: _Photos.min1,
    3: _Photos.min3,
    5: _Photos.min5,
  };

  Timer? _timer;
  int _totalSeconds = 0;
  int _remaining = 0;
  bool _started = false;
  bool _running = false;
  bool _finished = false;

  void _start(int minutes) {
    _timer?.cancel();
    setState(() {
      _totalSeconds = minutes * 60;
      _remaining = _totalSeconds;
      _started = true;
      _running = true;
      _finished = false;
    });
    _startTicking();
  }

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining <= 1) {
        timer.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
          _finished = true;
        });
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  void _togglePause() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _startTicking();
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _started = false;
      _running = false;
      _finished = false;
    });
  }

  String get _timeText {
    final int m = _remaining ~/ 60;
    final int s = _remaining % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildChooser() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Take a quiet break.\nHow long would you like?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF283593),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          ...[1, 3, 5].map((minutes) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _OptionCard(
                photo: _minutePhotos[minutes]!,
                fallback: "⏳",
                title: "$minutes ${minutes == 1 ? 'minute' : 'minutes'}",
                subtitle: minutes == 1
                    ? "A short rest"
                    : (minutes == 3 ? "A medium rest" : "A long rest"),
                color: _purple,
                onTap: () => _start(minutes),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final double progress =
        _totalSeconds == 0 ? 0 : _remaining / _totalSeconds;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Photo(
            _finished ? _Photos.sunriseBig : _Photos.moonBig,
            fallback: _finished ? "🌟" : "🌙",
            width: 84,
            height: 84,
            circle: true,
          ),
          const SizedBox(height: 14),
          Text(
            _finished
                ? "Well done.\nYou took a quiet break."
                : "Rest your body.\nThere is nothing else to do.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF283593),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 14,
                    strokeCap: StrokeCap.round,
                    backgroundColor: _purple.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation(_purple),
                  ),
                ),
                Text(
                  _timeText,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (!_finished)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(220, 52),
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _togglePause,
              icon: Icon(
                  _running ? Icons.pause_rounded : Icons.play_arrow_rounded),
              label: Text(
                _running ? "Pause" : "Continue",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _finished ? () => Navigator.pop(context) : _reset,
            child: Text(
              _finished ? "I feel better" : "Stop the break",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CalmScaffold(
      title: "Quiet Break",
      child: _started ? _buildTimer() : _buildChooser(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🐠 4. Calm scenes: real photo backgrounds with a slow zoom
// ─────────────────────────────────────────────────────────────

enum _SceneType { ocean, night, garden }

// A soft drifting or twinkling dot (bubble, star, pollen)
class _Floater {
  final double size;
  final double x0, y0; // start position (0..1)
  final int dx, dy; // full trips across the scene per loop
  final double ampX, ampY; // gentle wobble
  final int freq; // wobble speed
  final double phase;
  final bool twinkle;

  const _Floater({
    required this.size,
    required this.x0,
    required this.y0,
    this.dx = 0,
    this.dy = 0,
    this.ampX = 0,
    this.ampY = 0,
    this.freq = 1,
    this.phase = 0,
    this.twinkle = false,
  });
}

class _SceneStyle {
  final String name;
  final String emoji; // fallback only
  final String photo; // full-screen background
  final String thumb; // small chip photo
  final List<Color> colors; // shown while the photo loads
  final bool darkBackground;

  const _SceneStyle(this.name, this.emoji, this.photo, this.thumb, this.colors,
      this.darkBackground);
}

const Map<_SceneType, _SceneStyle> _sceneStyles = {
  _SceneType.ocean: _SceneStyle("Ocean", "🐠", _Photos.sceneOcean,
      _Photos.thumbOcean, [Color(0xFF81D4FA), Color(0xFF0277BD)], true),
  _SceneType.night: _SceneStyle("Night sky", "🌙", _Photos.sceneNight,
      _Photos.thumbNight, [Color(0xFF1A237E), Color(0xFF4527A0)], true),
  _SceneType.garden: _SceneStyle("Garden", "🦋", _Photos.sceneGarden,
      _Photos.thumbGarden, [Color(0xFFE1F5FE), Color(0xFFA5D6A7)], true),
};

List<_Floater> _buildFloaters(_SceneType type) {
  final Random r = Random(type.index + 11);
  double rnd(double a, double b) => a + r.nextDouble() * (b - a);
  final List<_Floater> list = [];

  switch (type) {
    case _SceneType.ocean:
      // soft bubbles rising
      for (int i = 0; i < 14; i++) {
        list.add(_Floater(
          size: rnd(10, 28),
          x0: rnd(0.05, 0.95),
          y0: rnd(0, 1),
          dy: -1,
          ampX: 0.02,
          freq: 2 + r.nextInt(3),
          phase: r.nextDouble(),
        ));
      }
      break;

    case _SceneType.night:
      // twinkling star dots
      for (int i = 0; i < 28; i++) {
        list.add(_Floater(
          size: rnd(3, 8),
          x0: rnd(0.03, 0.97),
          y0: rnd(0.08, 0.9),
          freq: 2 + r.nextInt(3),
          phase: r.nextDouble(),
          twinkle: true,
        ));
      }
      break;

    case _SceneType.garden:
      // soft pollen drifting up and across
      for (int i = 0; i < 14; i++) {
        list.add(_Floater(
          size: rnd(6, 14),
          x0: rnd(0, 1),
          y0: rnd(0, 1),
          dx: 1,
          dy: -1,
          ampX: 0.01,
          ampY: 0.02,
          freq: 2 + r.nextInt(3),
          phase: r.nextDouble(),
        ));
      }
      break;
  }
  return list;
}

class _CalmAnimationsScreen extends StatefulWidget {
  const _CalmAnimationsScreen();

  @override
  State<_CalmAnimationsScreen> createState() => _CalmAnimationsScreenState();
}

class _CalmAnimationsScreenState extends State<_CalmAnimationsScreen>
    with SingleTickerProviderStateMixin {
  static const double _span = 1.2; // items wrap around just outside the screen

  late final AnimationController _controller;
  _SceneType _scene = _SceneType.ocean;
  late List<_Floater> _floaters;

  @override
  void initState() {
    super.initState();
    _floaters = _buildFloaters(_scene);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40), // slow and calm
    )..repeat();
  }

  void _changeScene(_SceneType type) {
    setState(() {
      _scene = type;
      _floaters = _buildFloaters(type);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildFloater(_Floater f, double t, double w, double h) {
    final double wobble = 2 * pi * (f.freq * t + f.phase);

    double x = f.x0 + f.dx * _span * t + f.ampX * sin(wobble);
    double y = f.y0 + f.dy * _span * t + f.ampY * sin(wobble + pi / 2);

    // wrap around so moving items re-enter from the other side
    if (f.dx != 0) x = (x % _span) - 0.1;
    if (f.dy != 0) y = (y % _span) - 0.1;

    double opacity = 1.0;
    if (f.twinkle) {
      opacity = 0.25 + 0.75 * (0.5 + 0.5 * sin(wobble));
    }

    final Widget dot = Container(
      width: f.size,
      height: f.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(f.twinkle ? 0.95 : 0.28),
        border: f.twinkle
            ? null
            : Border.all(color: Colors.white.withOpacity(0.6)),
        boxShadow: f.twinkle
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.7),
                  blurRadius: f.size * 1.5,
                ),
              ]
            : null,
      ),
    );

    return Positioned(
      left: x * w - f.size / 2,
      top: y * h - f.size / 2,
      child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: dot),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _SceneStyle style = _sceneStyles[_scene]!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        title: const Text("Calm Scenes",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: style.colors,
          ),
        ),
        child: Stack(
          children: [
            // 📷 Real photo background with a very slow zoom
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final double t = _controller.value;
                  final double scale = 1.10 + 0.06 * sin(2 * pi * t);
                  return Transform.scale(scale: scale, child: child);
                },
                child: Image.network(
                  style.photo,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : const SizedBox.shrink(),
                  errorBuilder: (context, error, stack) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),

            // soft dark layer so the buttons stay readable
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.05),
                      Colors.black.withOpacity(0.35),
                    ],
                  ),
                ),
              ),
            ),

            // ✨ Floating dots
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double w = constraints.maxWidth;
                  final double h = constraints.maxHeight;
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final double t = _controller.value;
                      return Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          for (final f in _floaters) _buildFloater(f, t, w, h),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // 🎛️ Scene picker and exit button
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 10,
                        children: _SceneType.values.map((type) {
                          final s = _sceneStyles[type]!;
                          final bool selected = type == _scene;
                          return ChoiceChip(
                            avatar: _Photo(s.thumb,
                                fallback: s.emoji,
                                width: 24,
                                height: 24,
                                circle: true),
                            label: Text(
                              s.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: selected ? Colors.white : _kInk,
                              ),
                            ),
                            selected: selected,
                            showCheckmark: false,
                            selectedColor: _kPrimary,
                            backgroundColor: Colors.white.withOpacity(0.9),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            onSelected: (_) => _changeScene(type),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "I feel better",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: _kPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🤗 5. Ask a parent or trusted adult to come (real portraits)
// ─────────────────────────────────────────────────────────────

class _Person {
  final String name;
  final String photo;
  final String emoji; // fallback only

  const _Person(this.name, this.photo, this.emoji);
}

class _CaregiverScreen extends StatefulWidget {
  const _CaregiverScreen();

  @override
  State<_CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<_CaregiverScreen> {
  static const Color _red = Color(0xFFEF5350);

  static const List<_Person> _people = [
    _Person("Mom", _Photos.mom, "👩"),
    _Person("Dad", _Photos.dad, "👨"),
    _Person("Teacher", _Photos.teacher, "🧑‍🏫"),
    _Person("Caregiver", _Photos.caregiverPerson, "🧑‍🤝‍🧑"),
  ];

  final FlutterTts _tts = FlutterTts();
  _Person? _selected;

  String get _message =>
      _selected == null ? "" : "I want my ${_selected!.name}. Please come.";

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      final engines = await _tts.getEngines;
      if (engines is List && engines.contains("com.google.android.tts")) {
        await _tts.setEngine("com.google.android.tts");
      }
      final available = await _tts.isLanguageAvailable("en-US");
      if (available == true) {
        await _tts.setLanguage("en-US");
      }
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
    } catch (e) {
      debugPrint("TTS setup error: $e");
    }
  }

  Future<void> _choose(_Person person) async {
    setState(() => _selected = person);
    await _speak();
  }

  Future<void> _speak() async {
    if (_selected == null) return;
    try {
      await _tts.stop();
      await _tts.speak(_message);
    } catch (e) {
      debugPrint("TTS speak error: $e");
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CalmScaffold(
      title: "I Want My Person",
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Who do you want?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF283593),
              ),
            ),
            const SizedBox(height: 18),

            // 👥 Person choices
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _people.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final person = _people[index];
                final bool selected = _selected?.name == person.name;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _choose(person),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFFEBEE)
                            : Colors.white.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? _red : _red.withOpacity(0.25),
                          width: selected ? 3 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _red.withOpacity(0.15),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Photo(person.photo,
                              fallback: person.emoji,
                              width: 86,
                              height: 86,
                              circle: true),
                          const SizedBox(height: 8),
                          Text(
                            person.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _kInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),

            // 📣 Big message to show to an adult
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _red.withOpacity(_selected == null ? 0.2 : 0.6),
                  width: 2,
                ),
              ),
              child: _selected == null
                  ?  Text(
                      "Tap a person. I will say it out loud, and you can show this screen to an adult.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    )
                  : Column(
                      children: [
                        Center(
                          child: _Photo(_selected!.photo,
                              fallback: _selected!.emoji,
                              width: 130,
                              height: 130,
                              circle: true),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _kInk,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: _red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _speak,
                          icon: const Icon(Icons.volume_up_rounded),
                          label: const Text(
                            "Say it again",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Go back",
                style: TextStyle(fontWeight: FontWeight.bold, color: _kPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}