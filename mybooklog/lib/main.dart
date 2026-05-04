import 'package:flutter/material.dart';
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
  // Whether to show the splash screen or the login UI
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Show splash screen for 2 seconds, then show login UI
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showSplash = false;
      });
    });
  }



  

  // Attempts to connect to Supabase and updates the UI with the result
  // Future<void> _checkConnection() async {
  //   setState(() {
  //     _checking = true;
  //     _statusMessage = null;
  //   });
  //   try {
  //     // Try to select one row from the 'books' table
  //     final response = await Supabase.instance.client
  //         .from('users')
  //         .select()
  //         .limit(1);
  //     setState(() {
  //       _statusMessage = 'Connection successful!';
  //       _checking = false;
  //     });
  //   } catch (e, stack) {
  //     // If an error occurs, show failure message
  //     setState(() {
  //       _statusMessage = 'Connection failed.';
  //       _checking = false;
  //     });
  //   }
  // }

  // Builds the splash screen or login UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(207, 211, 211, 211),
      body: Center(
        child: _showSplash
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'My Book Log',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'crafted with love',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 32),
                  CircularProgressIndicator(),
                ],
              )
            : const LoginScreen(),
      ),
    );
  }
}

// Login screen UI with username, password, sign up, and forgot password
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Login',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.visibility),
                  onPressed: null, // Will be replaced below
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Implement forgot password logic
                },
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement login logic
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                TextButton(
                  onPressed: () {
                    // TODO: Implement sign up logic
                  },
                  child: const Text('Sign up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// ...existing code...
