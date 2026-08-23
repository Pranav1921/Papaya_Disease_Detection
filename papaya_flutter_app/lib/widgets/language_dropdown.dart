import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum LanguageMenuLabelStyle { native, nativeWithEnglishGloss, twoLetterCodes }

class LanguageDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final bool useShortLabels;
  final LanguageMenuLabelStyle menuLabelStyle;
  final double iconSize;
  final TextStyle style;

  const LanguageDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.useShortLabels = false,
    this.menuLabelStyle = LanguageMenuLabelStyle.native,
    this.iconSize = 24,
    this.style = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<String>> menuItems;
    switch (menuLabelStyle) {
      case LanguageMenuLabelStyle.twoLetterCodes:
        menuItems = const [
          DropdownMenuItem(value: 'kn', child: Text('KN')),
          DropdownMenuItem(value: 'en', child: Text('EN')),
          DropdownMenuItem(value: 'hi', child: Text('HI')),
        ];
      case LanguageMenuLabelStyle.nativeWithEnglishGloss:
        menuItems = const [
          DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ (Kannada)')),
          DropdownMenuItem(value: 'en', child: Text('English')),
          DropdownMenuItem(value: 'hi', child: Text('हिन्दी (Hindi)')),
        ];
      case LanguageMenuLabelStyle.native:
        menuItems = const [
          DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ')),
          DropdownMenuItem(value: 'en', child: Text('English')),
          DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
        ];
    }

    return DropdownButton<String>(
      value: value,
      dropdownColor: AppTheme.forestGreen,
      icon: Icon(Icons.language, color: Colors.white, size: iconSize),
      underline: const SizedBox(),
      style: style,
      items: menuItems,
      selectedItemBuilder: useShortLabels
          ? (context) => const [
              Center(
                child: Text(
                  'KN',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  'EN',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  'HI',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ]
          : null,
      onChanged: onChanged,
    );
  }
}
