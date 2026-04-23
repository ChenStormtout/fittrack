class GameScoreModel {
  final int? id;
  final String userEmail;
  final String playerName;
  final String gameName;
  final int score;
  final String createdAt;

  GameScoreModel({
    this.id,
    required this.userEmail,
    required this.playerName,
    required this.gameName,
    required this.score,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_email': userEmail,
      'player_name': playerName,
      'game_name': gameName,
      'score': score,
      'created_at': createdAt,
    };
  }

  factory GameScoreModel.fromMap(Map<String, dynamic> map) {
    return GameScoreModel(
      id: map['id'] as int?,
      userEmail: map['user_email'] as String,
      playerName: (map['player_name'] ?? '').toString(),
      gameName: map['game_name'] as String,
      score: map['score'] as int,
      createdAt: map['created_at'] as String,
    );
  }
}