class RecommendedLocale {
  final int id;
  final String name;
  final String categoryName;
  final String cityName;
  final double averageRating;
  final String? logo;
  final String explanation;
  final double score;

  const RecommendedLocale({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.cityName,
    required this.averageRating,
    required this.logo,
    required this.explanation,
    required this.score,
  });

  factory RecommendedLocale.fromJson(Map<String, Object?> json) {
    return RecommendedLocale(
      id: json['id'] as int,
      name: json['name'] as String,
      categoryName: json['categoryName'] as String,
      cityName: json['cityName'] as String,
      averageRating: (json['averageRating'] as num).toDouble(),
      logo: json['logo'] as String?,
      explanation: json['explanation'] as String,
      score: (json['score'] as num).toDouble(),
    );
  }
}
