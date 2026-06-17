/// Suggestion IA (rule-based ou styliste premium).
class AiOutfitSuggestion {
  final Map<String, String> garments;
  final String rationaleShort;

  const AiOutfitSuggestion({
    required this.garments,
    this.rationaleShort = '',
  });

  factory AiOutfitSuggestion.fromGarmentMap(Map<String, String> map) =>
      AiOutfitSuggestion(garments: map);

  factory AiOutfitSuggestion.fromJson(Map<String, dynamic> json) {
    final raw = json['garments'];
    final garments = raw is Map
        ? Map<String, String>.from(
            raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
          )
        : <String, String>{};
    return AiOutfitSuggestion(
      garments: garments,
      rationaleShort: json['rationale_short'] as String? ?? '',
    );
  }
}
