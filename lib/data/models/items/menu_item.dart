import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class MenuItem {
  MenuItem({
    String? id,
    required this.name,
    this.description = '',
    required this.price,
    this.allergens = const [],
  }) : id = id ?? _uuid.v4();

  final String id;
  final String name;
  final String description;
  final double price;
  final List<int> allergens;

  MenuItem copyWith({
    String? name,
    String? description,
    double? price,
    List<int>? allergens,
  }) => MenuItem(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    price: price ?? this.price,
    allergens: allergens ?? this.allergens,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItem &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          price == other.price &&
          listEquals(allergens, other.allergens);

  @override
  int get hashCode =>
      Object.hash(id, name, description, price, Object.hashAll(allergens));
}
