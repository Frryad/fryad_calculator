class Budget {
  int? id;
  int categoryId;
  double limitAmount;
  double spentAmount; // This is not stored in the database, but calculated on the fly for UI

  Budget({
    this.id,
    required this.categoryId,
    required this.limitAmount,
    this.spentAmount = 0.0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'categoryId': categoryId,
    'limitAmount': limitAmount
  };
  
  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
    id: map['id'],
    categoryId: map['categoryId'],
    limitAmount: map['limitAmount']
  );
}