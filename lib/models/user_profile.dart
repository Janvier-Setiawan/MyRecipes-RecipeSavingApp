class UserProfile {
  final String userId;
  final String email;
  final String? fullName;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String cookingLevel;
  final String? favoriteCuisine;
  final List<String> dietaryPreferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.userId,
    required this.email,
    this.fullName,
    this.username,
    this.avatarUrl,
    this.bio,
    this.phoneNumber,
    this.dateOfBirth,
    this.cookingLevel = 'beginner',
    this.favoriteCuisine,
    this.dietaryPreferences = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      phoneNumber: json['phone_number'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      cookingLevel: json['cooking_level'] as String? ?? 'beginner',
      favoriteCuisine: json['favorite_cuisine'] as String?,
      dietaryPreferences: json['dietary_preferences'] != null
          ? List<String>.from(json['dietary_preferences'])
          : [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'username': username,
      'avatar_url': avatarUrl,
      'bio': bio,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth?.toIso8601String().split(
        'T',
      )[0], // Date only
      'cooking_level': cookingLevel,
      'favorite_cuisine': favoriteCuisine,
      'dietary_preferences': dietaryPreferences,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? userId,
    String? email,
    String? fullName,
    String? username,
    String? avatarUrl,
    String? bio,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? cookingLevel,
    String? favoriteCuisine,
    List<String>? dietaryPreferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      cookingLevel: cookingLevel ?? this.cookingLevel,
      favoriteCuisine: favoriteCuisine ?? this.favoriteCuisine,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName => fullName ?? username ?? email;

  String get initials {
    if (fullName != null && fullName!.isNotEmpty) {
      final names = fullName!.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      }
      return fullName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }
}
