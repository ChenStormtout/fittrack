class UserModel {
  final int? id;
  final String email;
  final String passwordHash;
  final String salt;
  final String createdAt;

  final String? fullName;
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final String? goal;
  final String? calisthenicsLevel;
  final String? activityLevel;
  final String? profileImage;

  UserModel({
    this.id,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
    this.fullName,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.goal,
    this.calisthenicsLevel,
    this.activityLevel,
    this.profileImage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password_hash': passwordHash,
      'salt': salt,
      'created_at': createdAt,
      'full_name': fullName,
      'age': age,
      'gender': gender,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'goal': goal,
      'calisthenics_level': calisthenicsLevel,
      'activity_level': activityLevel,
      'profile_image': profileImage,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      salt: map['salt'] as String,
      createdAt: map['created_at'] as String,
      fullName: map['full_name'] as String?,
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      goal: map['goal'] as String?,
      calisthenicsLevel: map['calisthenics_level'] as String?,
      activityLevel: map['activity_level'] as String?,
      profileImage: map['profile_image'] as String?,
    );
  }

  UserModel copyWith({
    int? id,
    String? email,
    String? passwordHash,
    String? salt,
    String? createdAt,
    String? fullName,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? goal,
    String? calisthenicsLevel,
    String? activityLevel,
    String? profileImage,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      createdAt: createdAt ?? this.createdAt,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goal: goal ?? this.goal,
      calisthenicsLevel: calisthenicsLevel ?? this.calisthenicsLevel,
      activityLevel: activityLevel ?? this.activityLevel,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}