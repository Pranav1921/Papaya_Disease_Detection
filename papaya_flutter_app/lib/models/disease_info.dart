import 'medicine_item.dart';

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
    if (lang == 'kn') return titleKannada;
    if (lang == 'hi') return titleHindi;
    return titleEnglish;
  }

  String getSeverityLevel(String lang) {
    if (lang == 'kn') return severityLevelKannada;
    if (lang == 'hi') return severityLevelHindi;
    return severityLevelEnglish;
  }

  String getDescription(String lang) {
    if (lang == 'kn') return descriptionKannada;
    if (lang == 'hi') return descriptionHindi;
    return descriptionEnglish;
  }

  String getChemicalTreatment(String lang) {
    if (lang == 'kn') return chemicalTreatmentKannada;
    if (lang == 'hi') return chemicalTreatmentHindi;
    return chemicalTreatmentEnglish;
  }

  String getOrganicTreatment(String lang) {
    if (lang == 'kn') return organicTreatmentKannada;
    if (lang == 'hi') return organicTreatmentHindi;
    return organicTreatmentEnglish;
  }

  String getFertilizerSchedule(String lang) {
    if (lang == 'kn') return fertilizerScheduleKannada;
    if (lang == 'hi') return fertilizerScheduleHindi;
    return fertilizerScheduleEnglish;
  }

  String getPreventiveCare(String lang) {
    if (lang == 'kn') return preventiveCareKannada;
    if (lang == 'hi') return preventiveCareHindi;
    return preventiveCareEnglish;
  }

  String getSafetyInterval(String lang) {
    if (lang == 'kn') return safetyIntervalKannada;
    if (lang == 'hi') return safetyIntervalHindi;
    return safetyIntervalEnglish;
  }
}
