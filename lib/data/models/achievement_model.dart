class AchievementModel {
  final int? id;
  final String userEmail;
  final String title;
  final String description;
  final String createdAt;

  AchievementModel({
    this.id,
    required this.userEmail,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_email': userEmail,
      'title': title,
      'description': description,
      'created_at': createdAt,
    };
  }

  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'] as int?,
      userEmail: map['user_email'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      createdAt: map['created_at'] as String,
    );
  }
}