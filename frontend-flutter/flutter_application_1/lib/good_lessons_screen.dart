import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

// 🎨 Same calm palette as the rest of the app
const Color _kPrimary = Color(0xFF5C6BC0);
const Color _kPrimaryDark = Color(0xFF3F51B5);
const Color _kBgTop = Color(0xFFE8EAF6);
const Color _kBgBottom = Color(0xFFF3E5F5);
const Color _kInk = Color(0xFF263238);
const Color _kTitle = Color(0xFF283593);

// 🖼️ BACKGROUND IMAGE for the Good Lessons screen (g1.jpg)
const String _kLessonsBgAsset = 'assets/images/g1.jpg';

// ─────────────────────────────────────────────────────────────
// 📚 Lessons data (25 short lessons, one at a time)
// ─────────────────────────────────────────────────────────────

class _Lesson {
  final String emoji; // the "picture" for the lesson
  final String term; // small label (e.g. Sabr, Salah)
  final String title;
  final String line; // the one simple lesson
  final String story; // short story for children
  final String tryThis; // one small action for today

  const _Lesson({
    required this.emoji,
    required this.term,
    required this.title,
    required this.line,
    required this.story,
    required this.tryThis,
  });
}

const List<_Lesson> _lessons = [
  _Lesson(
    emoji: "🍎",
    term: "Bismillah",
    title: "Start with Bismillah",
    line: "Say Bismillah before you begin.",
    story:
        "Yusuf was about to eat his apple. He stopped, smiled and said, Bismillah. He felt happy because he began in the name of Allah.",
    tryThis: "Say Bismillah before eating, drinking and starting homework.",
  ),
  _Lesson(
    emoji: "☀️",
    term: "Alhamdulillah",
    title: "Say Alhamdulillah",
    line: "Thank Allah for every blessing.",
    story:
        "Maryam woke up to a sunny morning. She hugged her mom and said, Alhamdulillah for this beautiful day.",
    tryThis: "Say Alhamdulillah when you feel happy and after you eat.",
  ),
  _Lesson(
    emoji: "🎁",
    term: "Shukr",
    title: "Be Thankful",
    line: "Say thank you to Allah and to people.",
    story:
        "Ali's friend gave him a pencil. Ali said thank you and Jazakallahu khairan, which means may Allah reward you with goodness.",
    tryThis: "Thank two people today for something they did for you.",
  ),
  _Lesson(
    emoji: "🕌",
    term: "Salah",
    title: "Pray on Time",
    line: "Salah is our special talk with Allah.",
    story:
        "When the adhan began, Hamza put his toys away and made wudu. After praying, he felt calm and peaceful.",
    tryThis: "Make wudu and pray one salah together with your family.",
  ),
  _Lesson(
    emoji: "🌱",
    term: "Sabr",
    title: "Be Patient",
    line: "Wait calmly. Good things come with sabr.",
    story:
        "Sara planted a seed and wanted a flower right away. She watered it every day, and one morning a tiny green leaf appeared.",
    tryThis: "When you have to wait, take a deep breath and count to ten.",
  ),
  _Lesson(
    emoji: "🤲",
    term: "Tawakkul",
    title: "Trust Allah",
    line: "Do your best, then trust Allah.",
    story:
        "Bilal studied hard for his spelling test. Then he made dua and trusted Allah. He felt calm, not worried.",
    tryThis: "Do your best at one thing today, then make a short dua.",
  ),
  _Lesson(
    emoji: "💎",
    term: "Sidq",
    title: "Tell the Truth",
    line: "Always tell the truth, even when it is hard.",
    story:
        "Zayd spilled some juice by accident. He told his dad the truth right away. Dad smiled and said, Thank you for being honest.",
    tryThis: "If you make a mistake today, tell the truth quickly.",
  ),
  _Lesson(
    emoji: "🔐",
    term: "Amanah",
    title: "Keep Your Promise",
    line: "Keep your promises and take care of what you borrow.",
    story:
        "Aisha borrowed a book from her friend. She kept it clean and gave it back on the day she promised.",
    tryThis: "Keep one promise today, big or small.",
  ),
  _Lesson(
    emoji: "⚖️",
    term: "'Adl",
    title: "Be Fair",
    line: "Treat everyone fairly.",
    story:
        "At the park there was one swing and three children. Omar said, Let's take turns, so everyone could enjoy it.",
    tryThis: "Take turns and share the best spot with someone today.",
  ),
  _Lesson(
    emoji: "👨‍👩‍👧",
    term: "Parents",
    title: "Be Kind to Parents",
    line: "Speak gently and help your parents.",
    story:
        "Hana set the table before her mother asked. Mom hugged her and made dua for her.",
    tryThis: "Help your mom or dad with one small job without being asked.",
  ),
  _Lesson(
    emoji: "📖",
    term: "Qur'an",
    title: "Love the Qur'an",
    line: "Listen to the Qur'an and treat it with respect.",
    story:
        "Ibrahim practiced a short surah every evening. Little by little, he learned it by heart. He kept the Qur'an clean and on a high shelf.",
    tryThis: "Listen to or read a short surah with someone you love.",
  ),
  _Lesson(
    emoji: "🤝",
    term: "Helping",
    title: "Help Others",
    line: "Help someone today, big or small.",
    story:
        "Layla saw a classmate drop her books. She stopped and helped pick them up. They both smiled.",
    tryThis: "Look for one person you can help today.",
  ),
  _Lesson(
    emoji: "💐",
    term: "Visiting the Sick",
    title: "Visit the Sick",
    line: "Cheer up people who are not feeling well.",
    story:
        "Grandpa had a cold. Noor drew him a card and sat with him for a while. Grandpa smiled and said, Shukran, my dear.",
    tryThis: "Make a card or say a kind dua for someone who is unwell.",
  ),
  _Lesson(
    emoji: "💛",
    term: "Astaghfirullah",
    title: "Say Sorry",
    line: "If you do something wrong, say sorry and say Astaghfirullah.",
    story:
        "Kareem pushed his friend by mistake. He said sorry, said Astaghfirullah, and promised to be gentle next time.",
    tryThis: "Say sorry quickly if you hurt someone, then try to do better.",
  ),
  _Lesson(
    emoji: "🍪",
    term: "Sharing",
    title: "Share with Others",
    line: "Share what you have.",
    story:
        "Fatima had two cookies. She gave one to her friend. Both of them felt happy.",
    tryThis: "Share a snack, a toy or your time with someone today.",
  ),
  _Lesson(
    emoji: "👋",
    term: "Salam",
    title: "Say Assalamu Alaikum",
    line: "Greet people with Assalamu Alaikum.",
    story:
        "Musa met his neighbor and said, Assalamu Alaikum. The neighbor smiled and answered, Wa Alaikum Assalam.",
    tryThis: "Greet three people with salam today.",
  ),
  _Lesson(
    emoji: "💖",
    term: "Kindness",
    title: "Be Kind to Others",
    line: "Use kind words and gentle hands.",
    story:
        "Sumaya saw a new girl sitting alone. She said hello and invited her to play. A smile is sadaqah, she remembered.",
    tryThis: "Give three smiles today and say one kind word.",
  ),
  _Lesson(
    emoji: "🧼",
    term: "Cleanliness",
    title: "Stay Clean",
    line: "Keeping clean is part of our faith.",
    story:
        "Adam washed his hands, brushed his teeth and tidied his room. Everything felt fresh and cheerful.",
    tryThis: "Wash your hands well and tidy one small space.",
  ),
  _Lesson(
    emoji: "👵",
    term: "Respect",
    title: "Respect Elders",
    line: "Be polite to grandparents and elders.",
    story:
        "When Grandma came into the room, Zaynab stood up and offered her the best seat. Grandma said, May Allah bless you.",
    tryThis: "Call or visit a grandparent or elder and ask how they are.",
  ),
  _Lesson(
    emoji: "🐱",
    term: "Rahmah",
    title: "Be Kind to Animals",
    line: "Be gentle and kind to animals.",
    story:
        "Idris saw a thirsty little cat. He gave it some fresh water, and the cat purred happily.",
    tryThis: "Be gentle with animals and never tease them.",
  ),
  _Lesson(
    emoji: "🌈",
    term: "Forgiveness",
    title: "Forgive Others",
    line: "Forgive, and your heart feels light.",
    story:
        "Rayan's friend broke his toy by accident and said sorry. Rayan said, It's okay, I forgive you. They played together again.",
    tryThis: "Forgive someone who said sorry to you.",
  ),
  _Lesson(
    emoji: "🌿",
    term: "Humility",
    title: "Be Humble",
    line: "Do not show off. Stay kind and modest.",
    story:
        "Salma won the race. She congratulated the others and said, Alhamdulillah, we all ran well.",
    tryThis: "Celebrate a friend's success today.",
  ),
  _Lesson(
    emoji: "🥣",
    term: "Eating Manners",
    title: "Eat with Good Manners",
    line: "Say Bismillah, eat with your right hand, and eat slowly.",
    story:
        "Yahya sat down, said Bismillah, ate with his right hand and chewed slowly. After the meal he said Alhamdulillah.",
    tryThis: "Eat one meal today slowly, with Bismillah and Alhamdulillah.",
  ),
  _Lesson(
    emoji: "🌙",
    term: "Dua",
    title: "Make Dua",
    line: "You can ask Allah for good things at any time.",
    story:
        "Before bed, Amina raised her hands and asked Allah to keep her family safe. She went to sleep with a peaceful heart.",
    tryThis: "Make a short dua for your family before you sleep.",
  ),
  _Lesson(
    emoji: "🏡",
    term: "Neighbors",
    title: "Love Your Neighbors",
    line: "Be good to the people who live next door.",
    story:
        "Ismail and his mom took some warm bread to their neighbor. The neighbor was so happy, and they became good friends.",
    tryThis: "Say hello to a neighbor or send them a kind message.",
  ),
];

// Each lesson gets a soft color (cycles through this list)
const List<Color> _palette = [
  Color(0xFF42A5F5),
  Color(0xFF26A69A),
  Color(0xFFAB47BC),
  Color(0xFFFFA726),
  Color(0xFFEF5350),
  Color(0xFF66BB6A),
];

Color _colorFor(int index) => _palette[index % _palette.length];

// 📅 One lesson per day: the lesson changes automatically each day
int todaysLessonIndex() {
  final DateTime now = DateTime.now();
  final int dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  return dayOfYear % _lessons.length;
}

// ✅ Lessons the child marked as learned (kept while the app is open)
final Set<int> _learnedLessons = <int>{};

// ─────────────────────────────────────────────────────────────
// 🏠 Dashboard card: place this on the Home screen
// ─────────────────────────────────────────────────────────────
//
//   In home.dart:
//     import 'good_lessons_screen.dart';
//     ...
//     const GoodLessonsDashboardCard(),
//
class GoodLessonsDashboardCard extends StatelessWidget {
  const GoodLessonsDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    final int i = todaysLessonIndex();
    final _Lesson today = _lessons[i];
    final Color color = _colorFor(i);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.95), _kPrimaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GoodLessonsScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  child: Text(today.emoji, style: const TextStyle(fontSize: 38)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Good Lessons of the Day 🌟",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Today: ${today.title}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🌟 Good Lessons screen: one simple lesson at a time
// ─────────────────────────────────────────────────────────────

class GoodLessonsScreen extends StatefulWidget {
  const GoodLessonsScreen({super.key});

  @override
  State<GoodLessonsScreen> createState() => _GoodLessonsScreenState();
}

class _GoodLessonsScreenState extends State<GoodLessonsScreen> {
  final FlutterTts _tts = FlutterTts();
  late int _index;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _index = todaysLessonIndex();
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
      await _tts.setSpeechRate(0.42); // slow and clear for children
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _speaking = false);
      });
    } catch (e) {
      debugPrint("Lessons TTS setup error: $e");
    }
  }

  // 🔊 Optional audio: reads the lesson aloud
  Future<void> _toggleAudio() async {
    final _Lesson l = _lessons[_index];
    try {
      if (_speaking) {
        await _tts.stop();
        if (mounted) setState(() => _speaking = false);
        return;
      }
      setState(() => _speaking = true);
      await _tts.stop();
      await _tts.speak(
        "${l.title}. ${l.line} Here is a short story. ${l.story} "
        "Try this today. ${l.tryThis}",
      );
    } catch (e) {
      debugPrint("Lessons TTS error: $e");
      if (mounted) setState(() => _speaking = false);
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _speaking = false;
  }

  void _goTo(int newIndex) {
    _stopAudio();
    setState(() {
      _index = (newIndex + _lessons.length) % _lessons.length;
    });
  }

  void _toggleLearned() {
    setState(() {
      if (_learnedLessons.contains(_index)) {
        _learnedLessons.remove(_index);
      } else {
        _learnedLessons.add(_index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text(
              "Great job! You learned a new lesson. 🌟",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  // 📋 Pick any of the 25 lessons
  void _showAllLessons() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "All Good Lessons",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _kTitle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${_learnedLessons.length} of ${_lessons.length} learned",
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: _lessons.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      itemBuilder: (context, i) {
                        final l = _lessons[i];
                        final Color c = _colorFor(i);
                        final bool isCurrent = i == _index;
                        final bool learned = _learnedLessons.contains(i);
                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.pop(context);
                            _goTo(i);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: c.withOpacity(isCurrent ? 0.22 : 0.10),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isCurrent ? c : c.withOpacity(0.3),
                                width: isCurrent ? 3 : 1.5,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(l.emoji,
                                          style:
                                              const TextStyle(fontSize: 32)),
                                      const SizedBox(height: 4),
                                      Text(
                                        l.term,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _kInk,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (learned)
                                  const Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Icon(Icons.check_circle,
                                        color: Colors.green, size: 20),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );

  // 🖼️ The lesson "picture"
  Widget _buildPicture(_Lesson l, Color color) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.45)],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.30),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Text(l.emoji, style: const TextStyle(fontSize: 84)),
          const Positioned(
              top: 4, right: 14, child: Text("✨", style: TextStyle(fontSize: 24))),
          const Positioned(
              bottom: 10, left: 8, child: Text("⭐", style: TextStyle(fontSize: 18))),
        ],
      ),
    );
  }

  Widget _infoBox({
    required String heading,
    required String text,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              height: 1.45,
              color: _kInk,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard() {
    final _Lesson l = _lessons[_index];
    final Color color = _colorFor(_index);
    final bool learned = _learnedLessons.contains(_index);

    return Container(
      key: ValueKey(_index),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.45), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _buildPicture(l, color)),
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l.term,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _kTitle,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l.line,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: _kInk,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          _infoBox(heading: "📖  Short story", text: l.story, color: color),
          const SizedBox(height: 12),
          _infoBox(heading: "🌱  Try this today", text: l.tryThis, color: color),
          const SizedBox(height: 18),

          // 🔊 Optional audio
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _toggleAudio,
            icon: Icon(_speaking
                ? Icons.stop_circle_rounded
                : Icons.volume_up_rounded),
            label: Text(
              _speaking ? "Stop audio" : "Listen (optional audio)",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          // ✅ Mark as learned
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: learned ? Colors.green.shade800 : _kPrimaryDark,
              backgroundColor: learned
                  ? Colors.green.withOpacity(0.12)
                  : Colors.white.withOpacity(0.9),
              side: BorderSide(
                  color: learned ? Colors.green : _kPrimary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _toggleLearned,
            icon: Icon(learned
                ? Icons.check_circle_rounded
                : Icons.check_circle_outline),
            label: Text(
              learned ? "I learned this! ✓" : "I learned this",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int today = todaysLessonIndex();
    final bool isToday = _index == today;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _kPrimaryDark,
        title: const Text("Good Lessons",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: "All lessons",
            onPressed: _showAllLessons,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kBgTop, _kBgBottom],
          ),
        ),
        child: Stack(
          children: [
            // 📷 Background image (assets/images/g1.jpg), full screen
            Positioned.fill(
              child: Image.asset(
                _kLessonsBgAsset,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                errorBuilder: (context, error, stack) {
                  // If you see this in the console, the image path is wrong
                  debugPrint("Lessons background failed to load: $error");
                  return const SizedBox.shrink();
                },
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _kBgTop.withOpacity(0.15),
                      _kBgTop.withOpacity(0.25),
                      _kBgBottom.withOpacity(0.50),
                    ],
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

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Good Lessons of the Day 🌟",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _kTitle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "One simple lesson at a time.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Progress info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Lesson ${_index + 1} of ${_lessons.length}",
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, color: _kInk),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "⭐ ${_learnedLessons.length} learned",
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // The lesson (fades when you move to another one)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildLessonCard(),
                    ),
                    const SizedBox(height: 16),

                    // ◀ ▶ Previous / Next
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              foregroundColor: _kPrimaryDark,
                              backgroundColor: Colors.white.withOpacity(0.9),
                              side: const BorderSide(color: _kPrimary),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => _goTo(_index - 1),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text("Previous",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => _goTo(_index + 1),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text("Next lesson",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (!isToday)
                      TextButton(
                        onPressed: () => _goTo(today),
                        child: const Text(
                          "Go to today's lesson",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: _kPrimary),
                        ),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Back to home",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: _kPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}