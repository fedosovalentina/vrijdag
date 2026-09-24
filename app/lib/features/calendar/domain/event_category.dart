/// A label the person created for their own events. At most eight.
class EventCategory {
  const EventCategory({
    required this.id,
    required this.name,
    required this.colorIndex,
    required this.patternIndex,
  });

  static const maxCount = 8;

  final String id;
  final String name;
  final int colorIndex;
  final int patternIndex;

  EventCategory copyWith({String? name}) {
    return EventCategory(
      id: id,
      name: name ?? this.name,
      colorIndex: colorIndex,
      patternIndex: patternIndex,
    );
  }
}

class CategoryCatalog {
  const CategoryCatalog(this.items);

  final List<EventCategory> items;

  bool get isFull => items.length >= EventCategory.maxCount;

  /// Adds a label. Returns null when the name is empty or the list is full.
  CategoryCatalog? add({required String id, required String name}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || isFull) {
      return null;
    }
    return CategoryCatalog([
      ...items,
      EventCategory(
        id: id,
        name: trimmed,
        colorIndex: items.length % 4,
        patternIndex: items.length % 4,
      ),
    ]);
  }

  CategoryCatalog rename(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return this;
    }
    return CategoryCatalog([
      for (final item in items)
        if (item.id == id) item.copyWith(name: trimmed) else item,
    ]);
  }

  CategoryCatalog remove(String id) {
    return CategoryCatalog([
      for (final item in items)
        if (item.id != id) item,
    ]);
  }
}
