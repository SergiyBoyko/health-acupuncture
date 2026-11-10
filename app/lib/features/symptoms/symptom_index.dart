import '../../data/content_repository.dart';
import '../../data/models/symptom.dart';
import '../../data/text_normalizer.dart';

/// Рядок списку симптомів: окремий симптом або група з підтермінами.
class SymptomEntry {
  const SymptomEntry.symptom(Symptom this.symptom, {this.groupTitle})
    : group = null,
      subtermCount = 0;

  const SymptomEntry.group(SymptomGroup this.group, this.subtermCount)
    : symptom = null,
      groupTitle = null;

  final Symptom? symptom;
  final SymptomGroup? group;
  final int subtermCount;

  /// Назва групи для підтерміна, показаного поза групою (у фільтрі).
  final String? groupTitle;

  bool get isGroup => group != null;

  String get title {
    if (group != null) return group!.title;
    final term = _capitalized(symptom!.term);
    return groupTitle == null ? term : '$groupTitle: ${symptom!.term}';
  }

  String get sortKey => TextNormalizer.text(title);

  /// Літера розділу: перша літера назви, для цифр — `#`.
  String get letter {
    final key = sortKey;
    if (key.isEmpty) return '#';
    final first = key[0];
    return RegExp(r'[0-9]').hasMatch(first) ? '#' : first.toUpperCase();
  }

  static String _capitalized(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

int _byTitle(SymptomEntry a, SymptomEntry b) => a.sortKey.compareTo(b.sortKey);

/// Верхній рівень покажчика за алфавітом: симптоми без груп і самі групи.
List<SymptomEntry> topLevelEntries(ContentRepository repository) => [
  for (final symptom in repository.topLevelSymptoms)
    SymptomEntry.symptom(symptom),
  for (final group in repository.symptomGroups)
    SymptomEntry.group(group, repository.symptomsOfGroup(group.id).length),
]..sort(_byTitle);

/// Підтерміни групи за алфавітом.
List<SymptomEntry> groupEntries(ContentRepository repository, String groupId) =>
    [
      for (final symptom in repository.symptomsOfGroup(groupId))
        SymptomEntry.symptom(symptom),
    ]..sort(_byTitle);

/// Пошук по всьому покажчику, включно з підтермінами груп.
List<SymptomEntry> filterEntries(ContentRepository repository, String query) {
  final needle = TextNormalizer.text(query);
  if (needle.isEmpty) return topLevelEntries(repository);
  return [
    for (final symptom in repository.symptoms)
      SymptomEntry.symptom(
        symptom,
        groupTitle: symptom.groupId == null
            ? null
            : repository.symptomGroup(symptom.groupId!)?.title,
      ),
    for (final group in repository.symptomGroups)
      SymptomEntry.group(group, repository.symptomsOfGroup(group.id).length),
  ].where((entry) => entry.sortKey.contains(needle)).toList()..sort(_byTitle);
}
