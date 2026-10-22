import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 🖼️ BACKGROUND IMAGE for the Sign Up screen (s1.jpg)
const String _kSignupBgAsset = 'assets/images/s1.jpg';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Handles New User Account Creation in Supabase
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
        },
      );

      _showSnackBar(
          "Account created successfully! Welcome to the project.", Colors.green);
      if (mounted) {
        Navigator.pop(context); // Pop back to the Login/Home screen
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
        content:
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: alertColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 🎨 Shared rounded input style with a soft white fill
  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? helper,
    int helperMaxLines = 1,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      helperText: helper,
      helperMaxLines: helperMaxLines,
      filled: true,
      fillColor: Colors.white.withOpacity(0.85),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Create Account",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.blue.shade900,
      ),
      body: Stack(
        children: [
          // 📷 Background image (assets/images/s1.jpg)
          Positioned.fill(
            child: Image.asset(
              _kSignupBgAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stack) {
                // If you see this in the console, the image path is wrong
                debugPrint("Signup background failed to load: $error");
                return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade50, Colors.purple.shade50],
                  ),
                ),
                );
              },
            ),
          ),

          // 🌫️ Soft layer that blends the photo with the app colors
          // (lower the numbers to show more of the image)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.30),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.50),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.8), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.white.withOpacity(0.9),
                            child: const Icon(Icons.person_add_alt_1,
                                size: 52, color: Colors.blue),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Create your profile to save progress tracking and personalized training exercises.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Colors.grey.shade900,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 26),

                        // Username Input Form Field
                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.text,
                          decoration: _fieldDecoration(
                            label: "Username",
                            icon: Icons.account_circle,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter a unique username.";
                            }
                            if (value.trim().length < 3) {
                              return "Username must be at least 3 characters long.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email Address Form Field with Strict Verification
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _fieldDecoration(
                            label: "Email Address",
                            icon: Icons.email,
                            helper: "e.g., example@gmail.com",
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter an email address.";
                            }

                            // Strict RegEx checking structure alignment (.com, .net, etc.)
                            final emailRegex = RegExp(
                                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,}");
                            if (!emailRegex.hasMatch(value.trim())) {
                              return "Invalid email syntax. Watch out for typos like '.con'.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Form Field with strict 8+ length and complexity validation
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: _fieldDecoration(
                            label: "Password",
                            icon: Icons.lock,
                            helper:
                                "Must be 8+ characters with 1 uppercase, 1 lowercase, 1 number, & 1 symbol.",
                            helperMaxLines: 2,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter a password.";
                            }
                            // ✅ Enforces strict minimum length of 8 characters
                            if (value.length < 8) {
                              return "Password must be at least 8 characters long.";
                            }

                            // Regex expressions for each security class requirement
                            final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
                            final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
                            final hasDigits = RegExp(r'[0-9]').hasMatch(value);
                            final hasSpecial =
                                RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);

                            if (!hasUppercase) {
                              return "Password needs at least one uppercase letter.";
                            }
                            if (!hasLowercase) {
                              return "Password needs at least one lowercase letter.";
                            }
                            if (!hasDigits) {
                              return "Password needs at least one number.";
                            }
                            if (!hasSpecial) {
                              return "Password needs at least one special character.";
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Form Field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: _fieldDecoration(
                            label: "Confirm Password",
                            icon: Icons.lock_clock,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please confirm your password.";
                            }
                            if (value != _passwordController.text) {
                              return "Passwords do not match.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 26),

                        // Register Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isLoading ? null : _handleSignUp,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  "Register Account",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                        const SizedBox(height: 12),

                        // Back to Login Switcher
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Go back to Login Screen
                          },
                          child: const Text(
                            "Already have an account? Click here to Sign In",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}