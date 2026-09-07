import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home.dart'; // make sure this file exists in lib/

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://baigajpnijshpnrgvvli.supabase.co', // e.g. https://xyzcompany.supabase.co
    anonKey: 'sb_publishable_fo2cqYl--JtooQv0tEcd5g_rHCYLC68', // from Project Settings → API
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Emotion Recognition App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(), // starting screen
    );
  }
}
