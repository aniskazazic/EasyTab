class TimeSlot {
  final DateTime reservationDate;
  final String start;
  final String end;

  const TimeSlot({
    required this.reservationDate,
    required this.start,
    required this.end,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      reservationDate: DateTime.parse(json['reservationDate'] as String),
      start: json['start'] as String,
      end: json['end'] as String,
    );
  }
}
