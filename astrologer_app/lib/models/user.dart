class User {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? dateOfBirth;
  final String? timeOfBirth;
  final String? birthPlace;
  final String? sunSign;
  final String? moonSign;
  final String? risingSign;
  final String subscriptionPlan;
  final String? createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.dateOfBirth,
    this.timeOfBirth,
    this.birthPlace,
    this.sunSign,
    this.moonSign,
    this.risingSign,
    this.subscriptionPlan = 'free',
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatar_url'],
      dateOfBirth: json['date_of_birth'],
      timeOfBirth: json['time_of_birth'],
      birthPlace: json['birth_place'],
      sunSign: json['sun_sign'],
      moonSign: json['moon_sign'],
      risingSign: json['rising_sign'],
      subscriptionPlan: json['subscription_plan'] ?? 'free',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'email': email, 'name': name, 'avatar_url': avatarUrl,
    'date_of_birth': dateOfBirth, 'time_of_birth': timeOfBirth,
    'birth_place': birthPlace, 'sun_sign': sunSign, 'moon_sign': moonSign,
    'rising_sign': risingSign, 'subscription_plan': subscriptionPlan,
  };

  bool get isPremium => subscriptionPlan != 'free';

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class Horoscope {
  final String zodiacSign;
  final String periodType;
  final String content;
  final int loveScore;
  final int friendshipScore;
  final int workScore;
  final int? luckyNumber;
  final String? luckyColor;

  Horoscope({
    required this.zodiacSign,
    required this.periodType,
    required this.content,
    required this.loveScore,
    required this.friendshipScore,
    required this.workScore,
    this.luckyNumber,
    this.luckyColor,
  });

  factory Horoscope.fromJson(Map<String, dynamic> json) {
    return Horoscope(
      zodiacSign: json['zodiac_sign'] ?? '',
      periodType: json['period_type'] ?? 'daily',
      content: json['content'] ?? '',
      loveScore: json['love_score'] ?? 75,
      friendshipScore: json['friendship_score'] ?? 75,
      workScore: json['work_score'] ?? 75,
      luckyNumber: json['lucky_number'],
      luckyColor: json['lucky_color'],
    );
  }
}

class AudioContent {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String? thumbnailUrl;
  final String? audioUrl;
  final int? durationSeconds;
  final String? planetTheme;
  final bool isPremium;
  final int playCount;

  AudioContent({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.thumbnailUrl,
    this.audioUrl,
    this.durationSeconds,
    this.planetTheme,
    this.isPremium = false,
    this.playCount = 0,
  });

  factory AudioContent.fromJson(Map<String, dynamic> json) {
    return AudioContent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      audioUrl: json['audio_url'],
      durationSeconds: json['duration_seconds'],
      planetTheme: json['planet_theme'],
      isPremium: json['is_premium'] ?? false,
      playCount: json['play_count'] ?? 0,
    );
  }

  String get formattedDuration {
    if (durationSeconds == null) return '';
    final mins = durationSeconds! ~/ 60;
    return '$mins min';
  }
}

class Course {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final int totalLessons;
  final int? durationMinutes;
  final String difficulty;
  final String? category;
  final bool isPremium;
  final int userCompletedLessons;
  final bool isCompleted;

  Course({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.totalLessons,
    this.durationMinutes,
    required this.difficulty,
    this.category,
    this.isPremium = false,
    this.userCompletedLessons = 0,
    this.isCompleted = false,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      thumbnailUrl: json['thumbnail_url'],
      totalLessons: json['total_lessons'] ?? 0,
      durationMinutes: json['duration_minutes'],
      difficulty: json['difficulty'] ?? 'beginner',
      category: json['category'],
      isPremium: json['is_premium'] ?? false,
      userCompletedLessons: json['user_completed_lessons'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
    );
  }

  double get progress => totalLessons > 0 ? userCompletedLessons / totalLessons : 0;
}

class Transit {
  final String id;
  final String planet;
  final String aspect;
  final String? targetPlanet;
  final String? zodiacSign;
  final String description;
  final String? category;
  final String? intensity;

  Transit({
    required this.id,
    required this.planet,
    required this.aspect,
    this.targetPlanet,
    this.zodiacSign,
    required this.description,
    this.category,
    this.intensity,
  });

  factory Transit.fromJson(Map<String, dynamic> json) {
    return Transit(
      id: json['id'] ?? '',
      planet: json['planet'] ?? '',
      aspect: json['aspect'] ?? '',
      targetPlanet: json['target_planet'],
      zodiacSign: json['zodiac_sign'],
      description: json['description'] ?? '',
      category: json['category'],
      intensity: json['intensity'],
    );
  }

  String get title => targetPlanet != null ? '$planet $aspect $targetPlanet' : '$planet in $zodiacSign';
}
