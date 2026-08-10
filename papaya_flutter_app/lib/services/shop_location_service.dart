import 'dart:math';
import '../models/agri_shop.dart';

class ShopLocationService {
  // Reference User Location (Puttur / Mangaluru Center: 12.7684° N, 75.2027° E)
  static const double defaultUserLat = 12.7684;
  static const double defaultUserLng = 75.2027;

  static final List<AgriShop> _masterShopsList = [
    const AgriShop(
      id: 'shop_rsk_puttur',
      nameKannada: 'ರೈತ ಸಂಪರ್ಕ ಕೇಂದ್ರ (RSK - ಸರ್ಕಾರಿ)',
      nameEnglish: 'Raitha Samparka Kendra Puttur',
      nameHindi: 'रायता संपर्क केंद्र पुत्तूर (RSK - सरकारी)',
      shopType: '🏛️ ಸರ್ಕಾರಿ ಸಂಸ್ಥೆ (Govt RSK)',
      addressKannada: 'ಕೃಷಿ ಇಲಾಖೆ ಕಚೇರಿ ಹತ್ತಿರ, ಮುಖ್ಯ ರಸ್ತೆ, ಪುತ್ತೂರು',
      addressHindi: 'कृषि विभाग कार्यालय के पास, मुख्य सड़क, पुत्तूर',
      talukDistrict: 'ಪುತ್ತೂರು, ದಕ್ಷಿಣ ಕನ್ನಡ',
      latitude: 12.7695,
      longitude: 75.2045,
      distanceKm: 0.0,
      phone: '+91 8251 230455',
      rating: 4.8,
      isGovtRSK: true,
      inStockMedicineIds: ['m_pseudo', 'm_neem', 'm_tricho', 'm_sulphur'],
    ),
    const AgriShop(
      id: 'shop_agro_puttur',
      nameKannada: 'ಶ್ರೀ ದುರ್ಗಾ ಕೃಷಿ ಸೇವಾ ಕೇಂದ್ರ',
      nameEnglish: 'Shree Durga Agro Chemicals',
      nameHindi: 'श्री दुर्गा कृषि सेवा केंद्र',
      shopType: '🛒 ಅಧಿಕೃತ ಕೃಷಿ ಮಳಿಗೆ (Agri Store)',
      addressKannada: 'ಬಸ್ ಸ್ಟ್ಯಾಂಡ್ ಎದುರು, ದರ್ಬೆ, ಪುತ್ತೂರು',
      addressHindi: 'बस स्टैंड के सामने, दर्बे, पुत्तूर',
      talukDistrict: 'ಪುತ್ತೂರು, ದಕ್ಷಿಣ ಕನ್ನಡ',
      latitude: 12.7620,
      longitude: 75.1980,
      distanceKm: 0.0,
      phone: '+91 94481 22334',
      rating: 4.6,
      isGovtRSK: false,
      inStockMedicineIds: ['m_confidor', 'm_actara', 'm_contaf', 'm_dithane'],
    ),
    const AgriShop(
      id: 'shop_rsk_mangaluru',
      nameKannada: 'ರೈತ ಸಂಪರ್ಕ ಕೇಂದ್ರ ಮಂಗಳೂರು (RSK)',
      nameEnglish: 'Raitha Samparka Kendra Mangaluru',
      nameHindi: 'रायता संपर्क केंद्र मंगलूरु (RSK)',
      shopType: '🏛️ ಸರ್ಕಾರಿ ಸಂಸ್ಥೆ (Govt RSK)',
      addressKannada: 'ಕೋಟೆಕಾರ್ ಗೋಳಿಪಡ್ಪು, ಮಂಗಳೂರು',
      addressHindi: 'कोटेकार गोलीपडपु, मंगलूरु',
      talukDistrict: 'ಮಂಗಳೂರು, ದಕ್ಷಿಣ ಕನ್ನಡ',
      latitude: 12.9141,
      longitude: 74.8560,
      distanceKm: 0.0,
      phone: '+91 824 2422301',
      rating: 4.7,
      isGovtRSK: true,
      inStockMedicineIds: ['m_pseudo', 'm_neem', 'm_confidor', 'm_pride'],
    ),
    const AgriShop(
      id: 'shop_skpa_bantwal',
      nameKannada: 'ದಕ್ಷಿಣ ಕನ್ನಡ ಕೃಷಿಕ ಸಂಘ ಬಂಟ್ವಾಳ',
      nameEnglish: 'DK Farmers Co-Op Society Bantwal',
      nameHindi: 'दक्षिण कन्नड़ कृषक संघ बंटवाल',
      shopType: '🤝 ಸಹಕಾರಿ ಸಂಘ (Co-Op Society)',
      addressKannada: 'ಬಿ.ಸಿ. ರೋಡ್ ಕ್ರಾಸ್, ಬಂಟ್ವಾಳ',
      addressHindi: 'बी.सी. रोड क्रॉस, बंटवाल',
      talukDistrict: 'ಬಂಟ್ವಾಳ, ದಕ್ಷಿಣ ಕನ್ನಡ',
      latitude: 12.8943,
      longitude: 75.0345,
      distanceKm: 0.0,
      phone: '+91 8255 233211',
      rating: 4.5,
      isGovtRSK: false,
      inStockMedicineIds: ['m_actara', 'm_contaf', 'm_dithane', 'm_sulphur'],
    ),
    const AgriShop(
      id: 'shop_udupi_agri',
      nameKannada: 'ಉಡುಪಿ ಕೃಷಿಕ ಮಾರುಕಟ್ಟೆ ಮತ್ತು ಔಷಧ ಕೇಂದ್ರ',
      nameEnglish: 'Udupi Farmers Agro Center',
      nameHindi: 'उडुपी कृषक बाजार और औषधि केंद्र',
      shopType: '🛒 ಕೃಷಿ ಮಳಿಗೆ (Agri Store)',
      addressKannada: 'ಕವಿಮುದ್ದಣ ರಸ್ತೆ, ಉಡುಪಿ',
      addressHindi: 'कविमुद्दण मार्ग, उडुपी',
      talukDistrict: 'ಉಡುಪಿ, ಕರ್ನಾಟಕ',
      latitude: 13.3409,
      longitude: 74.7421,
      distanceKm: 0.0,
      phone: '+91 820 2521199',
      rating: 4.7,
      isGovtRSK: false,
      inStockMedicineIds: ['m_confidor', 'm_actara', 'm_pride', 'm_contaf'],
    ),
    const AgriShop(
      id: 'shop_sullia_rsk',
      nameKannada: 'ರೈತ ಸಂಪರ್ಕ ಕೇಂದ್ರ ಸುಳ್ಯ',
      nameEnglish: 'Raitha Samparka Kendra Sullia',
      nameHindi: 'रायता संपर्क केंद्र सुल्लिया',
      shopType: '🏛️ ಸರ್ಕಾರಿ ಸಂಸ್ಥೆ (Govt RSK)',
      addressKannada: 'ಮುಖ್ಯ ರಸ್ತೆ, ಸುಳ್ಯ',
      addressHindi: 'मुख्य सड़क, सुल्लिया',
      talukDistrict: 'ಸುಳ್ಯ, ದಕ್ಷಿಣ ಕನ್ನಡ',
      latitude: 12.5647,
      longitude: 75.3892,
      distanceKm: 0.0,
      phone: '+91 8257 230222',
      rating: 4.6,
      isGovtRSK: true,
      inStockMedicineIds: ['m_pseudo', 'm_neem', 'm_dithane'],
    ),
    const AgriShop(
      id: 'shop_faraway_mysuru',
      nameKannada: 'ಮೈಸೂರು ಅಗ್ರಿ ಮಾರ್ಟ್ (135 Km - Out of 100km Range)',
      nameEnglish: 'Mysuru Agro Mart',
      nameHindi: 'मैसूर एग्रो मार्ट',
      shopType: '🛒 ದೂರದ ಮಳಿಗೆ',
      addressKannada: 'ಕೆ.ಆರ್. ಸರ್ಕಲ್, ಮೈಸೂರು',
      addressHindi: 'के.आर. सर्कल, मैसूर',
      talukDistrict: 'ಮೈಸೂರು',
      latitude: 12.2958,
      longitude: 76.6394,
      distanceKm: 0.0,
      phone: '+91 821 2420011',
      rating: 4.1,
      isGovtRSK: false,
      inStockMedicineIds: [],
    ),
  ];

  /// Computes distance using Haversine formula in Kilometers
  static double calculateHaversineDistance(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  /// Gets shops strictly within maxDistanceKm (Default 100 KM)
  static List<AgriShop> getShopsWithinRadius({
    double userLat = defaultUserLat,
    double userLng = defaultUserLng,
    double maxDistanceKm = 100.0,
  }) {
    List<AgriShop> updatedList = _masterShopsList.map((shop) {
      double dist = calculateHaversineDistance(userLat, userLng, shop.latitude, shop.longitude);
      return shop.copyWithDistance(dist);
    }).toList();

    // Filter shops strictly less than maxDistanceKm (100km)
    List<AgriShop> filtered = updatedList.where((shop) => shop.distanceKm <= maxDistanceKm).toList();

    // Sort by distance ascending
    filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return filtered;
  }
}
