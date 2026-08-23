import 'medicine_item.dart';
import '../utils/localized_text.dart';

class DiseaseInfo {
  final String id;
  final String titleKannada;
  final String titleEnglish;
  final String titleHindi;
  final String severityLevelKannada;
  final String severityLevelEnglish;
  final String severityLevelHindi;
  final double defaultSeverityPercent; // e.g. 78.5%
  final String descriptionKannada;
  final String descriptionEnglish;
  final String descriptionHindi;
  final String chemicalTreatmentKannada;
  final String chemicalTreatmentEnglish;
  final String chemicalTreatmentHindi;
  final String organicTreatmentKannada;
  final String organicTreatmentEnglish;
  final String organicTreatmentHindi;
  final String fertilizerScheduleKannada;
  final String fertilizerScheduleEnglish;
  final String fertilizerScheduleHindi;
  final String preventiveCareKannada;
  final String preventiveCareEnglish;
  final String preventiveCareHindi;
  final String safetyIntervalKannada;
  final String safetyIntervalEnglish;
  final String safetyIntervalHindi;
  final List<MedicineItem> prescribedMedicines;

  const DiseaseInfo({
    required this.id,
    required this.titleKannada,
    required this.titleEnglish,
    required this.titleHindi,
    required this.severityLevelKannada,
    required this.severityLevelEnglish,
    required this.severityLevelHindi,
    required this.defaultSeverityPercent,
    required this.descriptionKannada,
    required this.descriptionEnglish,
    required this.descriptionHindi,
    required this.chemicalTreatmentKannada,
    required this.chemicalTreatmentEnglish,
    required this.chemicalTreatmentHindi,
    required this.organicTreatmentKannada,
    required this.organicTreatmentEnglish,
    required this.organicTreatmentHindi,
    required this.fertilizerScheduleKannada,
    required this.fertilizerScheduleEnglish,
    required this.fertilizerScheduleHindi,
    required this.preventiveCareKannada,
    required this.preventiveCareEnglish,
    required this.preventiveCareHindi,
    required this.safetyIntervalKannada,
    required this.safetyIntervalEnglish,
    required this.safetyIntervalHindi,
    required this.prescribedMedicines,
  });

  /// Calculates total price of all prescribed medicines
  double get totalPrice {
    return prescribedMedicines.fold(0.0, (sum, item) => sum + item.price);
  }

  String getTitle(String lang) {
    return pickLocalized(lang, kn: titleKannada, en: titleEnglish, hi: titleHindi);
  }

  String getSeverityLevel(String lang) {
    return pickLocalized(lang, kn: severityLevelKannada, en: severityLevelEnglish, hi: severityLevelHindi);
  }

  String getDescription(String lang) {
    return pickLocalized(lang, kn: descriptionKannada, en: descriptionEnglish, hi: descriptionHindi);
  }

  String getChemicalTreatment(String lang) {
    return pickLocalized(lang, kn: chemicalTreatmentKannada, en: chemicalTreatmentEnglish, hi: chemicalTreatmentHindi);
  }

  String getOrganicTreatment(String lang) {
    return pickLocalized(lang, kn: organicTreatmentKannada, en: organicTreatmentEnglish, hi: organicTreatmentHindi);
  }

  String getFertilizerSchedule(String lang) {
    return pickLocalized(lang, kn: fertilizerScheduleKannada, en: fertilizerScheduleEnglish, hi: fertilizerScheduleHindi);
  }

  String getPreventiveCare(String lang) {
    return pickLocalized(lang, kn: preventiveCareKannada, en: preventiveCareEnglish, hi: preventiveCareHindi);
  }

  String getSafetyInterval(String lang) {
    return pickLocalized(lang, kn: safetyIntervalKannada, en: safetyIntervalEnglish, hi: safetyIntervalHindi);
  }
}
