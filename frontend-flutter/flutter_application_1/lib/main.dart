import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'home.dart'; 
import 'update_password_screen.dart'; // ✅ Imported your new password change form screen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env
  await dotenv.load(fileName: ".env");

  // Initialize Supabase using .env values
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

// ✅ Converted to StatefulWidget to handle deep link stream event listeners safely
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // ✅ Added a global navigator key to push screens without needing a local context
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupPasswordRecoveryListener();
  }

  // ✅ Listens for the exact millisecond the user clicks the link inside their Gmail inbox
  void _setupPasswordRecoveryListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      
      // If the app is launched or resumed because of a password reset link click
      if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint("Password recovery deep link click detected!");
        
        // Automatically route them straight to your update screen layout
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const UpdatePasswordScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey, // 👈 CRITICAL: Attach this key so deep-links can launch screens from anywhere
      debugShowCheckedModeBanner: false,
      title: 'Emotion Recognition App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Modern visual components
      ),
      home: const HomePage(), // starting screen stays exactly the same
    );
  }
}
