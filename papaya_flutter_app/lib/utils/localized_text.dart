String pickLocalized(
  String lang, {
  required String kn,
  required String en,
  required String hi,
}) {
  if (lang == 'kn') return kn;
  if (lang == 'hi') return hi;
  return en;
}
