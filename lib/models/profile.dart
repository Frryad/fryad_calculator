class Profile {
  int? id;
  String name;
  String description;
  double dollarBalance;
  double dinarBalance;

  Profile({
    this.id,
    required this.name,
    required this.description,
    required this.dollarBalance,
    required this.dinarBalance,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'dollarBalance': dollarBalance,
      'dinarBalance': dinarBalance,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      dollarBalance: map['dollarBalance'],
      dinarBalance: map['dinarBalance'],
    );
  }
}