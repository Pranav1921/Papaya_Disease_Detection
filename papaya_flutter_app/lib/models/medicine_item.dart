import '../utils/localized_text.dart';

class MedicineItem {
  final String id;
  final String nameKannada;
  final String nameEnglish;
  final String nameHindi;
  final String typeKannada;
  final String typeEnglish;
  final String typeHindi;
  final String dosageKannada;
  final String dosageEnglish;
  final String dosageHindi;
  final double price; // MRP in Rupees
  final String packageSizeKannada;
  final String packageSizeEnglish;
  final String packageSizeHindi;
  final String descriptionKannada;
  final String descriptionEnglish;
  final String descriptionHindi;
  final bool isSubsidizedRSK; // 50% RSK subsidy available
  final String buyUrl;

  const MedicineItem({
    required this.id,
    required this.nameKannada,
    required this.nameEnglish,
    required this.nameHindi,
    required this.typeKannada,
    required this.typeEnglish,
    required this.typeHindi,
    required this.dosageKannada,
    required this.dosageEnglish,
    required this.dosageHindi,
    required this.price,
    required this.packageSizeKannada,
    required this.packageSizeEnglish,
    required this.packageSizeHindi,
    required this.descriptionKannada,
    required this.descriptionEnglish,
    required this.descriptionHindi,
    this.isSubsidizedRSK = false,
    this.buyUrl = 'https://www.bighaat.com',
  });

  String getName(String lang) {
    return pickLocalized(lang, kn: nameKannada, en: nameEnglish, hi: nameHindi);
  }

  String getType(String lang) {
    return pickLocalized(lang, kn: typeKannada, en: typeEnglish, hi: typeHindi);
  }

  String getDosage(String lang) {
    return pickLocalized(lang, kn: dosageKannada, en: dosageEnglish, hi: dosageHindi);
  }

  String getPackageSize(String lang) {
    return pickLocalized(lang, kn: packageSizeKannada, en: packageSizeEnglish, hi: packageSizeHindi);
  }

  String getDescription(String lang) {
    return pickLocalized(lang, kn: descriptionKannada, en: descriptionEnglish, hi: descriptionHindi);
  }
}
