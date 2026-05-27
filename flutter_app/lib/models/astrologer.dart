class Astrologer {
  final String id;
  final String userId;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final int experienceYears;
  final List<String> languages;
  final List<String> specializations;
  final List<String> expertiseAreas;
  final double perMinuteRateChat;
  final double perMinuteRateCall;
  final double perMinuteRateVideo;
  final int totalConsultations;
  final double rating;
  final int reviewCount;
  final bool isOnline;
  final bool isVerified;
  final bool isAvailable;
  final int queueCount;

  Astrologer({
    required this.id,
    required this.userId,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.experienceYears = 0,
    this.languages = const ['English'],
    this.specializations = const [],
    this.expertiseAreas = const [],
    this.perMinuteRateChat = 10,
    this.perMinuteRateCall = 15,
    this.perMinuteRateVideo = 20,
    this.totalConsultations = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.isOnline = false,
    this.isVerified = false,
    this.isAvailable = true,
    this.queueCount = 0,
  });

  factory Astrologer.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    return Astrologer(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      displayName: json['display_name'] ?? json['name'] ?? '',
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      experienceYears: json['experience_years'] ?? 0,
      languages: parseList(json['languages']),
      specializations: parseList(json['specializations']),
      expertiseAreas: parseList(json['expertise_areas']),
      perMinuteRateChat: double.tryParse(json['per_minute_rate_chat']?.toString() ?? '10') ?? 10,
      perMinuteRateCall: double.tryParse(json['per_minute_rate_call']?.toString() ?? '15') ?? 15,
      perMinuteRateVideo: double.tryParse(json['per_minute_rate_video']?.toString() ?? '20') ?? 20,
      totalConsultations: json['total_consultations'] ?? 0,
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      reviewCount: json['review_count'] ?? 0,
      isOnline: json['is_online'] ?? false,
      isVerified: json['is_verified'] ?? false,
      isAvailable: json['is_available'] ?? true,
      queueCount: json['queue_count'] ?? 0,
    );
  }

  String get statusText {
    if (!isAvailable) return 'Busy';
    if (isOnline) return queueCount > 0 ? '$queueCount in queue' : 'Available';
    return 'Offline';
  }

  String get ratingFormatted => rating.toStringAsFixed(1);
  String get experienceText => '$experienceYears yr${experienceYears != 1 ? 's' : ''}';
}

class Review {
  final String id;
  final String userName;
  final int rating;
  final String? reviewText;
  final bool isAnonymous;
  final String createdAt;

  Review({
    required this.id,
    required this.userName,
    required this.rating,
    this.reviewText,
    this.isAnonymous = false,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'] ?? '',
    userName: json['is_anonymous'] == true ? 'Anonymous' : (json['user_name'] ?? 'User'),
    rating: json['rating'] ?? 5,
    reviewText: json['review_text'],
    isAnonymous: json['is_anonymous'] ?? false,
    createdAt: json['created_at'] ?? '',
  );
}

class Consultation {
  final String id;
  final String astrologerId;
  final String? astrologerName;
  final String? astrologerAvatar;
  final String type;
  final String status;
  final int durationSeconds;
  final double totalAmount;
  final double perMinuteRate;
  final String? startedAt;
  final String? endedAt;
  final String createdAt;

  Consultation({
    required this.id,
    required this.astrologerId,
    this.astrologerName,
    this.astrologerAvatar,
    required this.type,
    required this.status,
    this.durationSeconds = 0,
    this.totalAmount = 0,
    required this.perMinuteRate,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) => Consultation(
    id: json['id'] ?? '',
    astrologerId: json['astrologer_id'] ?? '',
    astrologerName: json['astrologer_name'],
    astrologerAvatar: json['astrologer_avatar'],
    type: json['type'] ?? 'chat',
    status: json['status'] ?? 'completed',
    durationSeconds: json['duration_seconds'] ?? 0,
    totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
    perMinuteRate: double.tryParse(json['per_minute_rate']?.toString() ?? '0') ?? 0,
    startedAt: json['started_at'],
    endedAt: json['ended_at'],
    createdAt: json['created_at'] ?? '',
  );

  String get durationFormatted {
    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    return '${mins}m ${secs}s';
  }
}

class WalletData {
  final String id;
  final double balance;
  final String currency;
  final double totalAdded;
  final double totalSpent;

  WalletData({
    required this.id,
    required this.balance,
    this.currency = 'INR',
    this.totalAdded = 0,
    this.totalSpent = 0,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) => WalletData(
    id: json['id'] ?? '',
    balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0,
    currency: json['currency'] ?? 'INR',
    totalAdded: double.tryParse(json['total_added']?.toString() ?? '0') ?? 0,
    totalSpent: double.tryParse(json['total_spent']?.toString() ?? '0') ?? 0,
  );
}

class WalletTransaction {
  final String id;
  final String type;
  final double amount;
  final String description;
  final String status;
  final String createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
    id: json['id'] ?? '',
    type: json['type'] ?? 'debit',
    amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
    description: json['description'] ?? '',
    status: json['status'] ?? 'success',
    createdAt: json['created_at'] ?? '',
  );

  bool get isCredit => type == 'credit' || type == 'cashback' || type == 'bonus' || type == 'refund';
}

class LiveSession {
  final String id;
  final String astrologerId;
  final String astrologerName;
  final String? avatarUrl;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String status;
  final int viewerCount;
  final double totalTips;
  final String? scheduledAt;
  final String? startedAt;

  LiveSession({
    required this.id,
    required this.astrologerId,
    required this.astrologerName,
    this.avatarUrl,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.status,
    this.viewerCount = 0,
    this.totalTips = 0,
    this.scheduledAt,
    this.startedAt,
  });

  factory LiveSession.fromJson(Map<String, dynamic> json) => LiveSession(
    id: json['id'] ?? '',
    astrologerId: json['astrologer_id'] ?? '',
    astrologerName: json['astrologer_name'] ?? '',
    avatarUrl: json['avatar_url'],
    title: json['title'] ?? '',
    description: json['description'],
    thumbnailUrl: json['thumbnail_url'],
    status: json['status'] ?? 'scheduled',
    viewerCount: json['viewer_count'] ?? 0,
    totalTips: double.tryParse(json['total_tips']?.toString() ?? '0') ?? 0,
    scheduledAt: json['scheduled_at'],
    startedAt: json['started_at'],
  );

  bool get isLive => status == 'live';
}

class CommunityPost {
  final String id;
  final String authorName;
  final String? authorSign;
  final String? astrologerName;
  final bool? isVerified;
  final String content;
  final String? mediaUrl;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isPinned;
  final String createdAt;
  final String? category;

  CommunityPost({
    required this.id,
    required this.authorName,
    this.authorSign,
    this.astrologerName,
    this.isVerified,
    required this.content,
    this.mediaUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.isPinned = false,
    required this.createdAt,
    this.category,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
    id: json['id'] ?? '',
    authorName: json['astrologer_name'] ?? json['author_name'] ?? 'User',
    authorSign: json['author_sign'],
    astrologerName: json['astrologer_name'],
    isVerified: json['is_verified'],
    content: json['content'] ?? '',
    mediaUrl: json['media_url'],
    likesCount: json['likes_count'] ?? 0,
    commentsCount: json['comments_count'] ?? 0,
    isLiked: json['is_liked'] ?? false,
    isPinned: json['is_pinned'] ?? false,
    createdAt: json['created_at'] ?? '',
    category: json['category'],
  );
}

class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final int durationDays;
  final int freeMinutes;
  final int discountPercent;
  final List<String> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    this.freeMinutes = 0,
    this.discountPercent = 0,
    this.features = const [],
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) => SubscriptionPlan(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
    durationDays: json['duration_days'] ?? 30,
    freeMinutes: json['free_minutes'] ?? 0,
    discountPercent: json['discount_percent'] ?? 0,
    features: json['features'] is List ? List<String>.from(json['features']) : [],
  );
}

class RechargeOffer {
  final int id;
  final double amount;
  final int bonusPercent;
  final String label;

  RechargeOffer({required this.id, required this.amount, required this.bonusPercent, required this.label});

  double get walletCredit => amount * (1 + bonusPercent / 100);
  double get bonusAmount => walletCredit - amount;

  factory RechargeOffer.fromJson(Map<String, dynamic> json) => RechargeOffer(
    id: json['id'] ?? 0,
    amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
    bonusPercent: json['bonus_percent'] ?? 0,
    label: json['label'] ?? '',
  );
}
