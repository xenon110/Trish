class UserProfile {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final List<String> interests;
  final String? goal;
  final String? matter;
  final int age;
  final String location;
  final String? gender;
  final String? hobby;
  final double? latitude;
  final double? longitude;
  final List<String> moments;
  final DateTime? locationUpdatedAt;

  UserProfile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    this.interests = const [],
    this.goal,
    this.matter,
    this.age = 18,
    this.location = 'Unknown',
    this.gender,
    this.hobby,
    this.latitude,
    this.longitude,
    this.moments = const [],
    this.locationUpdatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return UserProfile(id: 'unknown', fullName: 'Unknown User');
    }
    
    List<String> interestsList = [];
    if (json['interests'] != null && json['interests'] is List) {
      interestsList = List<String>.from(json['interests']);
    }
    
    List<String> momentsList = [];
    if (json['moments'] != null && json['moments'] is List) {
      momentsList = List<String>.from(json['moments']);
    }

    return UserProfile(
      id: json['id'] ?? 'unknown',
      fullName: json['full_name'] ?? 'User',
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      interests: interestsList,
      goal: json['goal'],
      matter: json['matter'],
      age: json['age'] ?? 18,
      location: json['location'] ?? 'Unknown',
      gender: json['gender'],
      hobby: json['hobby'],
      moments: momentsList,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      locationUpdatedAt: json['location_updated_at'] != null ? DateTime.parse(json['location_updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'interests': interests,
      'goal': goal,
      'matter': matter,
      'age': age,
      'location': location,
      'gender': gender,
      'hobby': hobby,
      'moments': moments,
      'latitude': latitude,
      'longitude': longitude,
      'location_updated_at': locationUpdatedAt?.toIso8601String(),
    };
  }
}
