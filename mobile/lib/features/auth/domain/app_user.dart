/// The three roles the backend recognises, matching the `users.role` enum.
enum Role {
  kasir('kasir', 'Kasir'),
  admin('admin', 'Admin'),
  owner('owner', 'Owner');

  const Role(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static Role parse(Object? raw) {
    for (final role in Role.values) {
      if (role.apiValue == raw) {
        return role;
      }
    }
    throw FormatException('Role tidak dikenal: $raw');
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
  });

  final int id;
  final String name;
  final String username;
  final Role role;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      username: json['username'] as String,
      role: Role.parse(json['role']),
    );
  }
}
