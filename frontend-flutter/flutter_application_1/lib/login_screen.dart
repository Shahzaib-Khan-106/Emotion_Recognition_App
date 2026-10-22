import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_screen.dart';
import 'progress_screen.dart';
import 'forgot_password_screen.dart';

// 🖼️ BACKGROUND IMAGE for the Sign In screen (l1.webp)
const String _kLoginBgAsset = 'assets/images/l1.webp';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 🎨 Same calm palette as the home page
  static const Color _primary = Color(0xFF5C6BC0);
  static const Color _primaryDark = Color(0xFF3F51B5);
  static const Color _bgTop = Color(0xFFE8EAF6);
  static const Color _bgBottom = Color(0xFFF3E5F5);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Primary action method: tries to sign in first
  Future<void> _processAuthentication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      // 1. Attempt standard password login
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _showSnackBar("Welcome back! Login successful.", Colors.green);

      if (mounted) {
        // Replace Login and go straight to ProgressScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProgressScreen()),
        );
      }
    } on AuthException catch (error) {
      // 2. Catch if the user profile doesn't exist in Supabase yet
      if (error.message.toLowerCase().contains("invalid login credentials") ||
          error.statusCode == '400') {
        _promptAutomaticSignUp(email, password);
      } else {
        _showSnackBar(error.message, Colors.red);
      }
    } catch (error) {
      _showSnackBar(
          "An unexpected error occurred. Please try again.", Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Dialog offering to create an account automatically
  void _promptAutomaticSignUp(String email, String password) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.person_search, color: _primary),
              SizedBox(width: 10),
              Expanded(child: Text("Account Not Found")),
            ],
          ),
          content: Text(
            "There is no registered account matching '$email'.\n\nWould you like to create a new profile using this password?",
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _executeNewUserRegistration(email, password);
              },
              child: const Text("Yes, Create Account"),
            ),
          ],
        );
      },
    );
  }

  // Sends the registration request to Supabase
  Future<void> _executeNewUserRegistration(
      String email, String password) async {
    setState(() => _isLoading = true);
    try {
      // Use the part of the email before '@' as a starting username
      final String generatedUsername = email.split('@')[0];

      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': generatedUsername,
        },
      );

      _showSnackBar(
          "Account created successfully! Welcome to the project.", Colors.green);

      if (mounted) {
        // Go to ProgressScreen right after successful registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProgressScreen()),
        );
      }
    } on AuthException catch (error) {
      _showSnackBar(error.message, Colors.red);
    } catch (error) {
      _showSnackBar(
          "Registration failed. Please try a stronger password.", Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String text, Color alertColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content:
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: alertColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Shared style for the text fields
  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF5F6FA),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _primaryDark,
        title: const Text(
          "Sign In",
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
            // 📷 Background image (assets/images/l1.webp)
            Positioned.fill(
              child: Image.asset(
                _kLoginBgAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stack) {
                  // If you see this in the console, the image path is wrong
                  debugPrint("Login background failed to load: $error");
                  return const SizedBox.shrink();
                },
              ),
            ),

            // 🌫️ Soft layer that blends the photo into the app palette
            // (lower the numbers to show more of the image)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _bgTop.withOpacity(0.15),
                      _bgTop.withOpacity(0.25),
                      _bgBottom.withOpacity(0.50),
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
              top: 220,
              left: -90,
              child: _DecorCircle(
                  size: 170, color: Colors.purple.withOpacity(0.08)),
            ),
            Positioned(
              bottom: -90,
              right: -50,
              child: _DecorCircle(size: 240, color: _primary.withOpacity(0.10)),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 👤 Header icon
                        Container(
                          padding: const EdgeInsets.all(18),
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
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.lock_open_rounded,
                              size: 52, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Welcome",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF283593),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Log in to save your progress.\nNew here? Just enter your details and we'll help you create an account.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade900,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 🃏 Form card
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withOpacity(0.18),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _fieldDecoration(
                                    label: "Email Address",
                                    icon: Icons.email_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty ||
                                        !value.contains('@')) {
                                      return "Please enter a valid email address.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: _fieldDecoration(
                                    label: "Password",
                                    icon: Icons.lock_outline,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.grey.shade600,
                                      ),
                                      tooltip: _obscurePassword
                                          ? "Show password"
                                          : "Hide password",
                                      onPressed: () => setState(() =>
                                          _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.length < 6) {
                                      return "Password must be at least 6 characters long.";
                                    }
                                    return null;
                                  },
                                ),

                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const ForgotPasswordScreen()),
                                      );
                                    },
                                    child: const Text(
                                      "Forgot Password?",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Continue button
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize:
                                        const Size(double.infinity, 54),
                                    backgroundColor: _primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  onPressed:
                                      _isLoading ? null : _processAuthentication,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          "Continue",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Register link
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignupScreen()),
                            );
                          },
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade900,
                                  fontWeight: FontWeight.w500),
                              children: const [
                                TextSpan(text: "Don't have an account? "),
                                TextSpan(
                                  text: "Register here",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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