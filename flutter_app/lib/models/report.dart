class Report {
  final String id;
  final String name;
  final String category;
  final String icon;
  final String? description;
  final List<String> inclusions;
  final double avgRating;
  final int unlockCount;
  final ReportComment? randomComment;

  Report({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    this.description,
    required this.inclusions,
    required this.avgRating,
    required this.unlockCount,
    this.randomComment,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      icon: json['icon'] ?? '📄',
      description: json['description'],
      inclusions: json['inclusions'] != null ? List<String>.from(json['inclusions']) : [],
      avgRating: double.tryParse(json['avg_rating']?.toString() ?? '') ?? 4.5,
      unlockCount: json['unlock_count'] ?? 0,
      randomComment: json['random_comment'] != null ? ReportComment.fromJson(json['random_comment']) : null,
    );
  }
}

class ReportComment {
  final String reviewerName;
  final String reviewText;
  final double rating;

  ReportComment({required this.reviewerName, required this.reviewText, required this.rating});

  factory ReportComment.fromJson(Map<String, dynamic> json) {
    return ReportComment(
      reviewerName: json['reviewer_name'] ?? 'User',
      reviewText: json['review_text'] ?? '',
      rating: (json['rating'] ?? 5).toDouble(),
    );
  }
}

class ReportUnlock {
  final String id;
  final String reportId;
  final String? familyMemberId;
  final String reportName;
  final String icon;
  final String category;
  final String? familyMemberName;
  final String? aiContent;
  final String createdAt;

  ReportUnlock({
    required this.id,
    required this.reportId,
    this.familyMemberId,
    required this.reportName,
    required this.icon,
    required this.category,
    this.familyMemberName,
    this.aiContent,
    required this.createdAt,
  });

  factory ReportUnlock.fromJson(Map<String, dynamic> json) {
    return ReportUnlock(
      id: json['id'] ?? '',
      reportId: json['report_id'] ?? '',
      familyMemberId: json['family_member_id'],
      reportName: json['report_name'] ?? '',
      icon: json['icon'] ?? '📄',
      category: json['category'] ?? '',
      familyMemberName: json['family_member_name'],
      aiContent: json['ai_content'],
      createdAt: json['created_at'] ?? '',
    );
  }

  String get personLabel => familyMemberName ?? 'You';
}

class ReportUnlockStatus {
  final bool isUnlocked;
  final bool freeAvailable;
  final int planCredits;
  final double walletBalance;

  ReportUnlockStatus({
    required this.isUnlocked,
    required this.freeAvailable,
    required this.planCredits,
    required this.walletBalance,
  });

  factory ReportUnlockStatus.fromJson(Map<String, dynamic> json) {
    return ReportUnlockStatus(
      isUnlocked: json['is_unlocked'] ?? false,
      freeAvailable: json['free_available'] ?? false,
      planCredits: json['plan_credits'] ?? 0,
      walletBalance: (json['wallet_balance'] ?? 0).toDouble(),
    );
  }

  bool get canUnlockFree => freeAvailable;
  bool get canUnlockWithCredits => planCredits > 0;
  bool get needsPurchase => !freeAvailable && planCredits == 0;
}

class ReportPlan {
  final String name;
  final String label;
  final int actualPrice;
  final int price;
  final int discount;
  final int credits;

  ReportPlan({
    required this.name,
    required this.label,
    required this.actualPrice,
    required this.price,
    required this.discount,
    required this.credits,
  });

  factory ReportPlan.fromJson(Map<String, dynamic> json) {
    return ReportPlan(
      name: json['name'] ?? '',
      label: json['label'] ?? '',
      actualPrice: json['actualPrice'] ?? 0,
      price: json['price'] ?? 0,
      discount: json['discount'] ?? 0,
      credits: json['credits'] ?? 1,
    );
  }
}
