import 'dart:io';

import 'package:acupoints/data/content_repository.dart';

/// Справжній вміст застосунку, прочитаний із `assets/content.json`.
///
/// Тести запускаються з кореня проєкту `app/`, тож шлях відносний.
ContentRepository loadTestContent() => ContentRepository.fromJsonString(
  File(ContentRepository.assetPath).readAsStringSync(),
);
