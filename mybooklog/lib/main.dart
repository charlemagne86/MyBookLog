// Dart imports for encoding and hashing passwords securely
import 'dart:convert'; // For utf8.encode (used in password hashing)
import 'package:crypto/crypto.dart'; // For sha256 (used in password hashing)

// Supabase and Flutter imports for backend and UI
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase client for backend/auth
import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:flutter/services.dart'; // Haptic feedback for long-press interactions
import 'package:http/http.dart'
    as http; // HTTP client for Google Books API requests
import 'theme/app_theme.dart'; // App light/dark theme definitions
import 'theme/theme_provider.dart'; // Theme mode state management

const String _googleBooksApiKey = 'AIzaSyB4bO6BYBHZgNbV-cTTRTRAeKZV4di5KqI';

/// Entry point of the Flutter application
Future<void> main() async {
  // Ensure Flutter engine is initialized before any async code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with your project URL and anon key for backend/auth
  await Supabase.initialize(
    url: 'https://asqdogadhpwqpeekvxny.supabase.co',
    publishableKey: 'sb_publishable_pEhvPEbg84LgQlNm9kfsUg_f-AThaqn',
  );

  // Start the Flutter app by running the root widget
  runApp(const MyApp());
}

/// Root widget of the application
/// The root widget of the application, sets up theming and home screen
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Centralized theme state holder. This can later be replaced by Provider/Riverpod.
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild MaterialApp whenever theme mode changes.
    return AnimatedBuilder(
      animation: _themeProvider,
      // `child` is unused here since the whole tree rebuilds on theme change.
      builder: (context, child) {
        return MaterialApp(
          title: 'My Book Log',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeProvider.themeMode,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

/// Splash screen widget that transitions to login after a delay
/// SplashScreen widget: shows a splash for 2 seconds, then transitions to login
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Controls whether splash or login is shown
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Show splash for 2 seconds, then show login
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  /// Builds the splash screen or login UI
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: _showSplash
            // Splash screen content: app name, subtitle, and spinner
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'My Book Log',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'crafted with love',
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ],
              )
            // After splash, show login screen
            : const LoginScreen(),
      ),
    );
  }
}

/// Login screen UI with username, password, sign up, and forgot password

/// LoginScreen: Handles user login, error display, and navigation
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Error message to display below form
  String? _errorText;
  // Whether a login request is in progress
  bool _isSubmitting = false;
  // Controllers for username and password fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // Controls password visibility
  bool _obscurePassword = true;

  /// Handles user login using Supabase Auth
  /// On success, creates bookshelf if needed and navigates to BookshelfScreen
  Future<void> _login() async {
    // Reset visible errors and disable repeated taps while the auth request runs.
    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });
    try {
      // Attempt login with Supabase Auth
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      final session = response.session;
      if (session == null) {
        // A missing session means the credentials were not accepted strongly
        // enough to establish a logged-in app state.
        setState(() {
          _errorText = 'Login failed: Invalid credentials or user not found.';
          _isSubmitting = false;
        });
        return;
      }
      // On successful login, create bookshelf for user if not exists
      final userId = response.user?.id;
      if (userId != null) {
        // Upsert ensures every authenticated user has a bookshelf row without
        // creating duplicates on repeated logins.
        await Supabase.instance.client.from('bookshelf').upsert({
          'user_id': userId,
        });
      }
      // After async operations, ensure widget is still mounted before touching state or context
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      // Show login success message and navigate
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login successful!')));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const BookshelfScreen()),
      );
    } catch (e) {
      // Guard setState with mounted check after async failure
      if (mounted) {
        setState(() {
          _errorText = 'Login failed: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  /// Builds the login form UI
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
            // Styling is inherited from InputDecorationTheme to keep
            // shape/typography/colors consistent across all forms.
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username (email)'),
            ),
            const SizedBox(height: 16),
            // Password input with show/hide toggle
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    // Toggle password visibility
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Error message display if login fails
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  _errorText!,
                  style: TextStyle(
                    color: colorScheme.error,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            // Forgot password link (not implemented)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Show not implemented message for forgot password
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Forgot password functionality is not implemented yet.',
                      ),
                    ),
                  );
                },
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 16),
            // Login button, shows spinner if submitting
            ElevatedButton(
              onPressed: _isSubmitting ? null : _login,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            // Sign up link to registration page
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                TextButton(
                  onPressed: () {
                    // Navigate to the sign up page
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SignUpPage(),
                      ),
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
  const SignUpPage({super.key});

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
  final TextEditingController _confirmPasswordController =
      TextEditingController();
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
      // Stop before any backend work if local validation already failed.
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      // Avoid creating an auth user if the confirmation entry is inconsistent.
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
          _errorText =
              'Unable to create user due to database error. Please retry after some time.';
          _isSubmitting = false;
        });
        return;
      }

      // Step 2: Hash the password for the app-specific profile record.
      // Supabase Auth already stores the real password securely for sign-in.
      final hashedPassword = _hashPassword(_passwordController.text);

      // Step 3: Insert or update user profile in public.users table
      await Supabase.instance.client.from('users').upsert({
        'id': user.id, // Use Supabase Auth user UUID for RLS compliance
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'encrypted_password': hashedPassword,
      });

      // Step 4: On success, show a message and redirect to login after 2 seconds
      // Ensure widget is still mounted before using context
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up successful! Redirecting...')),
        );
      }
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      // Handle Supabase Auth-specific errors
      if (mounted) {
        setState(() {
          _errorText = 'Auth-specific: Sign up failed: ${e.message}';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      // Handle any other errors
      if (mounted) {
        setState(() {
          _errorText = ' Generic: Sign up failed: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  /// Builds the sign up form UI
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                  decoration: InputDecoration(labelText: 'First Name'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'First name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                // Last name input
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(labelText: 'Last Name'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Last name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                // Username input (email)
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: 'Username (email)'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Username is required'
                      : null,
                ),
                const SizedBox(height: 16),
                // Password input with validation and show/hide toggle
                // Form fields intentionally inherit InputDecorationTheme to avoid
                // duplicated style values and keep updates centralized.
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText:
                        'At least 8 chars, 1 letter, 1 number, 1 special character',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
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
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please confirm your password'
                      : null,
                ),
                const SizedBox(height: 24),
                // Error message display
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      _errorText!,
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

/// BookshelfScreen: Shows user's bookshelf with 3x5 grid, search/add/logout buttons, and parchment background
class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

/// State for BookshelfScreen
class _BookshelfScreenState extends State<BookshelfScreen> {
  // List of books to display
  List<Map<String, dynamic>> _books = [];
  // Loading state
  bool _loading = true;
  // Controls whether the floating bookshelf search field is visible.
  bool _showSearchBar = false;
  // Tracks the current search text for real-time filtering.
  String _searchQuery = '';
  // Controller for the floating bookshelf search field.
  final TextEditingController _searchController = TextEditingController();

  // Popup actions available from the long-press context menu on a shelf item.
  static const String _menuActionRemove = 'remove';
  static const String _menuActionToggleRead = 'toggle_read';

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Returns the books currently visible in the grid after applying the active
  // search filter rules.
  List<Map<String, dynamic>> get _visibleBooks {
    final query = _searchQuery.trim().toLowerCase();
    if (query.length < 3) {
      // Do not filter until the user has entered enough characters to make
      // the search intentional and reduce noisy partial matches.
      return _books;
    }

    return _books.where((book) {
      final title = (book['title'] as String? ?? '').toLowerCase();
      final author = (book['author'] as String? ?? '').toLowerCase();
      return title.contains(query) || author.contains(query);
    }).toList();
  }

  /// Fetches books for the current user from Supabase
  Future<void> _fetchBooks() async {
    // Every refresh starts by flipping the screen into a loading state.
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // No logged-in user means there is no bookshelf context to query.
      setState(() {
        _books = [];
        _loading = false;
      });
      return;
    }
    try {
      // Fetch bookshelf_items for the user.
      final response = await Supabase.instance.client
          .from('bookshelf_items')
          .select()
          .eq('bookshelf_user_id', user.id);
      //.limit(15);

      final bookshelfItems = List<Map<String, dynamic>>.from(response);
      // bookshelf_items stores shelf membership, not the full display metadata.
      // Collect all referenced catalog ids so we can hydrate the UI in one batch.
      final bookIds = bookshelfItems
          .map((item) => item['book_id'])
          .whereType<dynamic>()
          .toSet()
          .toList();

      final catalogById = <dynamic, Map<String, dynamic>>{};
      if (bookIds.isNotEmpty) {
        // Pull the display fields needed by the grid in a single query rather
        // than making one request per tile.
        final catalogRows = await Supabase.instance.client
            .from('books_catalog')
            .select('id, title, author, thumbnail_uri')
            .inFilter('id', bookIds);

        for (final row in List<Map<String, dynamic>>.from(catalogRows)) {
          catalogById[row['id']] = row;
        }
      }

      // Merge relationship data with catalog data so the widget tree receives a
      // ready-to-render map for each bookshelf cell.
      final enrichedBooks = bookshelfItems.map((item) {
        final catalog = catalogById[item['book_id']];
        return {
          ...item,
          'title': catalog?['title'] as String?,
          'author': catalog?['author'] as String?,
          'thumbnail_uri': catalog?['thumbnail_uri'] as String?,
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _books = enrichedBooks;
        _loading = false;
      });
    } catch (e) {
      // Surface backend failures to the user and end the loading state cleanly.
      if (!mounted) return;
      setState(() {
        _books = [];
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load bookshelf: $e')));
    }
  }

  // Converts mixed backend value types to a stable bool for UI/business logic.
  bool _isBookReadValue(dynamic raw) {
    if (raw == true || raw == 1) return true;
    if (raw is String) return raw.toLowerCase() == 'true';
    return false;
  }

  // Handles long-press on a shelf tile by giving tactile confirmation and then
  // opening a context menu anchored near the pressed position.
  Future<void> _onBookLongPress(
    Map<String, dynamic> book,
    Offset globalPosition,
  ) async {
    await HapticFeedback.mediumImpact();
    if (!mounted) return;

    final selectedAction = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      items: [
        const PopupMenuItem<String>(
          value: _menuActionRemove,
          child: Text(
            'Remove Book',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        PopupMenuItem<String>(
          value: _menuActionToggleRead,
          child: Text(
            _isBookReadValue(book['is_read'])
                ? 'Mark as Unread'
                : 'Mark as Read',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );

    if (selectedAction == null) return;
    if (selectedAction == _menuActionRemove) {
      await _removeBookFromShelf(book);
      return;
    }
    if (selectedAction == _menuActionToggleRead) {
      await _toggleBookReadStatus(book);
    }
  }

  // Removes only the user->book association row from bookshelf_items so the
  // catalog entry can continue to exist for other users/references.
  Future<void> _removeBookFromShelf(Map<String, dynamic> book) async {
    final user = Supabase.instance.client.auth.currentUser;
    final bookId = book['book_id'];
    if (user == null || bookId == null) return;

    try {
      await Supabase.instance.client
          .from('bookshelf_items')
          .delete()
          .eq('bookshelf_user_id', user.id)
          .eq('book_id', bookId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book removed from your bookshelf.')),
      );
      await _fetchBooks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove book: $e')));
    }
  }

  // Flips is_read for the selected shelf row and then refreshes data so the
  // top-left read badge reflects the new state immediately.
  Future<void> _toggleBookReadStatus(Map<String, dynamic> book) async {
    final user = Supabase.instance.client.auth.currentUser;
    final bookId = book['book_id'];
    if (user == null || bookId == null) return;

    final currentlyRead = _isBookReadValue(book['is_read']);
    try {
      await Supabase.instance.client
          .from('bookshelf_items')
          .update({
            'is_read': !currentlyRead,
            'marked_read_on': !currentlyRead
                ? DateTime.now().toIso8601String()
                : null,
          })
          .eq('bookshelf_user_id', user.id)
          .eq('book_id', bookId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentlyRead ? 'Book marked as read.' : 'Book marked as unread.',
          ),
        ),
      );
      await _fetchBooks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update read status: $e')),
      );
    }
  }

  /// Handler for add book button; navigates to add/search book screen
  Future<void> _onAddBook() async {
    // Wait until the add-book flow returns so we can immediately reload the
    // latest shelf contents from the database.
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddBookPage()));

    if (!mounted) return;
    await _fetchBooks();
  }

  /// Handler for search book button
  void _onSearchBook() {
    setState(() {
      // Toggle the floating search bar. Closing it also resets the current
      // query so the bookshelf immediately returns to its full state.
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  /// Handler for logout button - signs out user and returns to login screen
  Future<void> _onLogout() async {
    try {
      // Sign out the current user from Supabase
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      // Navigate back to login screen and replace the navigation stack
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      // Show error if logout fails
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to logout: $e')));
    }
  }

  /// Builds the bookshelf UI
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookshelf'),
        leading: IconButton(
          icon: const Icon(Icons.logout, size: 32),
          tooltip: 'Logout',
          onPressed: _onLogout,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 32),
            tooltip: 'Search Books',
            onPressed: _onSearchBook,
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 32),
            tooltip: 'Add Book',
            onPressed: _onAddBook,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _showSearchBar
                  ? Padding(
                      key: const ValueKey('bookshelf-search-bar'),
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        bottom: 8.0,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Material(
                            elevation: 1,
                            shadowColor: colorScheme.shadow.withAlpha(
                              (0.08 * 255).round(),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).colorScheme.surface,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Search title or author',
                                    helperText: _searchQuery.trim().length < 3
                                        ? 'Enter at least 3 characters!'
                                        : null,
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: _searchQuery.trim().isEmpty
                                        ? null
                                        : IconButton(
                                            icon: const Icon(Icons.close),
                                            tooltip: 'Clear search',
                                            onPressed: () {
                                              setState(() {
                                                _searchController.clear();
                                                _searchQuery = '';
                                              });
                                            },
                                          ),
                                    border: const OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                  ),
                                ),
                                if (_searchQuery.trim().length >= 3)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      bottom: 12,
                                    ),
                                    child: Text(
                                      '${_visibleBooks.length} matching ${_visibleBooks.length == 1 ? 'book' : 'books'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('bookshelf-search-hidden'),
                    ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _visibleBooks.isEmpty
                  ? Center(
                      child: Text(
                        'No books match your search.',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 32,
                            crossAxisSpacing: 32,
                            childAspectRatio: 0.48,
                          ),
                      itemCount: _visibleBooks.length,
                      itemBuilder: (context, index) {
                        final book = _visibleBooks[index];
                        final rawIsRead = book['is_read'];
                        final isRead = _isBookReadValue(rawIsRead);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onLongPressStart: (details) {
                            _onBookLongPress(book, details.globalPosition);
                          },
                          child: _BookOnShelf(
                            imageUrl: book['thumbnail_uri'] as String?,
                            title: book['title'] as String? ?? '',
                            isRead: isRead,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AddBookPage: allows the user to search Google Books by title or author
class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  // Controllers for title and author search fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  bool _isSearching = false;
  String? _errorText;

  /// Build a Google Books API query from title and author fields
  String _buildGoogleBooksQuery() {
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final queryParts = <String>[];
    // Only include search clauses for fields the user actually entered.
    if (title.isNotEmpty)
      queryParts.add('intitle:${Uri.encodeQueryComponent(title)}');
    if (author.isNotEmpty)
      queryParts.add('inauthor:${Uri.encodeQueryComponent(author)}');
    return queryParts.isEmpty ? '' : queryParts.join('+');
  }

  /// Performs a search request against the Google Books API and navigates to results page
  Future<void> _searchBooks() async {
    final query = _buildGoogleBooksQuery();
    if (query.isEmpty) {
      // Avoid unnecessary API calls when there is no search input.
      setState(() {
        _errorText = 'Enter a title, an author, or both before searching.';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSearching = true;
    });

    try {
      // Query Google Books for candidate titles the user may want to add.
      final url = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=$query&maxResults=20&key=$_googleBooksApiKey',
      );
      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception(
          'Google Books API returned status ${response.statusCode}',
        );
      }

      final payload = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      final items = payload['items'] as List<dynamic>?;
      final results = <Map<String, dynamic>>[];

      if (items != null) {
        results.addAll(_normalizeGoogleBooksItems(items));
      }

      if (!mounted) return;
      final totalItems = payload['totalItems'] as int?;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(
            results: results,
            searchQuery: query,
            totalItems: totalItems,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = 'Search failed: $e';
          _isSearching = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Book')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Search for a book...',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _authorController,
                decoration: InputDecoration(labelText: 'Author'),
              ),
              const SizedBox(height: 32),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _errorText!,
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              // Constrain button width so it's not full-width and centered
              Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _searchBooks,
                    icon: const Icon(Icons.search_rounded),
                    label: _isSearching
                        ? const Text(
                            'Searching...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : const Text(
                            'Search Books',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Maps Google Books API items into a shape used by the search results list.
List<Map<String, dynamic>> _normalizeGoogleBooksItems(List<dynamic> items) {
  final results = <Map<String, dynamic>>[];
  for (final item in items) {
    final volumeInfo =
        (item as Map<String, dynamic>)['volumeInfo'] as Map<String, dynamic>?;
    if (volumeInfo == null) continue;

    final thumbnails = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    final thumbnail = thumbnails != null
        ? thumbnails['thumbnail'] as String?
        : null;
    final title = volumeInfo['title'] as String? ?? 'No Title';
    final authors =
        (volumeInfo['authors'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final isbnList = volumeInfo['industryIdentifiers'] as List<dynamic>?;
    // Search through the ISBN list, preferring ISBN_13 over ISBN_10.
    final isbnMap = isbnList != null && isbnList.isNotEmpty
        ? isbnList.firstWhere(
            (item) => item['type'] == 'ISBN_13',
            orElse: () => isbnList.firstWhere(
              (item) => item['type'] == 'ISBN_10',
              orElse: () => null,
            ),
          )
        : null;
    final isbn = isbnMap != null ? isbnMap['identifier'] as String? : null;

    results.add({
      'title': title,
      'authors': authors,
      'thumbnail': thumbnail ?? '',
      'isbn': isbn,
    });
  }
  return results;
}

/// SearchResultsPage displays a list of books returned by GoogleBooks API
/// Allows users to select and add books to their bookshelf
class SearchResultsPage extends StatefulWidget {
  final List<Map<String, dynamic>> results;
  final String searchQuery;
  final int? totalItems;

  const SearchResultsPage({
    super.key,
    required this.results,
    required this.searchQuery,
    this.totalItems,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  static const int _googlePageSize = 20;

  // Track the index of the currently selected book
  int? _selectedIndex;
  // Track whether an add operation is in progress
  bool _isAdding = false;
  bool _isLoadingMore = false;
  bool _hasMoreResults = true;
  List<Map<String, dynamic>> _results = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _results = List<Map<String, dynamic>>.from(widget.results);
    _hasMoreResults = _hasExpectedMoreResults;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  int get _nextStartIndex => _results.length;

  bool get _hasExpectedMoreResults {
    if (widget.totalItems != null) {
      return _results.length < widget.totalItems!;
    }
    return _results.length >= _googlePageSize;
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMoreResults)
      return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 500) {
      _loadMoreResults();
    }
  }

  Future<void> _loadMoreResults() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final url = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=${widget.searchQuery}&startIndex=$_nextStartIndex&maxResults=$_googlePageSize&key=$_googleBooksApiKey',
      );
      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception(
          'Google Books API returned status ${response.statusCode}',
        );
      }

      final payload = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      final items = payload['items'] as List<dynamic>?;
      final fetchedResults = items == null
          ? <Map<String, dynamic>>[]
          : _normalizeGoogleBooksItems(items);

      if (!mounted) return;
      setState(() {
        if (fetchedResults.isNotEmpty) {
          // De-duplicate results across pages by ISBN (or title+authors fallback).
          final existingKeys = _results.map(_bookIdentityKey).toSet();
          for (final result in fetchedResults) {
            final key = _bookIdentityKey(result);
            if (existingKeys.add(key)) {
              _results.add(result);
            }
          }
        }

        final totalItems = payload['totalItems'] as int?;
        final reachedKnownEnd =
            totalItems != null && _results.length >= totalItems;
        final pageReturnedNothing = fetchedResults.isEmpty;
        final pageNotFull = fetchedResults.length < _googlePageSize;
        _hasMoreResults =
            !(reachedKnownEnd || pageReturnedNothing || pageNotFull);
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more results: $e')),
      );
    }
  }

  String _bookIdentityKey(Map<String, dynamic> book) {
    final isbn = (book['isbn'] as String?)?.trim();
    if (isbn != null && isbn.isNotEmpty) {
      return 'isbn:$isbn';
    }

    final title = ((book['title'] as String?) ?? '').trim().toLowerCase();
    final authors = (book['authors'] as List<String>? ?? <String>[])
        .map((author) => author.trim().toLowerCase())
        .where((author) => author.isNotEmpty)
        .join('|');
    return 'fallback:$title::$authors';
  }

  /// Adds the selected book to the user's bookshelf in Supabase
  Future<void> _addSelectedBook() async {
    if (_selectedIndex == null) return;

    // Resolve the selected search result into a data record we can validate and save.
    final selectedBook = _results[_selectedIndex!];
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated. Please log in.'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      // Extract the fields needed by both duplicate detection and database writes.
      final title = selectedBook['title'] as String?;
      final authors = selectedBook['authors'] as List<String>?;
      final isbn = selectedBook['isbn'] as String?;

      // Refuse to persist incomplete catalog rows. ISBN is also the business key
      // used to determine whether a book already exists on a shelf.
      if (title == null || title.isEmpty) {
        throw Exception('Failed to add to bookshelf due to missing Title');
      }
      if (authors == null || authors.isEmpty) {
        throw Exception('Failed to add to bookshelf due to missing Author');
      }
      if (isbn == null || isbn.isEmpty) {
        throw Exception('Failed to add to bookshelf due to missing ISBN');
      }

      // Prevent duplicate books on the current user's shelf by ISBN.
      // First find any catalog rows that represent the same real-world book.
      final existingCatalogRows = await Supabase.instance.client
          .from('books_catalog')
          .select('id')
          .eq('isbn', isbn);

      if (existingCatalogRows.isNotEmpty) {
        final existingBookIds = List<Map<String, dynamic>>.from(
          existingCatalogRows,
        ).map((row) => row['id']).toList();

        // Then check whether this user already has one of those catalog ids on
        // their shelf. If yes, stop before any insert happens.
        final existingShelfRows = await Supabase.instance.client
            .from('bookshelf_items')
            .select('book_id')
            .eq('bookshelf_user_id', user.id)
            .inFilter('book_id', existingBookIds)
            .limit(1);

        if (existingShelfRows.isNotEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This book already exists on your bookshelf.'),
            ),
          );
          setState(() {
            _isAdding = false;
          });
          return;
        }
      }

      final author = authors.join(', ');
      final thumbnail = selectedBook['thumbnail'] as String?;

      // Persist the canonical book metadata first. bookshelf_items will point at
      // this catalog row through book_id.
      final catalogResponse = await Supabase.instance.client
          .from('books_catalog')
          .insert({
            'title': title,
            'author': author,
            'isbn': isbn,
            'thumbnail_uri': thumbnail,
            //'user_id': user.id,
            // id and created_at are auto-generated by the database
          })
          .select();

      if (catalogResponse.isEmpty) {
        throw Exception('Failed to insert book into catalog');
      }

      // Capture the generated catalog id so we can link it to the user's shelf.
      final bookId = catalogResponse[0]['id'];

      // Create the user-to-book relationship record that makes the book appear
      // on this specific user's bookshelf.
      await Supabase.instance.client.from('bookshelf_items').insert({
        'book_id': bookId,
        'bookshelf_user_id': user.id,
        // created_at is auto-generated by the database
      });

      if (!mounted) return;

      // Show success message and navigate back to bookshelf
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book added to your bookshelf!')),
      );

      // Navigate back to the BookshelfScreen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add book: $e')));
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Search Results')),
      // Use a Stack to layer the ListView with the floating action button
      body: Stack(
        children: [
          SafeArea(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      'No results found. Try a different search.',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 16.0,
                      bottom: _selectedIndex != null ? 96.0 : 28.0,
                    ),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final title = item['title'] as String? ?? 'No Title';
                      final authors =
                          item['authors'] as List<String>? ?? <String>[];
                      final thumbnail = item['thumbnail'] as String? ?? '';
                      // Check if this item is currently selected
                      final isSelected = _selectedIndex == index;
                      final textTheme = Theme.of(context).textTheme;

                      return GestureDetector(
                        onTap: () {
                          // Toggle selection for this book
                          setState(() {
                            _selectedIndex = isSelected ? null : index;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            // Selected state uses a subtle semantic tint to preserve readability.
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withAlpha(30),
                                blurRadius: 6,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Keep the cover art in a fixed frame so every row lines up
                                // consistently even when the image aspect ratios vary.
                                if (thumbnail.isNotEmpty)
                                  SizedBox(
                                    width: 120,
                                    height: 180,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        thumbnail,
                                        fit: BoxFit.contain,
                                        alignment: Alignment.center,
                                      ),
                                    ),
                                  )
                                else
                                  SizedBox(
                                    width: 120,
                                    height: 180,
                                    child: Center(
                                      child: Icon(
                                        Icons.menu_book,
                                        size: 90,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 18),
                                // Let the title/author text expand into the remaining space
                                // so the larger thumbnail still feels balanced.
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        title,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        authors.isNotEmpty
                                            ? authors.join(', ')
                                            : 'Unknown author',
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontSize: 15,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Keep the selected-state icon aligned to the same right edge
                                // regardless of whether the row is selected.
                                if (isSelected)
                                  Padding(
                                    padding: EdgeInsets.only(left: 12),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: colorScheme.primary,
                                      size: 32,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    // Add a little extra breathing room between the taller result cards.
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 18),
                    itemCount: _results.length,
                  ),
          ),
          if (_isLoadingMore)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
          // Floating "Add" button that appears when a book is selected
          if (_selectedIndex != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAdding ? null : _addSelectedBook,
                  icon: _isAdding
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(
                    _isAdding ? 'Adding...' : 'Add to Bookshelf',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

/// Widget for a single book on the shelf
class _BookOnShelf extends StatelessWidget {
  /// Book cover image URL
  final String? imageUrl;

  /// Book title
  final String title;

  /// Whether this book is marked as read for the current user.
  final bool isRead;
  const _BookOnShelf({this.imageUrl, required this.title, this.isRead = false});

  /// Builds the book tile UI
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Book cover with book-appropriate aspect ratio (0.67 for tall books)
        AspectRatio(
          aspectRatio: 0.67,
          child: Stack(
            children: [
              // Base layer: thumbnail (or fallback icon) with styling.
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withAlpha((0.10 * 255).round()),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(imageUrl!, fit: BoxFit.contain),
                      )
                    : Center(
                        child: Icon(
                          Icons.menu_book,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
              // Overlay layer: only render the read badge when this shelf item
              // is marked as read for the current user. Unread items intentionally
              // show nothing to keep the grid visually clean.
              if (isRead)
                Positioned(
                  top: 6,
                  left: 6,
                  // Green filled circle with white checkmark per UX spec.
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.onPrimary,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 14,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Book title
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
