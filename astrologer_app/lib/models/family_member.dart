class FamilyMember {
  final String id;
  final String userId;
  final String name;
  final String dateOfBirth;
  final String? timeOfBirth;
  final String? birthPlace;
  final String? sunSign;
  final String? relationship;
  final String? createdAt;

  FamilyMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.dateOfBirth,
    this.timeOfBirth,
    this.birthPlace,
    this.sunSign,
    this.relationship,
    this.createdAt,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      timeOfBirth: json['time_of_birth'],
      birthPlace: json['birth_place'],
      sunSign: json['sun_sign'],
      relationship: json['relationship'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'date_of_birth': dateOfBirth,
    'time_of_birth': timeOfBirth,
    'birth_place': birthPlace,
    'relationship': relationship,
  };
}
