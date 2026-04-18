class Allergen {
  const Allergen(this.index, this.name);

  final int index;
  final String name;
}

/// EU Regulation (EU) No 1169/2011 — 14 major allergens.
/// Indices are stable; new allergens are appended if regulations change.
const List<Allergen> euAllergens = [
  Allergen(0, 'Celery'),
  Allergen(1, 'Gluten-containing cereals'),
  Allergen(2, 'Crustaceans'),
  Allergen(3, 'Eggs'),
  Allergen(4, 'Fish'),
  Allergen(5, 'Lupin'),
  Allergen(6, 'Milk'),
  Allergen(7, 'Molluscs'),
  Allergen(8, 'Mustard'),
  Allergen(9, 'Tree nuts'),
  Allergen(10, 'Peanuts'),
  Allergen(11, 'Sesame seeds'),
  Allergen(12, 'Soybeans'),
  Allergen(13, 'Sulphur dioxide / Sulphites'),
];

String allergenName(int index) {
  if (index < 0 || index >= euAllergens.length) return 'Unknown ($index)';
  return euAllergens[index].name;
}
