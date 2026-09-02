import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils.dart' as utils;
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/profile_repository.dart';

/// Everything the user entered at signup, plus the ability to change it:
/// update their name, change their password, or permanently delete their
/// account.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool _loading = true;
  bool _savingProfile = false;
  bool _changingPassword = false;
  bool _deleting = false;
  String? _username;
  String? _profileError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await context.read<ProfileRepository>().fetchProfile();
      if (!mounted) return;
      setState(() {
        _username = profile.username;
        _firstNameController.text = profile.firstName ?? '';
        _lastNameController.text = profile.lastName ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthRepository.friendlyMessage(e))),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_profileFormKey.currentState?.validate() != true) return;
    setState(() {
      _savingProfile = true;
      _profileError = null;
    });
    try {
      await context.read<ProfileRepository>().updateProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _profileError = AuthRepository.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  /// Re-verifies the current password via a real sign-in before allowing
  /// the change, so a few seconds of access to an already-unlocked device
  /// isn't enough on its own to lock the real owner out.
  Future<void> _changePassword() async {
    if (_passwordFormKey.currentState?.validate() != true) return;
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _passwordError = 'Passwords do not match');
      return;
    }
    setState(() {
      _changingPassword = true;
      _passwordError = null;
    });

    final auth = context.read<AuthRepository>();
    try {
      await auth.signIn(
        email: _username ?? '',
        password: _currentPasswordController.text,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _passwordError = 'Current password is incorrect.';
        _changingPassword = false;
      });
      return;
    }

    try {
      await auth.updatePassword(newPassword: _newPasswordController.text);
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _passwordError = AuthRepository.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently deletes your account — your bookshelf, ratings, '
          'and profile. This is final and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await context.read<ProfileRepository>().deleteAccount();
      // No manual navigation needed: deleteAccount() signs out, and the
      // router's onAuthStateChange redirect to /login fires automatically.
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthRepository.friendlyMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    _username ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _profileFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'First name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Last name is required'
                              : null,
                        ),
                        if (_profileError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _profileError!,
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _savingProfile ? null : _saveProfile,
                          child: _savingProfile
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save Changes'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Change Password',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _passwordFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrentPassword,
                          decoration: InputDecoration(
                            labelText: 'Current Password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureCurrentPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _obscureCurrentPassword =
                                    !_obscureCurrentPassword,
                              ),
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Current password is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            helperText:
                                'At least 8 chars, 1 letter, 1 number, 1 special character',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNewPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () =>
                                    _obscureNewPassword = !_obscureNewPassword,
                              ),
                            ),
                          ),
                          validator: utils.validatePassword,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
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
                          validator: (v) => v == null || v.isEmpty
                              ? 'Please confirm your new password'
                              : null,
                        ),
                        if (_passwordError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _passwordError!,
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _changingPassword ? null : _changePassword,
                          child: _changingPassword
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Update Password'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Danger Zone',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.errorRed,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Deleting your account permanently removes your '
                    'bookshelf, ratings, and profile. This cannot be undone.',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                      foregroundColor: AppColors.white,
                    ),
                    icon: _deleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.delete_forever),
                    label: const Text('Delete Account'),
                    onPressed: _deleting ? null : _handleDeleteAccount,
                  ),
                ],
              ),
            ),
    );
  }
}
