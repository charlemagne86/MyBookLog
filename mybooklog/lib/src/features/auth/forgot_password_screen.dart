import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils.dart';
import '../../data/repositories/auth_repository.dart';

/// BUSINESS LOGIC:
/// The "Forgot password" screen. A user who cannot log in proves they own
/// their account by receiving a 6-digit code at their email address and
/// typing it back in, then chooses a new password — all inside the app, with
/// no fiddly email links to tap. When the reset succeeds they are signed in
/// and taken straight to their bookshelf; they proved they own the mailbox,
/// so making them log in again would be pure friction.
///
/// The screen has two stages:
///   1. "Which email?" — one field and a Send Code button.
///   2. "Code + new password" — the code from the email, plus the new
///      password typed twice, all submitted together.
///
/// Privacy rule: after Send Code we show the SAME message whether or not an
/// account exists for that email ("If an account exists ... we've sent a
/// code"). This stops strangers using the form to discover which emails have
/// accounts.
///
/// TECHNICAL:
/// Stage 2 collects everything in one form because verifying the code signs
/// the user in mid-flow (see AuthRepository.verifyRecoveryCode). Collecting
/// code and password together means one submit finishes the whole job, so
/// the user can never end up signed in but stranded without a new password.
/// If the password save fails AFTER the code was accepted (e.g. a network
/// blip between the two calls), we remember that with [_codeVerified] and
/// retry only the password save — the code is single-use and would be
/// rejected if sent again.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  /// Email carried over from the login screen so the user need not retype it.
  final String? initialEmail;

  /// How long the Resend Code link stays disabled after sending a code.
  /// Matches the server's own limit (one email per 60 seconds), shown as a
  /// visible countdown instead of a silent, confusing failure.
  static const resendCooldown = Duration(seconds: 60);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Which of the two stages is showing: false = "enter email",
  // true = "enter code + new password".
  bool _codeSent = false;
  // True once the server has accepted the 6-digit code. If the password save
  // then fails, the retry skips re-verifying (the code is already used up).
  bool _codeVerified = false;
  // Whether the password boxes currently hide their contents as dots.
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  // True while waiting for the server, so buttons show a spinner and ignore
  // repeat taps (same pattern as the login screen).
  bool _isSubmitting = false;
  // The error message currently on display, or null when there is none.
  String? _errorText;
  // Seconds left before Resend Code may be tapped again; 0 means available.
  int _resendSecondsLeft = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail ?? '';
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Starts (or restarts) the visible 60-second countdown on Resend Code.
  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(
      () => _resendSecondsLeft = ForgotPasswordScreen.resendCooldown.inSeconds,
    );
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _resendSecondsLeft -= 1;
        if (_resendSecondsLeft <= 0) timer.cancel();
      });
    });
  }

  /// Stage 1 submit (also used by Resend Code): ask the server to email a
  /// 6-digit reset code, then advance to stage 2. The confirmation message
  /// never reveals whether the email actually has an account.
  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorText = 'Please enter your email address.');
      return;
    }
    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });
    try {
      await context.read<AuthRepository>().requestPasswordReset(email: email);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _isSubmitting = false;
      });
      _startResendCooldown();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = AuthRepository.friendlyMessage(e);
          _isSubmitting = false;
        });
      }
    }
  }

  /// Stage 2 submit: check the typed code with the server, then save the new
  /// password. Two server calls, one button press.
  Future<void> _resetPassword() async {
    // Client-side checks first, so obvious mistakes never cost a server call.
    if (_formKey.currentState?.validate() != true) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorText = 'Passwords do not match');
      return;
    }
    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });
    final auth = context.read<AuthRepository>();
    try {
      // Skip re-verifying if a previous attempt already used up the code —
      // only the password save is outstanding then.
      if (!_codeVerified) {
        await auth.verifyRecoveryCode(
          email: _emailController.text,
          code: _codeController.text,
        );
        _codeVerified = true;
      }
      await auth.updatePassword(newPassword: _passwordController.text);
      if (!mounted) return;
      // Success: the user now has a session and a new password. Tell them,
      // and go to the shelf — the same destination a normal login reaches.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your password has been updated.')),
      );
      context.go('/shelf');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = AuthRepository.friendlyMessage(e);
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      // The back arrow returns to the login screen; nothing here is lost by
      // leaving, because a fresh code can always be requested.
      appBar: AppBar(title: const Text('Forgot password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  // The explanation swaps with the stage: first "we'll email
                  // you a code", then the deliberately vague "if an account
                  // exists" confirmation (see privacy rule in class comment).
                  Text(
                    _codeSent
                        ? "If an account exists for that email, we've sent a "
                              '6-digit code. It expires in 1 hour.'
                        : "Enter your account's email address and we'll send "
                              'you a 6-digit code to reset your password.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    enabled: !_codeSent,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  if (_codeSent) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      // Codes are digits only; block anything else at the
                      // keyboard level to prevent typos.
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: '6-digit code',
                        counterText: '',
                      ),
                      validator: (v) => (v == null || v.length != 6)
                          ? 'Enter the 6-digit code from the email.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        helperText:
                            'At least 8 chars, 1 letter, 1 number, 1 special character',
                        helperMaxLines: 2,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      // The same strength rules as signup — one standard.
                      validator: validatePassword,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm new password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Please confirm your new password'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : (_codeSent ? _resetPassword : _sendCode),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _codeSent ? 'Reset password' : 'Send code',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  if (_codeSent) ...[
                    const SizedBox(height: 16),
                    // Resend link with visible countdown. Disabled while the
                    // server would refuse anyway (one email per 60 seconds),
                    // so the user sees why instead of a silent failure.
                    Center(
                      child: TextButton(
                        onPressed: (_resendSecondsLeft > 0 || _isSubmitting)
                            ? null
                            : _sendCode,
                        child: Text(
                          _resendSecondsLeft > 0
                              ? 'Resend code (${_resendSecondsLeft}s)'
                              : 'Resend code',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
