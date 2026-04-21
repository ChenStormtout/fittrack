class WaterLogModel {
  final int? id;
  final String userEmail;
  final int amountMl;
  final String selectedDate;
  final String createdAt;

  WaterLogModel({
    this.id,
    required this.userEmail,
    required this.amountMl,
    required this.selectedDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_email': userEmail,
      'amount_ml': amountMl,
      'selected_date': selectedDate,
      'created_at': createdAt,
    };
  }

  factory WaterLogModel.fromMap(Map<String, dynamic> map) {
    return WaterLogModel(
      id: map['id'] as int?,
      userEmail: map['user_email'] as String,
      amountMl: map['amount_ml'] as int,
      selectedDate: map['selected_date'] as String,
      createdAt: map['created_at'] as String,
    );
  }
}