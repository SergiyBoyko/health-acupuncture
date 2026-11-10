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

  @override
  String get segmentSchemas => 'Зведені схеми';

  @override
  String get segmentFilterHint => 'Код або слово';

  @override
  String get clearFilter => 'Очистити фільтр';

  @override
  String get orderLabel => 'Порядок точок';

  @override
  String get orderBook => 'Як у книзі';

  @override
  String get orderCode => 'За кодом';

  @override
  String get noMatchesTitle => 'Нічого не знайдено';

  @override
  String segmentNoMatchesMessage(String query) {
    return 'У цьому розділі немає точок за запитом «$query».';
  }

  @override
  String sourcePages(String pages) {
    return 'стор. $pages';
  }

  @override
  String get pointDescription => 'Опис';

  @override
  String get pointSymptoms => 'Симптоми';

  @override
  String showMoreSymptoms(int count) {
    return 'Ще $count';
  }

  @override
  String get handwrittenNotes => 'Рукописні нотатки власника';

  @override
  String get transcriptionNotes => 'Примітки транскрипції';

  @override
  String figureCounter(int index, int total) {
    return '$index з $total';
  }

  @override
  String get figureOverview => 'зведена схема';

  @override
  String get figureDetail => 'малюнок біля опису';

  @override
  String get previousPoint => 'Попередня точка';

  @override
  String get nextPoint => 'Наступна точка';

  @override
  String get close => 'Закрити';

  @override
  String get pointsOnFigure => 'Точки на малюнку';

  @override
  String get openFullscreen => 'Відкрити на весь екран';

  @override
  String get symptomFilterHint => 'Хвороба або орган';

  @override
  String symptomNoMatchesMessage(String query) {
    return 'У покажчику немає записів за запитом «$query».';
  }

  @override
  String subtermsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count підтеми',
      many: '$count підтем',
      few: '$count підтеми',
      one: '$count підтема',
    );
    return '$_temp0';
  }

  @override
  String jumpToLetter(String letter) {
    return 'Перейти до літери $letter';
  }

  @override
  String get handwrittenEntry => 'Дописано від руки';

  @override
  String get handwrittenEntryMessage =>
      'Цього рядка немає в друкованому покажчику — його дописав власник брошури.';

  @override
  String get legend => 'Позначення';

  @override
  String get legendTitle => 'Позначення в покажчику';

  @override
  String get legendSuffixes =>
      'Літери M і B у кодах (2M, 2B) — частина назви точки. «MB» після числа означає пару: 10MB — це 10M і 10B.';

  @override
  String get somaticPoints => 'Соматичні точки';

  @override
  String get somaticPointsMessage => 'Діють на весь організм.';

  @override
  String get glossary => 'Словник';

  @override
  String get glossaryFilterHint => 'Термін';

  @override
  String glossaryNoMatchesMessage(String query) {
    return 'У словнику немає термінів за запитом «$query».';
  }

  @override
  String get sideLeft => 'ліва сторона';

  @override
  String get sideRight => 'права сторона';

  @override
  String get sideBoth => 'ліва і права сторони';

  @override
  String get pairedPoints => 'парні точки';

  @override
  String get pressTogether => 'Натискати разом';

  @override
  String get alternative => 'або';

  @override
  String get unknownCodeMessage => 'Точки з таким кодом у книзі немає';

  @override
  String get asPrinted => 'У книзі';

  @override
  String get noPointsForSymptom => 'Для цього запису в книзі не вказано точок.';

  @override
  String get search => 'Пошук';

  @override
  String get searchHint => 'Код, симптом або слово';

  @override
  String get clearSearch => 'Очистити запит';

  @override
  String get searchPromptTitle => 'Що шукаємо?';

  @override
  String get searchPromptMessage =>
      'Код точки, наприклад 12M, симптом або слово з опису.';

  @override
  String resultsPoints(int count) {
    return 'Точки · $count';
  }

  @override
  String resultsSymptoms(int count) {
    return 'Симптоми · $count';
  }

  @override
  String resultsGlossary(int count) {
    return 'Словник · $count';
  }

  @override
  String searchNoResultsMessage(String query) {
    return 'За запитом «$query» нічого немає. Спробуйте інше слово або знайдіть симптом у покажчику.';
  }

  @override
  String get openSymptoms => 'Відкрити покажчик симптомів';

  @override
  String get recentSearches => 'Останні запити';

  @override
  String get clear => 'Очистити';

  @override
  String removeSearch(String query) {
    return 'Видалити запит «$query»';
  }

  @override
  String get clearSearchesTitle => 'Очистити останні запити?';

  @override
  String get clearSearchesMessage =>
      'Усі збережені запити буде видалено з цього пристрою.';

  @override
  String get cancel => 'Скасувати';

  @override
  String get addToFavorites => 'Додати в обране';

  @override
  String get removeFromFavorites => 'Прибрати з обраного';

  @override
  String addedToFavorites(String code) {
    return 'Точку $code додано в обране';
  }

  @override
  String removedFromFavorites(String code) {
    return 'Точку $code прибрано з обраного';
  }

  @override
  String get favorites => 'Обране';

  @override
  String get history => 'Історія';

  @override
  String get favoritesEmptyTitle => 'Збережіть першу точку';

  @override
  String get favoritesEmptyMessage =>
      'Торкніться зірочки на сторінці точки — і вона з\'явиться тут.';

  @override
  String get openBody => 'Відкрити частини тіла';

  @override
  String get historyEmptyTitle => 'Історія порожня';

  @override
  String get historyEmptyMessage =>
      'Тут з\'являться точки, розділи й симптоми, які ви відкривали.';

  @override
  String get clearHistory => 'Очистити історію';

  @override
  String get clearHistoryTitle => 'Очистити історію переглядів?';

  @override
  String get clearHistoryMessage =>
      'Список відкритих точок і розділів буде видалено з цього пристрою. Обране залишиться.';

  @override
  String get today => 'Сьогодні';

  @override
  String get yesterday => 'Вчора';

  @override
  String get earlier => 'Раніше';

  @override
  String get historyTypeSegment => 'Частина тіла';

  @override
  String get historyTypeSymptom => 'Симптом';

  @override
  String get historyTypeTerm => 'Термін словника';

  @override
  String get recentViews => 'Нещодавні';

  @override
  String get showAll => 'Усі';

  @override
  String termsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count терміна',
      many: '$count термінів',
      few: '$count терміни',
      one: '$count термін',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Налаштування';

  @override
  String get theme => 'Тема';

  @override
  String get themeSystem => 'Як у системі';

  @override
  String get themeLight => 'Світла';

  @override
  String get themeDark => 'Темна';

  @override
  String get aboutSource => 'Про джерело і застереження';

  @override
  String get aboutTitle => 'Про джерело';

  @override
  String get disclaimerTitle => 'Перш ніж почати';

  @override
  String get disclaimerHeading => 'Застереження';

  @override
  String get disclaimerSource =>
      'Цей застосунок відтворює текст і малюнки брошури про точки надавлювання, виданої 1992 року. Він показує матеріал джерела як є і нічого не додає від себе.';

  @override
  String get disclaimerNotAdvice =>
      'Це не медична порада. Описані методи не перевірені сучасною медициною і не замінюють звернення до лікаря.';

  @override
  String get disclaimerEmergency =>
      'Якщо у вас гострий біль, травма або стан, що загрожує життю, зверніться по медичну допомогу.';

  @override
  String get disclaimerAccept => 'Я прочитав(ла), продовжити';

  @override
  String get sourceHeading => 'Джерело';

  @override
  String get sourceTranscription =>
      'Текст транскрибовано вручну зі скану, тож можливі помилки. Біля кожної точки вказано сторінку джерела, щоб можна було звіритись.';

  @override
  String sourceContents(String points, String symptoms, String terms) {
    return 'У довіднику: $points, $symptoms, $terms.';
  }

  @override
  String symptomEntriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count запису покажчика',
      many: '$count записів покажчика',
      few: '$count записи покажчика',
      one: '$count запис покажчика',
    );
    return '$_temp0';
  }

  @override
  String get privacyHeading => 'Приватність';

  @override
  String get privacyMessage =>
      'Історія пошуку, історія переглядів і обране зберігаються лише на цьому пристрої. Застосунок працює без мережі й не збирає жодних даних.';
}
