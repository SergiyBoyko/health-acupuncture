import '../models/json_utils.dart';

/// Запит з історії пошуку.
class SearchEntry {
  const SearchEntry({required this.query, required this.at});

  factory SearchEntry.fromJson(JsonMap json) => SearchEntry(
    query: json['query'] as String,
    at: DateTime.parse(json['at'] as String),
  );

  final String query;
  final DateTime at;

  JsonMap toJson() => {'query': query, 'at': at.toIso8601String()};
}

/// Що саме відкривали.
enum ViewType { point, segment, symptom, term }

/// Запис історії переглядів.
class ViewEntry {
  const ViewEntry({required this.type, required this.id, required this.at});

  factory ViewEntry.fromJson(JsonMap json) => ViewEntry(
    type: ViewType.values.byName(json['type'] as String),
    id: json['id'] as String,
    at: DateTime.parse(json['at'] as String),
  );

  final ViewType type;

  /// Код точки, ідентифікатор сегмента чи симптому, або сам термін словника.
  final String id;
  final DateTime at;

  JsonMap toJson() => {'type': type.name, 'id': id, 'at': at.toIso8601String()};
}

/// Точка в обраному.
class FavoriteEntry {
  const FavoriteEntry({required this.code, required this.at});

  factory FavoriteEntry.fromJson(JsonMap json) => FavoriteEntry(
    code: json['code'] as String,
    at: DateTime.parse(json['at'] as String),
  );

  final String code;
  final DateTime at;

  JsonMap toJson() => {'code': code, 'at': at.toIso8601String()};
}
