import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'quiz_data.dart';
// Import your HomePage widget file here:
import 'home.dart';

// 🖼️ BACKGROUND IMAGE for the quiz screen (pp1.jpg)
const String _kQuizBgAsset = 'assets/images/pp1.jpg';

// ─────────────────────────────────────────────────────────────
// 📦 ONE FINISHED QUIZ (saved in history)
// ─────────────────────────────────────────────────────────────
class QuizRecord {
  final DateTime date;
  final int total; // questions answered
  final int correct; // correct answers
  final int seconds; // time taken
  // emotion -> [asked, correct]
  final Map<String, List<int>> perEmotion;

  QuizRecord({
    required this.date,
    required this.total,
    required this.correct,
    required this.seconds,
    required this.perEmotion,
  });

  /// Accuracy of this quiz in % = correct / total × 100
  double get accuracy => total == 0 ? 0 : correct / total * 100;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'total': total,
        'correct': correct,
        'seconds': seconds,
        'perEmotion': perEmotion,
      };

  factory QuizRecord.fromJson(Map<String, dynamic> j) => QuizRecord(
        date: DateTime.parse(j['date'] as String),
        total: j['total'] as int,
        correct: j['correct'] as int,
        seconds: j['seconds'] as int,
        perEmotion: (j['perEmotion'] as Map).map(
          (k, v) => MapEntry(
            k as String,
            (v as List).map((e) => e as int).toList(),
          ),
        ),
      );
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _displayName = "User";
  bool _isLoadingName = true;

  // 🎚️ Quiz length chosen by the user (null = still on the selection screen)
  int? _selectedQuizLength;

  // 📊 Dynamic Quiz State Engines
  List<Map<String, dynamic>> _activeQuizSet = [];
  int _currentQuestionIndex = 0;
  int _totalCorrectAnswers = 0;
  String? _selectedOption;
  bool _isAnswered = false;
  bool _isQuizFinished = false;
  List<String> _shuffledCurrentOptions = [];

  // 📝 Tracking for history / statistics
  final List<Map<String, dynamic>> _answerLog = []; // {emotion, correct}
  final Stopwatch _quizTimer = Stopwatch();
  QuizRecord? _lastRecord;
  List<QuizRecord> _history = []; // oldest first
  bool _historyLoaded = false;

  // Available quiz sizes shown on the selection screen
  static const List<Map<String, dynamic>> _quizLengthChoices = [
    {
      "count": 10,
      "title": "Quick Quiz",
      "subtitle": "10 questions • about 2 minutes",
      "icon": Icons.bolt,
      "color": Colors.green,
    },
    {
      "count": 20,
      "title": "Standard Quiz",
      "subtitle": "20 questions • about 5 minutes",
      "icon": Icons.timer,
      "color": Colors.orange,
    },
    {
      "count": 30,
      "title": "Challenge Quiz",
      "subtitle": "30 questions • about 8 minutes",
      "icon": Icons.local_fire_department,
      "color": Colors.redAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchLoggedInUsername();
    _loadHistory();
  }

  // ───────────────────── PROFILE ─────────────────────

  void _fetchLoggedInUsername() {
    try {
      final User? currentUserProfile = Supabase.instance.client.auth.currentUser;
      if (currentUserProfile != null && currentUserProfile.userMetadata != null) {
        final String? usernameFromMetadata =
            currentUserProfile.userMetadata!['username'] as String?;
        if (usernameFromMetadata != null && usernameFromMetadata.trim().isNotEmpty) {
          setState(() {
            _displayName = usernameFromMetadata.trim();
          });
        }
      }
    } catch (error) {
      debugPrint("Error loading profile: $error");
    } finally {
      setState(() {
        _isLoadingName = false;
      });
    }
  }

  // ───────────────────── HISTORY STORAGE ─────────────────────

  // Each logged-in user has their own history on this phone
  String get _historyKey {
    final id = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
    return 'quiz_history_$id';
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _history = list
            .map((e) => QuizRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      debugPrint("Error loading history: $e");
      _history = [];
    }
    if (mounted) setState(() => _historyLoaded = true);
  }

  Future<void> _saveHistory() async {
    try {
      // keep only the latest 100 quizzes
      if (_history.length > 100) {
        _history = _history.sublist(_history.length - 100);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _historyKey, jsonEncode(_history.map((r) => r.toJson()).toList()));
    } catch (e) {
      debugPrint("Error saving history: $e");
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    if (mounted) setState(() => _history = []);
  }

  // ───────────────────── STATISTICS (formulas) ─────────────────────

  /// OVERALL ACCURACY (%) = (all correct answers ÷ all questions answered) × 100
  /// (weighted across every quiz, so long quizzes count more than short ones)
  double get _overallAccuracy {
    final totalQ = _history.fold<int>(0, (s, r) => s + r.total);
    if (totalQ == 0) return 0;
    final totalC = _history.fold<int>(0, (s, r) => s + r.correct);
    return totalC / totalQ * 100;
  }

  /// CONSISTENCY (0–100) = 100 × (1 − σ ÷ 50)
  /// σ = standard deviation of the accuracy of the last 10 quizzes.
  /// 50 is the largest σ possible for scores between 0 and 100.
  /// Same score every time → σ = 0 → 100% consistent.
  double? get _consistency {
    if (_history.length < 2) return null;
    final recent = _history.length > 10
        ? _history.sublist(_history.length - 10)
        : _history;
    final scores = recent.map((r) => r.accuracy).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final variance =
        scores.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
            scores.length;
    final sigma = sqrt(variance);
    return (100 * (1 - sigma / 50)).clamp(0, 100).toDouble();
  }

  /// TREND (percentage points) = average accuracy of the latest k quizzes
  ///                           − average accuracy of the k quizzes before them
  /// where k = min(3, quizzes ÷ 2).
  double? get _trend {
    final n = _history.length;
    if (n < 2) return null;
    final k = min(3, n ~/ 2);
    double avg(List<QuizRecord> l) =>
        l.map((r) => r.accuracy).reduce((a, b) => a + b) / l.length;
    final latest = _history.sublist(n - k);
    final before = _history.sublist(n - 2 * k, n - k);
    return avg(latest) - avg(before);
  }

  double get _bestScore =>
      _history.isEmpty ? 0 : _history.map((r) => r.accuracy).reduce(max);

  /// Average seconds per question = total time ÷ total questions
  double get _avgSecondsPerQuestion {
    final totalQ = _history.fold<int>(0, (s, r) => s + r.total);
    if (totalQ == 0) return 0;
    final totalS = _history.fold<int>(0, (s, r) => s + r.seconds);
    return totalS / totalQ;
  }

  /// emotion -> [asked, correct] across ALL quizzes
  Map<String, List<int>> get _overallPerEmotion {
    final Map<String, List<int>> out = {};
    for (final r in _history) {
      r.perEmotion.forEach((emotion, v) {
        final cur = out.putIfAbsent(emotion, () => [0, 0]);
        cur[0] += v[0];
        cur[1] += v[1];
      });
    }
    return out;
  }

  // ───────────────────── QUIZ LOGIC ─────────────────────

  // ▶️ Starts a quiz with the chosen number of questions
  void _startQuiz(int questionCount) {
    _answerLog.clear();
    _quizTimer
      ..reset()
      ..start();
    setState(() {
      _selectedQuizLength = questionCount;
      _activeQuizSet = QuizData.getRandomQuizSet(questionCount: questionCount);
      _currentQuestionIndex = 0;
      _totalCorrectAnswers = 0;
      _isQuizFinished = false;
      _lastRecord = null;
    });

    _prepareDynamicOptions();
  }

  // 🔙 Returns to the quiz length selection screen
  void _backToSelection() {
    _quizTimer
      ..stop()
      ..reset();
    setState(() {
      _selectedQuizLength = null;
      _activeQuizSet = [];
      _currentQuestionIndex = 0;
      _totalCorrectAnswers = 0;
      _isQuizFinished = false;
      _selectedOption = null;
      _isAnswered = false;
      _shuffledCurrentOptions = [];
      _lastRecord = null;
    });
  }

  // 🔀 Uses the options already built in QuizData for the current question
  void _prepareDynamicOptions() {
    if (_activeQuizSet.isEmpty) return;

    final List<String> choices = List<String>.from(
      _activeQuizSet[_currentQuestionIndex]["options"] as List,
    );

    setState(() {
      _shuffledCurrentOptions = choices;
      _selectedOption = null;
      _isAnswered = false;
    });
  }

  void _selectOption(String choice, String correctOption) {
    if (_isAnswered) return;

    final bool isCorrect = choice == correctOption;
    _answerLog.add({"emotion": correctOption, "correct": isCorrect});

    setState(() {
      _selectedOption = choice;
      _isAnswered = true;
      if (isCorrect) {
        _totalCorrectAnswers += 1;
      }
    });
  }

  void _navigateToNextQuestion() {
    if (_currentQuestionIndex < _activeQuizSet.length - 1) {
      setState(() {
        _currentQuestionIndex += 1;
      });
      _prepareDynamicOptions();
    } else {
      _finishQuiz();
    }
  }

  // 🏁 Builds the record, saves it to history and shows the results
  Future<void> _finishQuiz() async {
    _quizTimer.stop();

    final Map<String, List<int>> perEmotion = {};
    for (final a in _answerLog) {
      final e = a["emotion"] as String;
      final cur = perEmotion.putIfAbsent(e, () => [0, 0]);
      cur[0] += 1;
      if (a["correct"] == true) cur[1] += 1;
    }

    final record = QuizRecord(
      date: DateTime.now(),
      total: _answerLog.length,
      correct: _totalCorrectAnswers,
      seconds: _quizTimer.elapsed.inSeconds,
      perEmotion: perEmotion,
    );

    setState(() {
      _history.add(record);
      _lastRecord = record;
      _isQuizFinished = true;
    });
    await _saveHistory();
  }

  // 🚪 Signs out from Supabase and redirects directly to HomePage, clearing backstack
  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error logging out: $error")),
        );
      }
    }
  }

  // ───────────────────── SMALL HELPERS ─────────────────────

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day} ${months[d.month - 1]} ${d.year}, $h:$m $ap';
  }

  String _fmtDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '${m}m ${s}s';
  }

  Color _accColor(double p) {
    if (p >= 80) return Colors.green;
    if (p >= 60) return Colors.orange;
    return Colors.redAccent;
  }

  String _accLabel(double p) {
    if (p >= 80) return "Great job!";
    if (p >= 60) return "Good, keep going";
    return "Keep practising";
  }

  String _consistencyLabel(double c) {
    if (c >= 85) return "Very steady";
    if (c >= 70) return "Steady";
    if (c >= 50) return "Varies a bit";
    return "Up and down";
  }

  // ───────────────────── UI: WELCOME ─────────────────────

  // 👋 Welcome text shown at the top of every state
  Widget _buildWelcome() {
    return _isLoadingName
        ? const SizedBox(
            height: 32,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        : Text(
            "Welcome back, $_displayName! 👋",
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent),
          );
  }

  // ───────────────────── UI: LENGTH SELECTION ─────────────────────

  Widget _buildLengthSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Choose your quiz length",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          "Easy questions about 6 basic feelings: 😊 Happy, 😢 Sad, 😠 Angry, 😨 Scared, 😲 Surprised, 🤢 Disgusted.",
          style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        ..._quizLengthChoices.map((choice) {
          final int count = choice["count"] as int;
          final String title = choice["title"] as String;
          final String subtitle = choice["subtitle"] as String;
          final IconData icon = choice["icon"] as IconData;
          final Color color = choice["color"] as Color;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _startQuiz(count),
              child: Card(
                color: Colors.white.withOpacity(0.95),
                elevation: 3,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: color.withOpacity(0.15),
                        child: Icon(icon, color: color, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$count Questions",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              title,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: color),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ───────────────────── UI: PROGRESS DASHBOARD ─────────────────────

  Widget _statTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    String? sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          if (sub != null)
            Text(sub,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Card(
      color: Colors.white.withOpacity(0.95),
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, color: Colors.blueAccent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text("Your Progress",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  tooltip: "How is this calculated?",
                  icon: const Icon(Icons.info_outline),
                  onPressed: _showFormulaDialog,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!_historyLoaded)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ))
            else if (_history.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12)),
                child: const Text(
                  "No quizzes yet. Take your first quiz above and your accuracy, consistency and history will appear here. 🌱",
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              )
            else
              ..._buildProgressContent(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProgressContent() {
    final acc = _overallAccuracy;
    final cons = _consistency;
    final trend = _trend;
    final totalQ = _history.fold<int>(0, (s, r) => s + r.total);
    final emotionStats = _overallPerEmotion;

    // Strongest / weakest emotion (needs at least 2 answers to be fair)
    String? strongest, weakest;
    double bestP = -1, worstP = 101;
    emotionStats.forEach((e, v) {
      if (v[0] < 2) return;
      final p = v[1] / v[0] * 100;
      if (p > bestP) {
        bestP = p;
        strongest = e;
      }
      if (p < worstP) {
        worstP = p;
        weakest = e;
      }
    });

    return [
      Row(
        children: [
          Expanded(
            child: _statTile(
              icon: Icons.check_circle,
              color: _accColor(acc),
              label: "Accuracy",
              value: "${acc.toStringAsFixed(1)}%",
              sub: _accLabel(acc),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statTile(
              icon: Icons.stacked_line_chart,
              color: Colors.indigo,
              label: "Consistency",
              value: cons == null ? "--" : "${cons.toStringAsFixed(0)}%",
              sub: cons == null
                  ? "Take 2+ quizzes"
                  : _consistencyLabel(cons),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _statTile(
              icon: Icons.quiz,
              color: Colors.teal,
              label: "Quizzes taken",
              value: "${_history.length}",
              sub: "$totalQ questions",
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statTile(
              icon: Icons.emoji_events,
              color: Colors.amber.shade800,
              label: "Best score",
              value: "${_bestScore.toStringAsFixed(0)}%",
              sub: "${_avgSecondsPerQuestion.toStringAsFixed(1)}s per question",
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),

      // 📈 Trend line
      if (trend != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (trend >= 0 ? Colors.green : Colors.orange).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                trend >= 0 ? Icons.trending_up : Icons.trending_down,
                color: trend >= 0 ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  trend.abs() < 0.5
                      ? "Your recent quizzes are about the same as before."
                      : trend > 0
                          ? "Improving! Your recent quizzes are ${trend.toStringAsFixed(1)} points better than before."
                          : "Your recent quizzes are ${trend.abs().toStringAsFixed(1)} points lower than before. Keep practising!",
                  style: const TextStyle(fontSize: 13.5, height: 1.3),
                ),
              ),
            ],
          ),
        ),

      // 😊 Accuracy by emotion
      if (emotionStats.isNotEmpty) ...[
        const SizedBox(height: 18),
        const Text("Accuracy by feeling",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...QuizData.easyEmotions.where((e) => emotionStats.containsKey(e)).map(
          (e) {
            final v = emotionStats[e]!;
            final p = v[0] == 0 ? 0.0 : v[1] / v[0] * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 112,
                    child: Text("${QuizData.faceFor(e)} $e",
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: p / 100,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(_accColor(p)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 74,
                    child: Text("${v[1]}/${v[0]} • ${p.toStringAsFixed(0)}%",
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade800)),
                  ),
                ],
              ),
            );
          },
        ),
        if (strongest != null && weakest != null && strongest != weakest) ...[
          const SizedBox(height: 4),
          Text("⭐ Strongest: $strongest (${bestP.toStringAsFixed(0)}%)",
              style: const TextStyle(fontSize: 13.5)),
          const SizedBox(height: 2),
          Text("🎯 Needs practice: $weakest (${worstP.toStringAsFixed(0)}%)",
              style: const TextStyle(fontSize: 13.5)),
        ],
      ],

      // 🕘 Recent history + button
      const SizedBox(height: 18),
      Row(
        children: [
          const Expanded(
            child: Text("Recent quizzes",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          TextButton.icon(
            onPressed: _showHistorySheet,
            icon: const Icon(Icons.history),
            label: const Text("Full history"),
          ),
        ],
      ),
      ..._history.reversed.take(3).map((r) => _historyTile(r, expandable: false)),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _showHistorySheet,
          icon: const Icon(Icons.history),
          label: Text("View Quiz History (${_history.length})",
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    ];
  }

  // 🕘 One quiz in the history list
  Widget _historyTile(QuizRecord r, {required bool expandable}) {
    final color = _accColor(r.accuracy);

    final header = Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.15),
          child: Text("${r.accuracy.toStringAsFixed(0)}%",
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${r.correct} / ${r.total} correct",
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              Text("${_fmtDate(r.date)}  •  ${_fmtDuration(r.seconds)}",
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ],
    );

    if (!expandable) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: header,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: header,
          children: [
            ...QuizData.easyEmotions
                .where((e) => r.perEmotion.containsKey(e))
                .map((e) {
              final v = r.perEmotion[e]!;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                    "${QuizData.faceFor(e)} $e: ${v[1]}/${v[0]} correct",
                    style: const TextStyle(fontSize: 13.5)),
              );
            }),
            const SizedBox(height: 4),
            Text(
                "Average ${(r.total == 0 ? 0 : r.seconds / r.total).toStringAsFixed(1)}s per question",
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  // 📜 Full history bottom sheet
  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final items = _history.reversed.toList();
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text("Quiz History (${items.length})",
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      if (items.isNotEmpty)
                        TextButton.icon(
                          onPressed: () async {
                            final ok = await _confirmClearHistory();
                            if (ok) {
                              await _clearHistory();
                              if (ctx.mounted) Navigator.pop(ctx);
                            }
                          },
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          label: const Text("Clear",
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text("No quizzes yet."))
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          itemBuilder: (c, i) =>
                              _historyTile(items[i], expandable: true),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool> _confirmClearHistory() async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Clear all history?"),
        content: const Text("All saved quiz results will be deleted."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Clear")),
        ],
      ),
    );
    return r ?? false;
  }

  // ℹ️ Explains the formulas
  void _showFormulaDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("How it is calculated"),
        content: const SingleChildScrollView(
          child: Text(
            "✅ Accuracy\n"
            "(correct answers ÷ questions answered) × 100, counted across all your quizzes.\n\n"
            "📊 Consistency\n"
            "100 × (1 − σ ÷ 50)\n"
            "σ is the standard deviation of your accuracy in the last 10 quizzes. If you score about the same every time, σ is small and consistency is high. It needs at least 2 quizzes.\n\n"
            "📈 Trend\n"
            "Average accuracy of your latest quizzes minus the average of the quizzes before them (up to 3 each).\n\n"
            "💾 History is saved on this phone for your account.",
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Got it")),
        ],
      ),
    );
  }

  // ───────────────────── UI: RESULTS ─────────────────────

  Widget _buildResults() {
    final int total = _activeQuizSet.length;
    final double ratio = total == 0 ? 0 : _totalCorrectAnswers / total;
    final record = _lastRecord;

    return Card(
      color: Colors.white.withOpacity(0.95),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.stars, color: Colors.amber, size: 80),
            const SizedBox(height: 16),
            const Text("Session Complete!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              "You scored $_totalCorrectAnswers out of $total correct answers.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              "Accuracy: ${(ratio * 100).toStringAsFixed(1)}%"
              "${record != null ? "  •  Time: ${_fmtDuration(record.seconds)}" : ""}",
              style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: _accColor(ratio * 100)),
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: ratio,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
              valueColor: AlwaysStoppedAnimation(
                  ratio >= 0.7 ? Colors.green : Colors.orange),
            ),

            // This quiz by feeling
            if (record != null) ...[
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("This quiz by feeling",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: QuizData.easyEmotions
                    .where((e) => record.perEmotion.containsKey(e))
                    .map((e) {
                  final v = record.perEmotion[e]!;
                  final p = v[0] == 0 ? 0.0 : v[1] / v[0] * 100;
                  return Chip(
                    backgroundColor: _accColor(p).withOpacity(0.15),
                    side: BorderSide(color: _accColor(p).withOpacity(0.5)),
                    label: Text("${QuizData.faceFor(e)} ${v[1]}/${v[0]}",
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("✅ Saved to your history",
                    style: TextStyle(
                        fontSize: 12.5, color: Colors.grey.shade700)),
              ),
            ],
            const SizedBox(height: 22),
            // Retake with the same length
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _startQuiz(_selectedQuizLength ?? 10),
              icon: const Icon(Icons.refresh),
              label: Text("New ${_selectedQuizLength ?? 10}-Question Quiz",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            // See progress & history
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _backToSelection,
              icon: const Icon(Icons.insights),
              label: const Text("See My Progress & Change Length",
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: _showHistorySheet,
              icon: const Icon(Icons.history),
              label: const Text("Quiz History"),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────── UI: QUESTION ─────────────────────

  Widget _buildQuestion() {
    final Map<String, dynamic> activeQuestionNode =
        _activeQuizSet[_currentQuestionIndex];
    final String emoji = activeQuestionNode["emoji"] as String;
    final String words = activeQuestionNode["words"] as String;
    final String correct = activeQuestionNode["correct"] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Overall quiz progress bar
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _activeQuizSet.length,
          minHeight: 8,
          backgroundColor: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.white.withOpacity(0.95),
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 90)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    words,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 17,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 10),
                Text("How does this person feel?",
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700)),
                const SizedBox(height: 14),
                ..._shuffledCurrentOptions.map((option) {
                  Color buttonColor = Colors.grey.shade100;
                  Color textColor = Colors.black87;
                  BorderSide borderSide =
                      BorderSide(color: Colors.grey.shade300);
                  if (_isAnswered) {
                    if (option == correct) {
                      buttonColor = Colors.green.shade100;
                      textColor = Colors.green.shade900;
                      borderSide =
                          BorderSide(color: Colors.green.shade700, width: 2);
                    } else if (option == _selectedOption) {
                      buttonColor = Colors.red.shade100;
                      textColor = Colors.red.shade900;
                      borderSide =
                          BorderSide(color: Colors.red.shade700, width: 2);
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        backgroundColor: buttonColor,
                        foregroundColor: textColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: borderSide),
                      ),
                      onPressed: () => _selectOption(option, correct),
                      child: Text("${QuizData.faceFor(option)}  $option",
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                  );
                }),
                if (_isAnswered) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _navigateToNextQuestion,
                    child: Text(
                      _currentQuestionIndex == _activeQuizSet.length - 1
                          ? "Finish Quiz"
                          : "Next Question →",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🌫️ Background: pp1.jpg stretched over the ENTIRE phone screen
  Widget _buildBackground() {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _kQuizBgAsset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            errorBuilder: (context, error, stack) {
              debugPrint("Quiz background failed to load: $error");
              return Container(color: Colors.blue.shade50);
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.10),
                  Colors.white.withOpacity(0.18),
                  Colors.white.withOpacity(0.40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── BUILD ─────────────────────

  @override
  Widget build(BuildContext context) {
    final bool onSelectionScreen = _selectedQuizLength == null;

    String appBarTitle;
    if (onSelectionScreen) {
      appBarTitle = "Emotion Quiz";
    } else if (_isQuizFinished) {
      appBarTitle = "Quiz Results";
    } else {
      appBarTitle =
          "Question ${_currentQuestionIndex + 1} of ${_activeQuizSet.length}";
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 📷 Background image (assets/images/pp1.jpg), full screen
          Positioned.fill(child: _buildBackground()),

          Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: Text(appBarTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: Colors.blue.shade900,
              // Lets the user quit a running quiz and pick another length
              leading: (!onSelectionScreen && !_isQuizFinished)
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: "Quit quiz",
                      onPressed: _backToSelection,
                    )
                  : null,
              actions: [
                // 📜 History button
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: "Quiz history",
                  onPressed: _showHistorySheet,
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: "Logout",
                  onPressed: _handleLogout,
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                // extra top space so content starts below the transparent app bar
                padding:
                    const EdgeInsets.fromLTRB(24, kToolbarHeight + 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcome(),
                    const SizedBox(height: 24),
                    if (onSelectionScreen) ...[
                      _buildLengthSelection(),
                      const SizedBox(height: 14),
                      // 📊 Progress, accuracy, consistency and history
                      _buildProgressSection(),
                    ] else if (_isQuizFinished)
                      _buildResults()
                    else
                      _buildQuestion(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}