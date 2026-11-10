// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Точки надавлювання';

  @override
  String get contentLoading => 'Завантаження довідника';

  @override
  String get contentErrorTitle => 'Не вдалося відкрити довідник';

  @override
  String get contentErrorMessage =>
      'Дані застосунку пошкоджені. Спробуйте ще раз або перевстановіть застосунок.';

  @override
  String get retry => 'Спробувати ще';

  @override
  String pointsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count точки',
      many: '$count точок',
      few: '$count точки',
      one: '$count точка',
    );
    return '$_temp0';
  }

  @override
  String pointSemantics(String code) {
    return 'Точка $code';
  }

  @override
  String unknownPointSemantics(String code) {
    return 'Код $code: такої точки в книзі немає';
  }

  @override
  String get somatic => 'Соматична';

  @override
  String get inFavorites => 'В обраному';

  @override
  String get imageUnavailable => 'Малюнок недоступний';

  @override
  String get tabHome => 'Головна';

  @override
  String get tabBody => 'Тіло';

  @override
  String get tabSymptoms => 'Симптоми';

  @override
  String get tabSaved => 'Збережене';

  @override
  String get bodyTitle => 'Частини тіла';

  @override
  String get notFoundTitle => 'Сторінку не знайдено';

  @override
  String get notFoundMessage => 'Такої точки або розділу в довіднику немає.';

  @override
  String get goHome => 'На головну';

  @override
  String get sectionInProgress => 'Розділ ще в роботі';

  @override
  String get relatedPoints => 'Пов\'язані точки';

  @override
  String sourcePage(int page) {
    return 'стор. $page';
  }
}
