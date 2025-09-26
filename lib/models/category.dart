import 'package:flutter/material.dart';

class Category {
  int? id;
  String name;
  int iconCodePoint; // Store the code point for a Material Icon
  int colorValue;    // Store the integer value of a color

  Category({
    this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
  });
  
  // Helper getters to convert stored values back to Flutter types
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'iconCodePoint': iconCodePoint,
    'colorValue': colorValue
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'],
    name: map['name'],
    iconCodePoint: map['iconCodePoint'],
    colorValue: map['colorValue']
  );
}