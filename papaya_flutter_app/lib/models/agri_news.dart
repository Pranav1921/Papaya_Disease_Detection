import '../utils/localized_text.dart';

class AgriNews {
  final String id;
  final String titleKannada;
  final String titleEnglish;
  final String titleHindi;
  final String categoryKannada;
  final String categoryEnglish;
  final String categoryHindi;
  final String summaryKannada;
  final String summaryEnglish;
  final String summaryHindi;
  final String dateKannada;
  final String dateEnglish;
  final String dateHindi;
  final String iconEmoji;
  final String sourceKannada;
  final String sourceEnglish;
  final String sourceHindi;
  final bool isFeatured;

  const AgriNews({
    required this.id,
    required this.titleKannada,
    required this.titleEnglish,
    required this.titleHindi,
    required this.categoryKannada,
    required this.categoryEnglish,
    required this.categoryHindi,
    required this.summaryKannada,
    required this.summaryEnglish,
    required this.summaryHindi,
    required this.dateKannada,
    required this.dateEnglish,
    required this.dateHindi,
    required this.iconEmoji,
    required this.sourceKannada,
    required this.sourceEnglish,
    required this.sourceHindi,
    this.isFeatured = false,
  });

  factory AgriNews.fromJson(Map<String, dynamic> json) {
    return AgriNews(
      id: json['id'] ?? '',
      titleKannada: json['titleKannada'] ?? '',
      titleEnglish: json['titleEnglish'] ?? '',
      titleHindi: json['titleHindi'] ?? '',
      categoryKannada: json['categoryKannada'] ?? '',
      categoryEnglish: json['categoryEnglish'] ?? '',
      categoryHindi: json['categoryHindi'] ?? '',
      summaryKannada: json['summaryKannada'] ?? '',
      summaryEnglish: json['summaryEnglish'] ?? '',
      summaryHindi: json['summaryHindi'] ?? '',
      dateKannada: json['dateKannada'] ?? '',
      dateEnglish: json['dateEnglish'] ?? '',
      dateHindi: json['dateHindi'] ?? '',
      iconEmoji: json['iconEmoji'] ?? '📰',
      sourceKannada: json['sourceKannada'] ?? '',
      sourceEnglish: json['sourceEnglish'] ?? '',
      sourceHindi: json['sourceHindi'] ?? '',
      isFeatured: json['isFeatured'] ?? false,
    );
  }

  String getTitle(String lang) {
    return pickLocalized(
      lang,
      kn: titleKannada,
      en: titleEnglish,
      hi: titleHindi,
    );
  }

  String getCategory(String lang) {
    return pickLocalized(
      lang,
      kn: categoryKannada,
      en: categoryEnglish,
      hi: categoryHindi,
    );
  }

  String getSummary(String lang) {
    return pickLocalized(
      lang,
      kn: summaryKannada,
      en: summaryEnglish,
      hi: summaryHindi,
    );
  }

  String getDate(String lang) {
    return pickLocalized(lang, kn: dateKannada, en: dateEnglish, hi: dateHindi);
  }

  String getSource(String lang) {
    return pickLocalized(
      lang,
      kn: sourceKannada,
      en: sourceEnglish,
      hi: sourceHindi,
    );
  }
}
