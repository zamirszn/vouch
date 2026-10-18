/// A signed-in person's public-facing profile (only readable by themselves).
library;

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    this.email = '',
    this.photoUrl,
    this.phone,
    this.createdAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? phone;
  final DateTime? createdAt;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    final name = (map['displayName'] as String?)?.trim();
    final email = (map['email'] as String?) ?? '';
    return UserProfile(
      uid: uid,
      displayName: (name == null || name.isEmpty)
          ? (email.isEmpty ? 'Friend' : email.split('@').first)
          : name,
      email: email,
      photoUrl: map['photoUrl'] as String?,
      phone: map['phone'] as String?,
      createdAt: _date(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'phone': phone,
        'createdAt': createdAt,
      };

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    String? phone,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      createdAt: createdAt,
    );
  }

  static DateTime? _date(Object? value) {
    if (value is DateTime) return value;
    try {
      final dynamic dynamicValue = value;
      final result = dynamicValue.toDate();
      if (result is DateTime) return result;
    } catch (_) {
      // Not a Timestamp.
    }
    return null;
  }
}

