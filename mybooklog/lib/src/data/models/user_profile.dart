/// The signed-in user's own profile: name and the email they log in with.
class UserProfile {
  final String id;
  final String username;
  final String? firstName;
  final String? lastName;

  const UserProfile({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
  });

  /// Builds a UserProfile from one raw row of the `users` table.
  static UserProfile fromRow(Map<String, dynamic> row) => UserProfile(
    id: row['id'].toString(),
    username: (row['username'] as String?) ?? '',
    firstName: row['first_name'] as String?,
    lastName: row['last_name'] as String?,
  );

  /// "First Last", falling back to whichever name is present, then to the
  /// username, so a display spot never shows blank text.
  String get displayName {
    final full = [
      firstName,
      lastName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');
    return full.isNotEmpty ? full : username;
  }

  UserProfile copyWith({String? firstName, String? lastName}) => UserProfile(
    id: id,
    username: username,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
  );
}
