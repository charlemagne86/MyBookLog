import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://asqdogadhpwqpeekvxny.supabase.co',
    anonKey: 'sb_publishable_pEhvPEbg84LgQlNm9kfsUg_f-AThaqn',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'My Book Log',
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _statusMessage;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }



  
  // This method attempts to connect to the Supabase database and updates the UI based on the result.

  Future<void> _checkConnection() async {
    setState(() {
      _checking = true;
      _statusMessage = null;
    });
    try {
      final response = await Supabase.instance.client
          .from('randomTableName')
          .select()
          .limit(1);
      setState(() {
        _statusMessage = 'Connection successful!';
        _checking = false;
      });
    } catch (e, stack) {
      setState(() {
        _statusMessage = 'Connection failed.';
        _checking = false;
      });
    }
  }

  //End of check connection method

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(207, 211, 211, 211),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'My Book Log',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'crafted with love',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (_checking)
              const CircularProgressIndicator()
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
