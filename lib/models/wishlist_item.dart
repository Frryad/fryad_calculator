class WishlistItem {
  int? id;
  int profileId;
  String name;
  double price;
  String currency;

  WishlistItem({
    this.id,
    required this.profileId,
    required this.name,
    required this.price,
    required this.currency,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'name': name,
      'price': price,
      'currency': currency,
    };
  }

  factory WishlistItem.fromMap(Map<String, dynamic> map) {
    return WishlistItem(
      id: map['id'],
      profileId: map['profileId'],
      name: map['name'],
      price: map['price'],
      currency: map['currency'],
    );
  }
}