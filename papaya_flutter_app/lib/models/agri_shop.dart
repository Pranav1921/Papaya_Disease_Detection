class AgriShop {
  final String id;
  final String nameKannada;
  final String nameEnglish;
  final String nameHindi;
  final String shopType; // RSK (Govt), Agri Center, Co-Op Society
  final String addressKannada;
  final String addressHindi;
  final String talukDistrict;
  final double latitude;
  final double longitude;
  final double distanceKm; // Calculated from user location
  final String phone;
  final double rating;
  final bool isGovtRSK;
  final List<String> inStockMedicineIds;

  const AgriShop({
    required this.id,
    required this.nameKannada,
    required this.nameEnglish,
    required this.nameHindi,
    required this.shopType,
    required this.addressKannada,
    required this.addressHindi,
    required this.talukDistrict,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.phone,
    required this.rating,
    this.isGovtRSK = false,
    required this.inStockMedicineIds,
  });

  AgriShop copyWithDistance(double newDistanceKm) {
    return AgriShop(
      id: id,
      nameKannada: nameKannada,
      nameEnglish: nameEnglish,
      nameHindi: nameHindi,
      shopType: shopType,
      addressKannada: addressKannada,
      addressHindi: addressHindi,
      talukDistrict: talukDistrict,
      latitude: latitude,
      longitude: longitude,
      distanceKm: newDistanceKm,
      phone: phone,
      rating: rating,
      isGovtRSK: isGovtRSK,
      inStockMedicineIds: inStockMedicineIds,
    );
  }

  String getName(String lang) {
    if (lang == 'kn') return nameKannada;
    if (lang == 'hi') return nameHindi;
    return nameEnglish;
  }

  String getAddress(String lang) {
    if (lang == 'kn') return addressKannada;
    if (lang == 'hi') return addressHindi;
    return nameEnglish; // Fallback to name/address English
  }
}
