/// Нормалізація тексту й кодів для фільтрів і пошуку.
abstract final class TextNormalizer {
  static final RegExp _separators = RegExp(r'[^a-zа-яіїєґ0-9½]+');
  static final RegExp _spaces = RegExp(r'\s+');

  /// Нижній регістр, `ё` → `е`, пунктуація → пробіли.
  static String text(String value) => value
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(_separators, ' ')
      .trim();

  /// Код точки для порівняння: без пробілів, кирилиця замість латиниці
  /// (`12м` = `12M`, `2в` = `2B`), `1/2` → `½`.
  static String code(String value) => value
      .toLowerCase()
      .replaceAll(_spaces, '')
      .replaceAll(',1/2', '½')
      .replaceAll('1/2', '½')
      .replaceAll('м', 'm')
      .replaceAll('в', 'b')
      .replaceAll('х', 'x')
      .replaceAll('е', 'e')
      .replaceAll('с', 's');
}

final RegExp _codeParts = RegExp(r'^(\D*)(\d*)(.*)$');

/// Природний порядок кодів: спершу числові (`1B, 1M, 2B, … 9M, 10B`),
/// потім буквені (`E, JB8, JB9, JB10, S1, X`).
int comparePointCodes(String a, String b) {
  final ma = _codeParts.firstMatch(a)!;
  final mb = _codeParts.firstMatch(b)!;
  final prefixA = ma.group(1)!;
  final prefixB = mb.group(1)!;
  if (prefixA.isEmpty != prefixB.isEmpty) return prefixA.isEmpty ? -1 : 1;

  final byPrefix = prefixA.compareTo(prefixB);
  if (byPrefix != 0) return byPrefix;

  final numberA = int.tryParse(ma.group(2)!) ?? -1;
  final numberB = int.tryParse(mb.group(2)!) ?? -1;
  if (numberA != numberB) return numberA.compareTo(numberB);

  return ma.group(3)!.compareTo(mb.group(3)!);
}
