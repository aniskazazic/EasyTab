import 'dart:math';

class ReservationCheckoutRequest {
  final String checkoutId;
  final int tableId;
  final int numberOfGuests;
  final DateTime reservationDate;
  final String startTime;
  final String endTime;

  ReservationCheckoutRequest({
    required this.tableId,
    required this.numberOfGuests,
    required this.reservationDate,
    required this.startTime,
    required this.endTime,
  }) : checkoutId = _newId();

  static String _newId() {
    final random = Random.secure();
    final hex = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Map<String, dynamic> toJson() => {
    'checkoutId': checkoutId,
    'tableId': tableId,
    'numberOfGuests': numberOfGuests,
    'reservationDate': DateTime(
      reservationDate.year,
      reservationDate.month,
      reservationDate.day,
    ).toIso8601String(),
    'startTime': startTime.length == 5 ? '$startTime:00' : startTime,
    'endTime': endTime.length == 5 ? '$endTime:00' : endTime,
  };
}
