enum SystemRecommendationKind { positive, warning, action }

class SystemRecommendation {
  final String title;
  final String message;
  final SystemRecommendationKind kind;

  const SystemRecommendation({
    required this.title,
    required this.message,
    required this.kind,
  });
}
