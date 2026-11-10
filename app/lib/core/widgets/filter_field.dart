import 'package:flutter/material.dart';

import '../l10n.dart';
import '../theme/app_theme.dart';

/// Поле фільтра списку з кнопкою очищення.
class FilterField extends StatelessWidget {
  const FilterField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;

  /// Викликається і під час набору, і після очищення.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.filter_list),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: context.l10n.clearFilter,
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.clear();
                  onChanged();
                },
              ),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.search),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
