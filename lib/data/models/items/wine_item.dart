import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class WineItem {
  WineItem({String? id, required this.name, required this.price})
      : id = id ?? _uuid.v4();

  final String id;
  final String name;
  final double price;

  WineItem copyWith({String? name, double? price}) =>
      WineItem(id: id, name: name ?? this.name, price: price ?? this.price);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WineItem && id == other.id && name == other.name && price == other.price;

  @override
  int get hashCode => Object.hash(id, name, price);
}
