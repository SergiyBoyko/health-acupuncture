/// Допоміжні функції для суворого розбору JSON.
typedef JsonMap = Map<String, dynamic>;

List<String> stringList(Object? value) =>
    (value as List<dynamic>? ?? const <dynamic>[]).cast<String>();

List<T> objectList<T>(Object? value, T Function(JsonMap json) fromJson) =>
    (value as List<dynamic>? ?? const <dynamic>[])
        .map((item) => fromJson(item as JsonMap))
        .toList(growable: false);
