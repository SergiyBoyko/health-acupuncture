import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('uk')];

  /// No description provided for @appTitle.
  ///
  /// In uk, this message translates to:
  /// **'Точки надавлювання'**
  String get appTitle;

  /// No description provided for @contentLoading.
  ///
  /// In uk, this message translates to:
  /// **'Завантаження довідника'**
  String get contentLoading;

  /// No description provided for @contentErrorTitle.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося відкрити довідник'**
  String get contentErrorTitle;

  /// No description provided for @contentErrorMessage.
  ///
  /// In uk, this message translates to:
  /// **'Дані застосунку пошкоджені. Спробуйте ще раз або перевстановіть застосунок.'**
  String get contentErrorMessage;

  /// No description provided for @retry.
  ///
  /// In uk, this message translates to:
  /// **'Спробувати ще'**
  String get retry;

  /// No description provided for @pointsCount.
  ///
  /// In uk, this message translates to:
  /// **'{count, plural, one{{count} точка} few{{count} точки} many{{count} точок} other{{count} точки}}'**
  String pointsCount(int count);

  /// No description provided for @pointSemantics.
  ///
  /// In uk, this message translates to:
  /// **'Точка {code}'**
  String pointSemantics(String code);

  /// No description provided for @unknownPointSemantics.
  ///
  /// In uk, this message translates to:
  /// **'Код {code}: такої точки в книзі немає'**
  String unknownPointSemantics(String code);

  /// No description provided for @somatic.
  ///
  /// In uk, this message translates to:
  /// **'Соматична'**
  String get somatic;

  /// No description provided for @inFavorites.
  ///
  /// In uk, this message translates to:
  /// **'В обраному'**
  String get inFavorites;

  /// No description provided for @imageUnavailable.
  ///
  /// In uk, this message translates to:
  /// **'Малюнок недоступний'**
  String get imageUnavailable;

  /// No description provided for @tabHome.
  ///
  /// In uk, this message translates to:
  /// **'Головна'**
  String get tabHome;

  /// No description provided for @tabBody.
  ///
  /// In uk, this message translates to:
  /// **'Тіло'**
  String get tabBody;

  /// No description provided for @tabSymptoms.
  ///
  /// In uk, this message translates to:
  /// **'Симптоми'**
  String get tabSymptoms;

  /// No description provided for @tabSaved.
  ///
  /// In uk, this message translates to:
  /// **'Збережене'**
  String get tabSaved;

  /// No description provided for @bodyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Частини тіла'**
  String get bodyTitle;

  /// No description provided for @notFoundTitle.
  ///
  /// In uk, this message translates to:
  /// **'Сторінку не знайдено'**
  String get notFoundTitle;

  /// No description provided for @notFoundMessage.
  ///
  /// In uk, this message translates to:
  /// **'Такої точки або розділу в довіднику немає.'**
  String get notFoundMessage;

  /// No description provided for @goHome.
  ///
  /// In uk, this message translates to:
  /// **'На головну'**
  String get goHome;

  /// No description provided for @sectionInProgress.
  ///
  /// In uk, this message translates to:
  /// **'Розділ ще в роботі'**
  String get sectionInProgress;

  /// No description provided for @relatedPoints.
  ///
  /// In uk, this message translates to:
  /// **'Пов\'язані точки'**
  String get relatedPoints;

  /// No description provided for @sourcePage.
  ///
  /// In uk, this message translates to:
  /// **'стор. {page}'**
  String sourcePage(int page);

  /// No description provided for @segmentSchemas.
  ///
  /// In uk, this message translates to:
  /// **'Зведені схеми'**
  String get segmentSchemas;

  /// No description provided for @segmentFilterHint.
  ///
  /// In uk, this message translates to:
  /// **'Код або слово'**
  String get segmentFilterHint;

  /// No description provided for @clearFilter.
  ///
  /// In uk, this message translates to:
  /// **'Очистити фільтр'**
  String get clearFilter;

  /// No description provided for @orderLabel.
  ///
  /// In uk, this message translates to:
  /// **'Порядок точок'**
  String get orderLabel;

  /// No description provided for @orderBook.
  ///
  /// In uk, this message translates to:
  /// **'Як у книзі'**
  String get orderBook;

  /// No description provided for @orderCode.
  ///
  /// In uk, this message translates to:
  /// **'За кодом'**
  String get orderCode;

  /// No description provided for @noMatchesTitle.
  ///
  /// In uk, this message translates to:
  /// **'Нічого не знайдено'**
  String get noMatchesTitle;

  /// No description provided for @segmentNoMatchesMessage.
  ///
  /// In uk, this message translates to:
  /// **'У цьому розділі немає точок за запитом «{query}».'**
  String segmentNoMatchesMessage(String query);

  /// No description provided for @sourcePages.
  ///
  /// In uk, this message translates to:
  /// **'стор. {pages}'**
  String sourcePages(String pages);

  /// No description provided for @pointDescription.
  ///
  /// In uk, this message translates to:
  /// **'Опис'**
  String get pointDescription;

  /// No description provided for @pointSymptoms.
  ///
  /// In uk, this message translates to:
  /// **'Симптоми'**
  String get pointSymptoms;

  /// No description provided for @showMoreSymptoms.
  ///
  /// In uk, this message translates to:
  /// **'Ще {count}'**
  String showMoreSymptoms(int count);

  /// No description provided for @handwrittenNotes.
  ///
  /// In uk, this message translates to:
  /// **'Рукописні нотатки власника'**
  String get handwrittenNotes;

  /// No description provided for @transcriptionNotes.
  ///
  /// In uk, this message translates to:
  /// **'Примітки транскрипції'**
  String get transcriptionNotes;

  /// No description provided for @figureCounter.
  ///
  /// In uk, this message translates to:
  /// **'{index} з {total}'**
  String figureCounter(int index, int total);

  /// No description provided for @figureOverview.
  ///
  /// In uk, this message translates to:
  /// **'зведена схема'**
  String get figureOverview;

  /// No description provided for @figureDetail.
  ///
  /// In uk, this message translates to:
  /// **'малюнок біля опису'**
  String get figureDetail;

  /// No description provided for @previousPoint.
  ///
  /// In uk, this message translates to:
  /// **'Попередня точка'**
  String get previousPoint;

  /// No description provided for @nextPoint.
  ///
  /// In uk, this message translates to:
  /// **'Наступна точка'**
  String get nextPoint;

  /// No description provided for @close.
  ///
  /// In uk, this message translates to:
  /// **'Закрити'**
  String get close;

  /// No description provided for @pointsOnFigure.
  ///
  /// In uk, this message translates to:
  /// **'Точки на малюнку'**
  String get pointsOnFigure;

  /// No description provided for @openFullscreen.
  ///
  /// In uk, this message translates to:
  /// **'Відкрити на весь екран'**
  String get openFullscreen;

  /// No description provided for @symptomFilterHint.
  ///
  /// In uk, this message translates to:
  /// **'Хвороба або орган'**
  String get symptomFilterHint;

  /// No description provided for @symptomNoMatchesMessage.
  ///
  /// In uk, this message translates to:
  /// **'У покажчику немає записів за запитом «{query}».'**
  String symptomNoMatchesMessage(String query);

  /// No description provided for @subtermsCount.
  ///
  /// In uk, this message translates to:
  /// **'{count, plural, one{{count} підтема} few{{count} підтеми} many{{count} підтем} other{{count} підтеми}}'**
  String subtermsCount(int count);

  /// No description provided for @jumpToLetter.
  ///
  /// In uk, this message translates to:
  /// **'Перейти до літери {letter}'**
  String jumpToLetter(String letter);

  /// No description provided for @handwrittenEntry.
  ///
  /// In uk, this message translates to:
  /// **'Дописано від руки'**
  String get handwrittenEntry;

  /// No description provided for @handwrittenEntryMessage.
  ///
  /// In uk, this message translates to:
  /// **'Цього рядка немає в друкованому покажчику — його дописав власник брошури.'**
  String get handwrittenEntryMessage;

  /// No description provided for @legend.
  ///
  /// In uk, this message translates to:
  /// **'Позначення'**
  String get legend;

  /// No description provided for @legendTitle.
  ///
  /// In uk, this message translates to:
  /// **'Позначення в покажчику'**
  String get legendTitle;

  /// No description provided for @legendSuffixes.
  ///
  /// In uk, this message translates to:
  /// **'Літери M і B у кодах (2M, 2B) — частина назви точки. «MB» після числа означає пару: 10MB — це 10M і 10B.'**
  String get legendSuffixes;

  /// No description provided for @somaticPoints.
  ///
  /// In uk, this message translates to:
  /// **'Соматичні точки'**
  String get somaticPoints;

  /// No description provided for @somaticPointsMessage.
  ///
  /// In uk, this message translates to:
  /// **'Діють на весь організм.'**
  String get somaticPointsMessage;

  /// No description provided for @glossary.
  ///
  /// In uk, this message translates to:
  /// **'Словник'**
  String get glossary;

  /// No description provided for @glossaryFilterHint.
  ///
  /// In uk, this message translates to:
  /// **'Термін'**
  String get glossaryFilterHint;

  /// No description provided for @glossaryNoMatchesMessage.
  ///
  /// In uk, this message translates to:
  /// **'У словнику немає термінів за запитом «{query}».'**
  String glossaryNoMatchesMessage(String query);

  /// No description provided for @sideLeft.
  ///
  /// In uk, this message translates to:
  /// **'ліва сторона'**
  String get sideLeft;

  /// No description provided for @sideRight.
  ///
  /// In uk, this message translates to:
  /// **'права сторона'**
  String get sideRight;

  /// No description provided for @sideBoth.
  ///
  /// In uk, this message translates to:
  /// **'ліва і права сторони'**
  String get sideBoth;

  /// No description provided for @pairedPoints.
  ///
  /// In uk, this message translates to:
  /// **'парні точки'**
  String get pairedPoints;

  /// No description provided for @pressTogether.
  ///
  /// In uk, this message translates to:
  /// **'Натискати разом'**
  String get pressTogether;

  /// No description provided for @alternative.
  ///
  /// In uk, this message translates to:
  /// **'або'**
  String get alternative;

  /// No description provided for @unknownCodeMessage.
  ///
  /// In uk, this message translates to:
  /// **'Точки з таким кодом у книзі немає'**
  String get unknownCodeMessage;

  /// No description provided for @asPrinted.
  ///
  /// In uk, this message translates to:
  /// **'У книзі'**
  String get asPrinted;

  /// No description provided for @noPointsForSymptom.
  ///
  /// In uk, this message translates to:
  /// **'Для цього запису в книзі не вказано точок.'**
  String get noPointsForSymptom;

  /// No description provided for @search.
  ///
  /// In uk, this message translates to:
  /// **'Пошук'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In uk, this message translates to:
  /// **'Код, симптом або слово'**
  String get searchHint;

  /// No description provided for @clearSearch.
  ///
  /// In uk, this message translates to:
  /// **'Очистити запит'**
  String get clearSearch;

  /// No description provided for @searchPromptTitle.
  ///
  /// In uk, this message translates to:
  /// **'Що шукаємо?'**
  String get searchPromptTitle;

  /// No description provided for @searchPromptMessage.
  ///
  /// In uk, this message translates to:
  /// **'Код точки, наприклад 12M, симптом або слово з опису.'**
  String get searchPromptMessage;

  /// No description provided for @resultsPoints.
  ///
  /// In uk, this message translates to:
  /// **'Точки · {count}'**
  String resultsPoints(int count);

  /// No description provided for @resultsSymptoms.
  ///
  /// In uk, this message translates to:
  /// **'Симптоми · {count}'**
  String resultsSymptoms(int count);

  /// No description provided for @resultsGlossary.
  ///
  /// In uk, this message translates to:
  /// **'Словник · {count}'**
  String resultsGlossary(int count);

  /// No description provided for @searchNoResultsMessage.
  ///
  /// In uk, this message translates to:
  /// **'За запитом «{query}» нічого немає. Спробуйте інше слово або знайдіть симптом у покажчику.'**
  String searchNoResultsMessage(String query);

  /// No description provided for @openSymptoms.
  ///
  /// In uk, this message translates to:
  /// **'Відкрити покажчик симптомів'**
  String get openSymptoms;

  /// No description provided for @recentSearches.
  ///
  /// In uk, this message translates to:
  /// **'Останні запити'**
  String get recentSearches;

  /// No description provided for @clear.
  ///
  /// In uk, this message translates to:
  /// **'Очистити'**
  String get clear;

  /// No description provided for @removeSearch.
  ///
  /// In uk, this message translates to:
  /// **'Видалити запит «{query}»'**
  String removeSearch(String query);

  /// No description provided for @clearSearchesTitle.
  ///
  /// In uk, this message translates to:
  /// **'Очистити останні запити?'**
  String get clearSearchesTitle;

  /// No description provided for @clearSearchesMessage.
  ///
  /// In uk, this message translates to:
  /// **'Усі збережені запити буде видалено з цього пристрою.'**
  String get clearSearchesMessage;

  /// No description provided for @cancel.
  ///
  /// In uk, this message translates to:
  /// **'Скасувати'**
  String get cancel;

  /// No description provided for @addToFavorites.
  ///
  /// In uk, this message translates to:
  /// **'Додати в обране'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In uk, this message translates to:
  /// **'Прибрати з обраного'**
  String get removeFromFavorites;

  /// No description provided for @addedToFavorites.
  ///
  /// In uk, this message translates to:
  /// **'Точку {code} додано в обране'**
  String addedToFavorites(String code);

  /// No description provided for @removedFromFavorites.
  ///
  /// In uk, this message translates to:
  /// **'Точку {code} прибрано з обраного'**
  String removedFromFavorites(String code);

  /// No description provided for @favorites.
  ///
  /// In uk, this message translates to:
  /// **'Обране'**
  String get favorites;

  /// No description provided for @history.
  ///
  /// In uk, this message translates to:
  /// **'Історія'**
  String get history;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Збережіть першу точку'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyMessage.
  ///
  /// In uk, this message translates to:
  /// **'Торкніться зірочки на сторінці точки — і вона з\'явиться тут.'**
  String get favoritesEmptyMessage;

  /// No description provided for @openBody.
  ///
  /// In uk, this message translates to:
  /// **'Відкрити частини тіла'**
  String get openBody;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Історія порожня'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyMessage.
  ///
  /// In uk, this message translates to:
  /// **'Тут з\'являться точки, розділи й симптоми, які ви відкривали.'**
  String get historyEmptyMessage;

  /// No description provided for @clearHistory.
  ///
  /// In uk, this message translates to:
  /// **'Очистити історію'**
  String get clearHistory;

  /// No description provided for @clearHistoryTitle.
  ///
  /// In uk, this message translates to:
  /// **'Очистити історію переглядів?'**
  String get clearHistoryTitle;

  /// No description provided for @clearHistoryMessage.
  ///
  /// In uk, this message translates to:
  /// **'Список відкритих точок і розділів буде видалено з цього пристрою. Обране залишиться.'**
  String get clearHistoryMessage;

  /// No description provided for @today.
  ///
  /// In uk, this message translates to:
  /// **'Сьогодні'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In uk, this message translates to:
  /// **'Вчора'**
  String get yesterday;

  /// No description provided for @earlier.
  ///
  /// In uk, this message translates to:
  /// **'Раніше'**
  String get earlier;

  /// No description provided for @historyTypeSegment.
  ///
  /// In uk, this message translates to:
  /// **'Частина тіла'**
  String get historyTypeSegment;

  /// No description provided for @historyTypeSymptom.
  ///
  /// In uk, this message translates to:
  /// **'Симптом'**
  String get historyTypeSymptom;

  /// No description provided for @historyTypeTerm.
  ///
  /// In uk, this message translates to:
  /// **'Термін словника'**
  String get historyTypeTerm;

  /// No description provided for @recentViews.
  ///
  /// In uk, this message translates to:
  /// **'Нещодавні'**
  String get recentViews;

  /// No description provided for @showAll.
  ///
  /// In uk, this message translates to:
  /// **'Усі'**
  String get showAll;

  /// No description provided for @termsCount.
  ///
  /// In uk, this message translates to:
  /// **'{count, plural, one{{count} термін} few{{count} терміни} many{{count} термінів} other{{count} терміна}}'**
  String termsCount(int count);

  /// No description provided for @settings.
  ///
  /// In uk, this message translates to:
  /// **'Налаштування'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In uk, this message translates to:
  /// **'Тема'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In uk, this message translates to:
  /// **'Як у системі'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In uk, this message translates to:
  /// **'Світла'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In uk, this message translates to:
  /// **'Темна'**
  String get themeDark;

  /// No description provided for @aboutSource.
  ///
  /// In uk, this message translates to:
  /// **'Про джерело і застереження'**
  String get aboutSource;

  /// No description provided for @aboutTitle.
  ///
  /// In uk, this message translates to:
  /// **'Про джерело'**
  String get aboutTitle;

  /// No description provided for @disclaimerTitle.
  ///
  /// In uk, this message translates to:
  /// **'Перш ніж почати'**
  String get disclaimerTitle;

  /// No description provided for @disclaimerHeading.
  ///
  /// In uk, this message translates to:
  /// **'Застереження'**
  String get disclaimerHeading;

  /// No description provided for @disclaimerSource.
  ///
  /// In uk, this message translates to:
  /// **'Цей застосунок відтворює текст і малюнки брошури про точки надавлювання, виданої 1992 року. Він показує матеріал джерела як є і нічого не додає від себе.'**
  String get disclaimerSource;

  /// No description provided for @disclaimerNotAdvice.
  ///
  /// In uk, this message translates to:
  /// **'Це не медична порада. Описані методи не перевірені сучасною медициною і не замінюють звернення до лікаря.'**
  String get disclaimerNotAdvice;

  /// No description provided for @disclaimerEmergency.
  ///
  /// In uk, this message translates to:
  /// **'Якщо у вас гострий біль, травма або стан, що загрожує життю, зверніться по медичну допомогу.'**
  String get disclaimerEmergency;

  /// No description provided for @disclaimerAccept.
  ///
  /// In uk, this message translates to:
  /// **'Я прочитав(ла), продовжити'**
  String get disclaimerAccept;

  /// No description provided for @sourceHeading.
  ///
  /// In uk, this message translates to:
  /// **'Джерело'**
  String get sourceHeading;

  /// No description provided for @sourceTranscription.
  ///
  /// In uk, this message translates to:
  /// **'Текст транскрибовано вручну зі скану, тож можливі помилки. Біля кожної точки вказано сторінку джерела, щоб можна було звіритись.'**
  String get sourceTranscription;

  /// No description provided for @sourceContents.
  ///
  /// In uk, this message translates to:
  /// **'У довіднику: {points}, {symptoms}, {terms}.'**
  String sourceContents(String points, String symptoms, String terms);

  /// No description provided for @symptomEntriesCount.
  ///
  /// In uk, this message translates to:
  /// **'{count, plural, one{{count} запис покажчика} few{{count} записи покажчика} many{{count} записів покажчика} other{{count} запису покажчика}}'**
  String symptomEntriesCount(int count);

  /// No description provided for @privacyHeading.
  ///
  /// In uk, this message translates to:
  /// **'Приватність'**
  String get privacyHeading;

  /// No description provided for @privacyMessage.
  ///
  /// In uk, this message translates to:
  /// **'Історія пошуку, історія переглядів і обране зберігаються лише на цьому пристрої. Застосунок працює без мережі й не збирає жодних даних.'**
  String get privacyMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
