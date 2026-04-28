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
  final DateTime? lastActiveAt;
  
  // New fields for detailed profile
  final DateTime? birthday;
  final String? interestedIn;
  final int? minAgePreference;
  final int? maxAgePreference;
  final double? distancePreference;
  final String? job;
  final String? education;
  final Map<String, dynamic>? lifestyle; // drinking, smoking, fitness
  final String? religion;
  final String? relationshipType;
  final List<Map<String, dynamic>>? prompts;
  final Map<String, String>? socialLinks;
  final bool isVerified;
  final double? height;
  final List<String> languages;
  final String? zodiac;
  final String? futurePlans;
  final String? hometown;
  final String? exercise;
  final String? drinking;
  final String? smoking;
  final String? wantKids;
  final String? haveKids;
  final String? politics;
  final String? phoneNumber;
  final bool isBlocked;
  final bool prefShowOnline;

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
    this.lastActiveAt,
    this.birthday,
    this.interestedIn,
    this.minAgePreference,
    this.maxAgePreference,
    this.distancePreference,
    this.job,
    this.education,
    this.lifestyle,
    this.religion,
    this.relationshipType,
    this.prompts,
    this.socialLinks,
    this.isVerified = false,
    this.height,
    this.languages = const [],
    this.zodiac,
    this.futurePlans,
    this.hometown,
    this.exercise,
    this.drinking,
    this.smoking,
    this.wantKids,
    this.haveKids,
    this.politics,
    this.phoneNumber,
    this.isBlocked = false,
    this.prefShowOnline = true,
  });

  bool get isOnline {
    if (lastActiveAt == null || !prefShowOnline) return false;
    return DateTime.now().toUtc().difference(lastActiveAt!.toUtc()).inMinutes < 15;
  }

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

    List<Map<String, dynamic>> promptsList = [];
    if (json['prompts'] != null && json['prompts'] is List) {
      promptsList = List<Map<String, dynamic>>.from(json['prompts']);
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
      lastActiveAt: json['last_active_at'] != null ? DateTime.parse(json['last_active_at']) : null,
      birthday: json['birthday'] != null ? DateTime.parse(json['birthday']) : null,
      interestedIn: json['interested_in'],
      minAgePreference: json['min_age_preference'],
      maxAgePreference: json['max_age_preference'],
      distancePreference: json['distance_preference'] != null ? (json['distance_preference'] as num).toDouble() : null,
      job: json['job'],
      education: json['education'],
      lifestyle: json['lifestyle'],
      religion: json['religion'],
      relationshipType: json['relationship_type'],
      prompts: promptsList,
      socialLinks: json['social_links'] != null ? Map<String, String>.from(json['social_links']) : null,
      isVerified: json['is_verified'] ?? false,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      languages: json['languages'] != null ? List<String>.from(json['languages']) : [],
      zodiac: json['zodiac'],
      futurePlans: json['future_plans'],
      hometown: json['hometown'],
      exercise: json['exercise'],
      drinking: json['drinking'],
      smoking: json['smoking'],
      wantKids: json['want_kids'],
      haveKids: json['have_kids'],
      politics: json['politics'],
      phoneNumber: json['phone_number'],
      isBlocked: json['is_blocked'] ?? false,
      prefShowOnline: json['pref_show_online'] ?? true,
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
      'birthday': birthday?.toIso8601String(),
      'interested_in': interestedIn,
      'min_age_preference': minAgePreference,
      'max_age_preference': maxAgePreference,
      'distance_preference': distancePreference,
      'job': job,
      'education': education,
      'lifestyle': lifestyle,
      'religion': religion,
      'relationship_type': relationshipType,
      'prompts': prompts,
      'social_links': socialLinks,
      'is_verified': isVerified,
      'height': height,
      'languages': languages,
      'zodiac': zodiac,
      'future_plans': futurePlans,
      'hometown': hometown,
      'exercise': exercise,
      'drinking': drinking,
      'smoking': smoking,
      'want_kids': wantKids,
      'have_kids': haveKids,
      'politics': politics,
      'phone_number': phoneNumber,
      'is_blocked': isBlocked,
      'pref_show_online': prefShowOnline,
    };
  }
}
