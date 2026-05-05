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

  // Builds the MaterialApp, which sets up app-wide configuration and theming
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'My Book Log',
      home: SplashScreen(), // Show splash screen on launch
      debugShowCheckedModeBanner: false,
    );
  }
}


// Splash screen widget that transitions to login after a delay
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  // Creates the mutable state for this widget
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}


// State for SplashScreen, manages splash/login transition
class _SplashScreenState extends State<SplashScreen> {
  // Whether to show the splash screen or the login UI
  bool _showSplash = true;

  // Called when the widget is inserted into the widget tree
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
            // Splash screen content
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
            // Show login screen after splash
            : const LoginScreen(),
      ),
    );
  }
}

// Login screen UI with username, password, sign up, and forgot password
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  // Creates the mutable state for this widget
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for username and password fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Builds the login form UI
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Login title
            const Text(
              'Login',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            // Username input
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Password input with show/hide toggle
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Forgot password link
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
            // Login button
            ElevatedButton(
              onPressed: () {
                // TODO: Implement login logic
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 16),
            // Sign up link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                TextButton(
                  onPressed: () {
                    // Navigate to the sign up page
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SignUpPage()),
                    );
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

// Sign Up Page for new users
class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  // Creates the mutable state for this widget
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  // Controllers for each input field
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorText;
  bool _isSubmitting = false;

  // Validates password for required complexity
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value);
    if (!hasLetter || !hasNumber || !hasSpecial) {
      return 'Password must have at least 1 letter, 1 number, and 1 special character.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  // Handles form submission and sends data to Supabase
  Future<void> _submit() async {
    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });
    if (_formKey.currentState?.validate() != true) {
      setState(() {
        _isSubmitting = false;
      });
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorText = 'Passwords do not match';
        _isSubmitting = false;
      });
      return;
    }
    try {
      // Insert user details into Supabase users table
      final response = await Supabase.instance.client.from('users').insert({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'password': _passwordController.text, // In production, hash passwords!
      });
      if (response.error != null) {
        setState(() {
          _errorText = response.error!.message;
          _isSubmitting = false;
        });
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up successful! Please log in.')),
        );
      }
    } catch (e) {
      setState(() {
        _errorText = 'Sign up failed: $e';
        _isSubmitting = false;
      });
    }
  }

  // Builds the sign up form UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // First name input
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'First name is required' : null,
                ),
                const SizedBox(height: 16),
                // Last name input
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Last name is required' : null,
                ),
                const SizedBox(height: 16),
                // Username input
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Username is required' : null,
                ),
                const SizedBox(height: 16),
                // Password input with validation and show/hide toggle
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    helperText: 'At least 8 chars, 1 letter, 1 number, 1 special character',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                // Confirm password input with show/hide toggle
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please confirm your password' : null,
                ),
                const SizedBox(height: 24),
                // Error message display
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(_errorText!, style: const TextStyle(color: Colors.red)),
                  ),
                // Sign up button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Sign Up'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ...existing code...
