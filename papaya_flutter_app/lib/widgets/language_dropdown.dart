import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LanguageDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final List<DropdownMenuItem<String>> items;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;
  final double iconSize;
  final TextStyle style;

  const LanguageDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    this.selectedItemBuilder,
    this.iconSize = 24,
    this.style = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      dropdownColor: AppTheme.forestGreen,
      icon: Icon(Icons.language, color: Colors.white, size: iconSize),
      underline: const SizedBox(),
      style: style,
      items: items,
      selectedItemBuilder: selectedItemBuilder,
      onChanged: onChanged,
    );
  }
}
