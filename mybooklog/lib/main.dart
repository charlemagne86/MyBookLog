import 'dart:convert'; // For utf8.encode (used in password hashing)
import 'package:crypto/crypto.dart'; // For sha256 (used in password hashing)
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase client for backend/auth
import 'package:flutter/material.dart'; // Flutter UI framework


/// Entry point of the Flutter application
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


/// Root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Builds the MaterialApp, which sets up app-wide configuration and theming
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'My Book Log',
      home: SplashScreen(), // Show splash screen on launch
      debugShowCheckedModeBanner: false,
    );
  }
}


/// Splash screen widget that transitions to login after a delay
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Creates the mutable state for this widget
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// State for SplashScreen, manages splash/login transition
class _SplashScreenState extends State<SplashScreen> {
  // Whether to show the splash screen or the login UI
  bool _showSplash = true;

  /// Called when the widget is inserted into the widget tree
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

  /// Builds the splash screen or login UI
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
                  CircularProgressIndicator(strokeWidth: 2, color: Color.fromARGB(255, 80, 110, 241)),
                ],
              )
            // Show login screen after splash
            : const LoginScreen(),
      ),
    );
  }
}


/// Login screen UI with username, password, sign up, and forgot password
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  /// Creates the mutable state for this widget
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// State for LoginScreen, manages login logic and UI
class _LoginScreenState extends State<LoginScreen> {
  String? _errorText; // Error message to display
  bool _isSubmitting = false; // Whether a login request is in progress
  // Controllers for username and password fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true; // Controls password visibility

  /// Handles user login using Supabase Auth
  Future<void> _login() async {
    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      final session = response.session;
      if (session == null) {
        setState(() {
          _errorText = 'Login failed: Invalid credentials or user not found.';
          _isSubmitting = false;
        });
        return;
      }
        // On successful login, create bookshelf if not exists, then navigate
        final userId = response.user?.id;
        if (userId != null) {
          // Create bookshelf for user if not exists
          await Supabase.instance.client.from('bookshelves').upsert({
            'user_id': userId,
          });
        }
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );
        // Navigate to bookshelf screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const BookshelfScreen()),
          );
        }
    } catch (e) {
      setState(() {
        _errorText = 'Login failed: $e';
        _isSubmitting = false;
      });
    }
  }

  /// Builds the login form UI
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
            // Username input (email)
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username (email)',
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
            // Error message display
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(_errorText!, style: const TextStyle(color: Colors.red)),
              ),
            // Forgot password link (not implemented)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Implement forgot password logic


                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Forgot password functionality is not implemented yet.')),
                    );

                    
                },
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 16),
            // Login button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _login,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color.fromARGB(255, 80, 110, 241)),
                    )
                  : const Text('Login'),
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


/// Sign Up Page for new users
class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  /// Creates the mutable state for this widget
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

/// State for SignUpPage, manages registration logic and UI
class _SignUpPageState extends State<SignUpPage> {
  /// Hashes the password using SHA-256 for secure storage
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  // Controllers for each input field
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true; // Controls password visibility
  bool _obscureConfirmPassword = true; // Controls confirm password visibility
  String? _errorText; // Error message to display
  bool _isSubmitting = false; // Whether a sign up request is in progress

  /// Validates password for required complexity
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>\_]').hasMatch(value);
    if (!hasLetter || !hasNumber || !hasSpecial) {
      //print("Password validation failed: hasLetter=$hasLetter, hasNumber=$hasNumber, hasSpecial=$hasSpecial");
      return 'Password must have at least 1 letter, 1 number, and 1 special character.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  /// Handles form submission, creates Supabase Auth user, and inserts user profile
  Future<void> _submit() async {
    // Reset error and set submitting state
    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    // Validate the form fields
    if (_formKey.currentState?.validate() != true) {
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorText = 'Passwords do not match';
        _isSubmitting = false;
      });
      return;
    }

    try {
      // Step 1: Create user in Supabase Auth
      final signUpResponse = await Supabase.instance.client.auth.signUp(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      // Get the created user from the response
      final user = signUpResponse.user;
      if (user == null) {
        // Defensive: This should not happen unless signUp throws
        setState(() {
          _errorText = 'Unable to create user due to database error. Please retry after some time.';
          _isSubmitting = false;
        });
        return;
      }

      // Step 2: Hash the password for secure storage in the profile
      final hashedPassword = _hashPassword(_passwordController.text);

      // Step 3: Insert or update user profile in public.users table
      final profileResponse = await Supabase.instance.client.from('users').upsert({
        'id': user.id, // Use Supabase Auth user UUID for RLS compliance
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'encrypted_password': hashedPassword,
      });

      // Step 4: On success, show a message and redirect to login after 2 seconds
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign up successful! Redirecting...')),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      // Handle Supabase Auth-specific errors
      setState(() {
        _errorText = 'Auth-specific: Sign up failed: ${e.message}';
        _isSubmitting = false;
      });
    } catch (e) {
      // Handle any other errors
      setState(() {
        _errorText = ' Generic: Sign up failed: $e';
        _isSubmitting = false;
      });
    }
  }

  /// Builds the sign up form UI
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
                // Username input (email)
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username (email)',
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
                if (_errorText !=   null)
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color.fromARGB(255, 80, 110, 241)),
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

/// BookshelfScreen: Shows user's bookshelf with 3x5 grid, add/search buttons, and hardwood background
class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({Key? key}) : super(key: key);

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> {
  List<Map<String, dynamic>> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _books = [];
        _loading = false;
      });
      return;
    }
    final response = await Supabase.instance.client
        .from('books')
        .select()
        .eq('user_id', user.id)
        .limit(15);
    setState(() {
      _books = List<Map<String, dynamic>>.from(response);
      _loading = false;
    });
  }

  void _onAddBook() {
    // TODO: Implement add book dialog/screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Book not implemented.')),
    );
  }

  void _onSearchBook() {
    // TODO: Implement search book dialog/screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search Book not implemented.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/hardwood_bookshelf_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_box_rounded, size: 32, color: Color(0xFF7B4A1D)),
                      tooltip: 'Add Book',
                      onPressed: _onAddBook,
                    ),
                    const Text(
                      'My Bookshelf',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B4A1D),
                        shadows: [Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(2,2))],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search_rounded, size: 32, color: Color(0xFF7B4A1D)),
                      tooltip: 'Search Book',
                      onPressed: _onSearchBook,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 32,
                          crossAxisSpacing: 32,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: 15,
                        itemBuilder: (context, index) {
                          if (index >= _books.length) {
                            return const SizedBox();
                          }
                          final book = _books[index];
                          return _BookOnShelf(
                            imageUrl: book['image_url'] as String?,
                            title: book['title'] as String? ?? '',
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget for a single book on the shelf
class _BookOnShelf extends StatelessWidget {
  final String? imageUrl;
  final String title;
  const _BookOnShelf({this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 0.7,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.brown[100],
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(2, 4),
                  ),
                ],
                image: imageUrl != null && imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null || imageUrl!.isEmpty
                  ? const Center(child: Icon(Icons.menu_book, size: 48, color: Color(0xFF7B4A1D)))
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF7B4A1D),
            shadows: [Shadow(blurRadius: 2, color: Colors.black12, offset: Offset(1,1))],
          ),
        ),
      ],
    );
  }
}
