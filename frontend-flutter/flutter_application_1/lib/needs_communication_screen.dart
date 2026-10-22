import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

// 🖼️ BACKGROUND IMAGE for the Needs Communication screen (from your project)
const String _kBgAsset = 'assets/images/c1.jpg';

// 🧩 One picture card on the communication board
class _CommItem {
  final String emoji; // the "picture"
  final String label; // short text under the picture
  final String message; // full sentence that is spoken aloud
  final String category;

  const _CommItem({
    required this.emoji,
    required this.label,
    required this.message,
    required this.category,
  });
}

class NeedsCommunicationScreen extends StatefulWidget {
  const NeedsCommunicationScreen({super.key});

  @override
  State<NeedsCommunicationScreen> createState() =>
      _NeedsCommunicationScreenState();
}

class _NeedsCommunicationScreenState extends State<NeedsCommunicationScreen> {
  // 🎨 Same calm palette as the rest of the app
  static const Color _primary = Color(0xFF5C6BC0);
  static const Color _primaryDark = Color(0xFF3F51B5);
  static const Color _bgTop = Color(0xFFE8EAF6);
  static const Color _bgBottom = Color(0xFFF3E5F5);

  // 🏷️ Categories and their colors
  static const List<String> _categories = [
    "All",
    "Needs",
    "Feelings",
    "Social",
    "Activities",
  ];

  static const Map<String, Color> _categoryColors = {
    "Needs": Color(0xFF42A5F5),
    "Feelings": Color(0xFFAB47BC),
    "Social": Color(0xFF26A69A),
    "Activities": Color(0xFFFFA726),
  };

  // 🖼️ All picture cards. Add or edit items here to change the board.
  static const List<_CommItem> _items = [
    // --- Needs ---
    _CommItem(
        emoji: "🤝",
        label: "I need help",
        message: "I need help.",
        category: "Needs"),
    _CommItem(
        emoji: "🍽️",
        label: "I'm hungry",
        message: "I am hungry. I want food.",
        category: "Needs"),
    _CommItem(
        emoji: "💧",
        label: "I want water",
        message: "I want water.",
        category: "Needs"),
    _CommItem(
        emoji: "🚽",
        label: "Bathroom",
        message: "I need to use the bathroom.",
        category: "Needs"),
    _CommItem(
        emoji: "🛏️",
        label: "I want to sleep",
        message: "I want to sleep.",
        category: "Needs"),
    _CommItem(
        emoji: "⏸️",
        label: "I need a break",
        message: "I need a break.",
        category: "Needs"),
    _CommItem(
        emoji: "🚿",
        label: "Shower",
        message: "I want to take a shower.",
        category: "Needs"),
    _CommItem(
        emoji: "🤕",
        label: "I'm in pain",
        message: "I am in pain. It hurts.",
        category: "Needs"),

    // --- Feelings ---
    _CommItem(
        emoji: "😣",
        label: "Uncomfortable",
        message: "I feel uncomfortable.",
        category: "Feelings"),
    _CommItem(
        emoji: "😊",
        label: "Happy",
        message: "I feel happy.",
        category: "Feelings"),
    _CommItem(
        emoji: "😢",
        label: "Sad",
        message: "I feel sad.",
        category: "Feelings"),
    _CommItem(
        emoji: "😠",
        label: "Angry",
        message: "I feel angry.",
        category: "Feelings"),
    _CommItem(
        emoji: "😨",
        label: "Scared",
        message: "I feel scared.",
        category: "Feelings"),
    _CommItem(
        emoji: "🥱",
        label: "Tired",
        message: "I feel tired.",
        category: "Feelings"),
    _CommItem(
        emoji: "🔊",
        label: "Too loud",
        message: "It is too loud for me.",
        category: "Feelings"),

    // --- Social ---
    _CommItem(
        emoji: "💬",
        label: "Talk to someone",
        message: "I want to talk to someone.",
        category: "Social"),
    _CommItem(
        emoji: "🧍",
        label: "Be alone",
        message: "I want to be alone.",
        category: "Social"),
    _CommItem(
        emoji: "🤗",
        label: "I need a hug",
        message: "I need a hug.",
        category: "Social"),
    _CommItem(
        emoji: "✅",
        label: "Yes",
        message: "Yes.",
        category: "Social"),
    _CommItem(
        emoji: "❌",
        label: "No",
        message: "No.",
        category: "Social"),
    _CommItem(
        emoji: "🙏",
        label: "Thank you",
        message: "Thank you.",
        category: "Social"),

    // --- Activities ---
    _CommItem(
        emoji: "⚽",
        label: "I want to play",
        message: "I want to play.",
        category: "Activities"),
    _CommItem(
        emoji: "🌳",
        label: "Go to the park",
        message: "I want to go to the park.",
        category: "Activities"),
    _CommItem(
        emoji: "📺",
        label: "Watch TV",
        message: "I want to watch TV.",
        category: "Activities"),
    _CommItem(
        emoji: "🎵",
        label: "Listen to music",
        message: "I want to listen to music.",
        category: "Activities"),
    _CommItem(
        emoji: "🎨",
        label: "Draw",
        message: "I want to draw.",
        category: "Activities"),
    _CommItem(
        emoji: "🏠",
        label: "Go home",
        message: "I want to go home.",
        category: "Activities"),
  ];

  final FlutterTts _tts = FlutterTts();

  String _selectedCategory = "All";
  _CommItem? _selectedItem; // last tapped card
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  // 🔊 Sets up the text-to-speech voice (calm and a little slower)
  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      _tts.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _tts.setErrorHandler((message) {
        debugPrint("TTS error: $message");
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (e) {
      debugPrint("TTS setup error: $e");
    }
  }

  // 🗣️ Speaks the message of a tapped card
  Future<void> _speak(_CommItem item) async {
    setState(() => _selectedItem = item);
    try {
      await _tts.stop();
      await _tts.speak(item.message);
    } catch (e) {
      debugPrint("TTS speak error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.orange,
          content: const Text(
            "Sorry, the voice could not play on this device.",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Color _colorFor(String category) =>
      _categoryColors[category] ?? _primary;

  // 🔵 Soft decorative circle
  Widget _decorCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // 💬 Big banner showing what is being said
  Widget _buildMessageBanner() {
    final _CommItem? item = _selectedItem;
    final Color accent = item == null ? _primary : _colorFor(item.category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        // Tap the banner to hear the message again
        onTap: item == null ? null : () => _speak(item),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accent.withOpacity(item == null ? 0.2 : 0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: item == null
                    ? Icon(Icons.touch_app_rounded, color: accent, size: 34)
                    : Text(item.emoji, style: const TextStyle(fontSize: 36)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item == null ? "Tap a picture" : "I am saying:",
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item == null
                          ? "Choose a picture below and I will say it out loud."
                          : item.message,
                      style: TextStyle(
                        fontSize: item == null ? 15 : 20,
                        fontWeight: FontWeight.w800,
                        color: item == null
                            ? Colors.grey.shade700
                            : const Color(0xFF263238),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (item != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(_isSpeaking ? 0.25 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isSpeaking
                        ? Icons.volume_up_rounded
                        : Icons.replay_rounded,
                    color: accent,
                    size: 26,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 🏷️ Category filter chips
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final String category = _categories[index];
          final bool selected = category == _selectedCategory;
          final Color color = _colorFor(category);

          return ChoiceChip(
            label: Text(
              category,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: selected ? Colors.white : const Color(0xFF37474F),
              ),
            ),
            selected: selected,
            showCheckmark: false,
            selectedColor: color,
            backgroundColor: Colors.white.withOpacity(0.95),
            side: BorderSide(
              color: selected ? color : Colors.grey.shade300,
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            onSelected: (_) => setState(() => _selectedCategory = category),
          );
        },
      ),
    );
  }

  // 🃏 One picture card
  Widget _buildCard(_CommItem item) {
    final Color color = _colorFor(item.category);
    final bool isSelected = _selectedItem == item;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _speak(item),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Color.alphaBlend(color.withOpacity(0.12), Colors.white)
                : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.25),
              width: isSelected ? 3 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(item.emoji, style: const TextStyle(fontSize: 56)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF263238),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_CommItem> visibleItems = _selectedCategory == "All"
        ? _items
        : _items.where((i) => i.category == _selectedCategory).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _primaryDark,
        title: const Text(
          "Needs Communication",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: Stack(
          children: [
            // 📷 Your background image (assets/images/c1.jpg)
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
            // (lower the numbers to show more of the image)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _bgTop.withOpacity(0.35),
                      _bgTop.withOpacity(0.55),
                      _bgBottom.withOpacity(0.85),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // 🔵 Decorative background circles
            Positioned(
              top: -70,
              right: -60,
              child: _decorCircle(220, _primary.withOpacity(0.12)),
            ),
            Positioned(
              bottom: -90,
              left: -60,
              child: _decorCircle(240, _primary.withOpacity(0.10)),
            ),

            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: _buildMessageBanner(),
                  ),
                  _buildCategoryChips(),
                  const SizedBox(height: 12),

                  // 🖼️ Picture grid
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double w = constraints.maxWidth;
                        final int columns = w >= 900 ? 4 : (w >= 600 ? 3 : 2);

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.95,
                          ),
                          itemCount: visibleItems.length,
                          itemBuilder: (context, index) =>
                              _buildCard(visibleItems[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}