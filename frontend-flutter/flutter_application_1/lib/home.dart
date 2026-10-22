import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Used to check login status
import 'camera_screen.dart';
import 'needs_communication_screen.dart';
import 'calming_assistant_screen.dart';
import 'good_lessons_screen.dart'; // 🌟 Good Lessons dashboard
import 'login_screen.dart';
import 'progress_screen.dart';
import 'parents_dashboard_screen.dart'; // 👨‍👩‍👧 NEW: Parents dashboard

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // 🎨 Calm, soft color palette (gentle on sensory sensitivity)
  static const Color _primary = Color(0xFF5C6BC0); // soft indigo
  static const Color _primaryDark = Color(0xFF3F51B5);
  static const Color _bgTop = Color(0xFFE8EAF6);
  static const Color _bgBottom = Color(0xFFF3E5F5);

  // 🖼️ Background photo (direct image link, no download needed)
  static const String _bgImageUrl =
      'https://theplaceforchildrenwithautism.com/wp-content/uploads/2019/08/tips-to-improve-behavior-at-home-in-children-with-autism.jpg';

  // 📷 Opens the camera screen
  void _openCamera(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
  }

  // 🗣️ Opens the Needs Communication board
  void _openNeedsCommunication(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NeedsCommunicationScreen()),
    );
  }

  // 🌿 Opens the Calming Assistant
  void _openCalmingAssistant(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CalmingAssistantScreen()),
    );
  }

  // 🌟 Opens the Good Lessons dashboard
  void _openGoodLessons(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GoodLessonsScreen()),
    );
  }

  // 👨‍👩‍👧 Opens the Parents Dashboard
  void _openParentsDashboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ParentsDashboardScreen()),
    );
  }

  // 🔑 Opens the login screen
  void _openLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // 🔐 Protected progress tracking: checks for an active Supabase session
  void _openProgress(BuildContext context) {
    final currentSessionUser = Supabase.instance.client.auth.currentUser;

    if (currentSessionUser != null) {
      // User is logged in -> open the progress dashboard
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProgressScreen()),
      );
    } else {
      // User is NOT logged in -> show a friendly message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Please log in first to access your progress tracking!",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );

      // Take them straight to the login screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Base gradient (also shown if the photo can't load)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: Stack(
          children: [
            // 📷 Background photo
            Positioned.fill(
              child: Image.network(
                _bgImageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                gaplessPlayback: true,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const SizedBox.shrink(),
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
            ),

            // 🌫️ Soft color layer that merges the photo into the app palette
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _bgTop.withOpacity(0.55),
                      _bgTop.withOpacity(0.72),
                      _bgBottom.withOpacity(0.88),
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
              child: _DecorCircle(size: 220, color: _primary.withOpacity(0.12)),
            ),
            Positioned(
              top: 140,
              left: -80,
              child: _DecorCircle(
                  size: 170, color: Colors.purple.withOpacity(0.08)),
            ),
            Positioned(
              bottom: -90,
              left: -50,
              child: _DecorCircle(size: 240, color: _primary.withOpacity(0.10)),
            ),
            Positioned(
              bottom: 120,
              right: -40,
              child: _DecorCircle(
                  size: 120, color: Colors.teal.withOpacity(0.08)),
            ),

            // 📱 Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🧠 Logo / header icon
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_primary, _primaryDark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withOpacity(0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emoji_emotions_outlined,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 🏷️ Title
                      const Text(
                        "Emotion Recognition",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF283593),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Learn to understand feelings,\nat your own pace 💙",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // 📷 Camera card
                      _MenuCard(
                        icon: Icons.camera_alt_rounded,
                        title: "Camera",
                        subtitle: "Detect emotions using your camera",
                        color: const Color(0xFF42A5F5),
                        onTap: () => _openCamera(context),
                      ),
                      const SizedBox(height: 16),

                      // 🗣️ Needs Communication card
                      _MenuCard(
                        icon: Icons.record_voice_over_rounded,
                        title: "Needs Communication",
                        subtitle: "Tap pictures to say what you need",
                        color: const Color(0xFFFFA726),
                        onTap: () => _openNeedsCommunication(context),
                      ),
                      const SizedBox(height: 16),

                      // 🌿 Calming Assistant card
                      _MenuCard(
                        icon: Icons.self_improvement_rounded,
                        title: "Calming Assistant",
                        subtitle: "Feeling upset? Find something calming",
                        color: const Color(0xFF26A69A),
                        onTap: () => _openCalmingAssistant(context),
                      ),
                      const SizedBox(height: 16),

                      // 🌟 Good Lessons card
                      _MenuCard(
                        icon: Icons.auto_stories_rounded,
                        title: "Good Lessons",
                        subtitle: "One simple lesson a day, with stories",
                        color: const Color(0xFFEC407A),
                        onTap: () => _openGoodLessons(context),
                      ),
                      const SizedBox(height: 16),

                      // 👨‍👩‍👧 Parents Dashboard card (NEW)
                      _MenuCard(
                        icon: Icons.family_restroom_rounded,
                        title: "Parents Dashboard",
                        subtitle: "Add photos of family, likes and fears",
                        color: const Color(0xFF7E57C2),
                        onTap: () => _openParentsDashboard(context),
                      ),
                      const SizedBox(height: 16),

                      // 📊 Progress card
                      _MenuCard(
                        icon: Icons.bar_chart_rounded,
                        title: "Progress Tracking",
                        subtitle: "Practice quizzes and see your progress",
                        color: const Color(0xFF66BB6A),
                        onTap: () => _openProgress(context),
                      ),
                      const SizedBox(height: 16),

                      // 🔑 Sign in card
                      _MenuCard(
                        icon: Icons.login_rounded,
                        title: "Sign In",
                        subtitle: "Log in to save your progress",
                        color: const Color(0xFFAB47BC),
                        onTap: () => _openLogin(context),
                      ),
                      const SizedBox(height: 28),

                      // 💬 Footer note
                      Text(
                        "Take your time. There is no rush. 🌱",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
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

// 🔵 Soft decorative circle used in the background
class _DecorCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// 🃏 Reusable menu card with icon, title, subtitle and arrow
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 18,
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withOpacity(0.85), color],
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),

                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263238),
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

                // Arrow
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 18, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}