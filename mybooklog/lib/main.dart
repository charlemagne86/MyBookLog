
// Import Flutter material design package for UI components
import 'package:flutter/material.dart';
// Import Supabase Flutter package for backend/database connectivity
import 'package:supabase_flutter/supabase_flutter.dart';


// Entry point of the Flutter application
Future<void> main() async {
  // Ensures Flutter engine is initialized before running asynchronous code
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Supabase with project URL and anon key
  await Supabase.initialize(
    url: 'https://asqdogadhpwqpeekvxny.supabase.co',
    anonKey: 'sb_publishable_pEhvPEbg84LgQlNm9kfsUg_f-AThaqn',
  );
  // Start the Flutter app by running MyApp widget
  runApp(const MyApp());
}


// Root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp sets up app-wide configuration and theming
    return const MaterialApp(
      title: 'My Book Log',
      home: SplashScreen(), // Show splash screen on launch
      debugShowCheckedModeBanner: false,
    );
  }
}


// Splash screen widget that checks Supabase connection
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}


// State for SplashScreen, manages connection status
class _SplashScreenState extends State<SplashScreen> {
  // Message to display connection status
  String? _statusMessage;
  // Whether the app is currently checking the connection
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    // Start connection check when splash screen is shown
    _checkConnection();
  }



  

  // Attempts to connect to Supabase and updates the UI with the result
  Future<void> _checkConnection() async {
    setState(() {
      _checking = true;
      _statusMessage = null;
    });
    try {
      // Try to select one row from the 'books' table
      final response = await Supabase.instance.client
          .from('books')
          .select()
          .limit(1);
      setState(() {
        _statusMessage = 'Connection successful!';
        _checking = false;
      });
    } catch (e, stack) {
      // If an error occurs, show failure message
      setState(() {
        _statusMessage = 'Connection failed.';
        _checking = false;
      });
    }
  }

  // Builds the splash screen UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(207, 211, 211, 211),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App title
            const Text(
              'My Book Log',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Subtitle
            const Text(
              'crafted with love',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            // Show loading indicator while checking
            if (_checking)
              const CircularProgressIndicator()
            // Show status message if available
            else if (_statusMessage != null)
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage == 'Connection successful!'
                      ? Colors.green
                      : Colors.red,
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
