import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import 'bookshelf_repository.dart' show NotAuthenticatedException;

/// The single gateway for the signed-in user's own profile: reading it,
/// updating the editable fields, and permanently deleting the account.
class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  /// The unique ID of the logged-in user. If somehow nobody is logged in,
  /// we stop immediately with a clear error rather than touching the wrong
  /// (or no) data.
  String get _uid {
    final user = _client.auth.currentUser;
    if (user == null) throw const NotAuthenticatedException();
    return user.id;
  }

  /// Fetches the signed-in user's profile row.
  Future<UserProfile> fetchProfile() async {
    final row = await _client.from('users').select().eq('id', _uid).single();
    return UserProfile.fromRow(row);
  }

  /// Updates the editable profile fields. Email/username isn't editable
  /// here — changing it needs its own confirmation flow.
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
  }) => _client
      .from('users')
      .update({'first_name': firstName.trim(), 'last_name': lastName.trim()})
      .eq('id', _uid);

  /// Permanently deletes the user's account: shelf contents, shelf, profile,
  /// and login. Signs the local session out immediately afterward so the
  /// app's existing sign-out → redirect-to-login flow fires right away,
  /// instead of waiting for the now-orphaned session token to fail later.
  Future<void> deleteAccount() async {
    await _client.rpc('delete_own_account');
    await _client.auth.signOut();
  }
}
