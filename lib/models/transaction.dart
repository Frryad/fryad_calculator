class Transaction {
  int? id;
  int profileId;
  int categoryId;
  String type; // 'expense' or 'income'
  String description;
  double amount;
  String currency; // 'USD' or 'IQD'
  String date;

  Transaction({
    this.id,
    required this.profileId,
    required this.categoryId,
    required this.type,
    required this.description,
    required this.amount,
    required this.currency,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'categoryId': categoryId,
      'type': type,
      'description': description,
      'amount': amount,
      'currency': currency,
      'date': date,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      profileId: map['profileId'],
      categoryId: map['categoryId'],
      type: map['type'],
      description: map['description'],
      amount: map['amount'],
      currency: map['currency'],
      date: map['date'],
    );
  }
}