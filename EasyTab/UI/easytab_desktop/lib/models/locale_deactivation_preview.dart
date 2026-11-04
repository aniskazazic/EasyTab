class LocaleDeactivationPreview {
  final int futureReservationsCount;

  const LocaleDeactivationPreview({required this.futureReservationsCount});

  factory LocaleDeactivationPreview.fromJson(Map<String, dynamic> json) =>
      LocaleDeactivationPreview(
        futureReservationsCount: (json['futureReservationsCount'] as num)
            .toInt(),
      );
}
