class ReviewEligibility {
  final bool canReview;
  final String? reason;

  const ReviewEligibility({required this.canReview, this.reason});

  factory ReviewEligibility.fromJson(Map<String, dynamic> json) {
    return ReviewEligibility(
      canReview: json['canReview'] == true,
      reason: json['reason'] as String?,
    );
  }
}
