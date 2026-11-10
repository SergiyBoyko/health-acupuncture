import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'content_repository.dart';

/// Вміст довідника. Завантажується з ресурсів один раз.
///
/// Автоповтор вимкнено: ресурс вшитий у застосунок, тож помилка розбору
/// сама не зникне — показуємо її користувачеві з кнопкою «Спробувати ще».
final contentRepositoryProvider = FutureProvider<ContentRepository>(
  (ref) => ContentRepository.load(rootBundle),
  retry: (retryCount, error) => null,
);
