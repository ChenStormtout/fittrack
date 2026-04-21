class ActivityModel {
  final int? id;
  final String userEmail;
  final String activityType;
  final String startTime;
  final String endTime;
  final int durationSeconds;
  final double distanceKm;
  final double caloriesBurned;
  final String routeJson;
  final String createdAt;

  ActivityModel({
    this.id,
    required this.userEmail,
    required this.activityType,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.distanceKm,
    required this.caloriesBurned,
    required this.routeJson,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_email': userEmail,
      'activity_type': activityType,
      'start_time': startTime,
      'end_time': endTime,
      'duration_seconds': durationSeconds,
      'distance_km': distanceKm,
      'calories_burned': caloriesBurned,
      'route_json': routeJson,
      'created_at': createdAt,
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'] as int?,
      userEmail: map['user_email'] as String,
      activityType: map['activity_type'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      durationSeconds: map['duration_seconds'] as int,
      distanceKm: (map['distance_km'] as num).toDouble(),
      caloriesBurned: (map['calories_burned'] as num).toDouble(),
      routeJson: map['route_json'] as String? ?? '[]',
      createdAt: map['created_at'] as String,
    );
  }
}