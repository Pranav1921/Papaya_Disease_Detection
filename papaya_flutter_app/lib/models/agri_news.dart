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

  String getTitle(String lang) {
    if (lang == 'kn') return titleKannada;
    if (lang == 'hi') return titleHindi;
    return titleEnglish;
  }

  String getCategory(String lang) {
    if (lang == 'kn') return categoryKannada;
    if (lang == 'hi') return categoryHindi;
    return categoryEnglish;
  }

  String getSummary(String lang) {
    if (lang == 'kn') return summaryKannada;
    if (lang == 'hi') return summaryHindi;
    return summaryEnglish;
  }

  String getDate(String lang) {
    if (lang == 'kn') return dateKannada;
    if (lang == 'hi') return dateHindi;
    return dateEnglish;
  }

  String getSource(String lang) {
    if (lang == 'kn') return sourceKannada;
    if (lang == 'hi') return sourceHindi;
    return sourceEnglish;
  }
}
