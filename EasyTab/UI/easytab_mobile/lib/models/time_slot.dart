class TimeSlot {
  final String start;
  final String end;

  const TimeSlot({required this.start, required this.end});

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      start: json['start'] as String,
      end: json['end'] as String,
    );
  }
}
