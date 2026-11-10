import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content_repository.dart';
import 'search_index.dart';

/// Вміст довідника. Завантажується з ресурсів один раз.
///
/// Автоповтор вимкнено: ресурс вшитий у застосунок, тож помилка розбору
/// сама не зникне — показуємо її користувачеві з кнопкою «Спробувати ще».
final contentRepositoryProvider = FutureProvider<ContentRepository>(
  (ref) => ContentRepository.load(rootBundle),
  retry: (retryCount, error) => null,
);

/// Завантажений вміст для екранів під `ContentGate`.
///
/// Синхронний: до екранів справа доходить лише після успішного завантаження.
final repositoryProvider = Provider<ContentRepository>(
  (ref) => ref.watch(contentRepositoryProvider).requireValue,
);

/// Пошуковий індекс. Будується один раз після завантаження вмісту.
final searchIndexProvider = Provider<SearchIndex>(
  (ref) => SearchIndex(ref.watch(repositoryProvider)),
);
