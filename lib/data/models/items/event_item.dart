import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class EventItem {
  EventItem({String? id, required this.name, this.time, this.price})
      : id = id ?? _uuid.v4();

  static const _absent = Object();

  final String id;
  final String name;
  final String? time;
  final double? price;

  EventItem copyWith({
    String? name,
    Object? time = _absent,
    Object? price = _absent,
  }) => EventItem(
    id: id,
    name: name ?? this.name,
    time: time == _absent ? this.time : time as String?,
    price: price == _absent ? this.price : price as double?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventItem &&
          id == other.id &&
          name == other.name &&
          time == other.time &&
          price == other.price;

  @override
  int get hashCode => Object.hash(id, name, time, price);
}
