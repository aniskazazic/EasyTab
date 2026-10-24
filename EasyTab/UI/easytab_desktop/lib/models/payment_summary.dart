class PaymentSummary {
  final double totalCollectedKm;
  final double totalRefundedKm;

  PaymentSummary.fromJson(Map<String, dynamic> json)
    : totalCollectedKm = (json['totalCollectedKm'] as num).toDouble(),
      totalRefundedKm = (json['totalRefundedKm'] as num).toDouble();
}
