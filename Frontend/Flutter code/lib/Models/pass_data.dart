class PassData {
  final int id;
  final int eventId;
  final String eventTitle;
  final String? eventDescription;
  final String? eventLocation;
  final DateTime? eventDate;
  final String qrToken;
  final String status;
  final String? attendeeName;
  final String? attendeeEmail;
  final DateTime registeredAt;
  final DateTime? checkedInAt;

  const PassData({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    this.eventDescription,
    this.eventLocation,
    this.eventDate,
    required this.qrToken,
    required this.status,
    this.attendeeName,
    this.attendeeEmail,
    required this.registeredAt,
    this.checkedInAt,
  });

  bool get isCheckedIn => status.toLowerCase() == 'checkedin' || checkedInAt != null;

  factory PassData.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null || val is! String) return null;
      return DateTime.tryParse(val)?.toLocal();
    }

    return PassData(
      id: json['id'] as int? ?? json['Id'] as int? ?? 0,
      eventId: json['eventId'] as int? ?? json['EventId'] as int? ?? 0,
      eventTitle: json['eventTitle'] as String? ?? json['EventTitle'] as String? ?? 'Event',
      eventDescription: json['eventDescription'] as String? ?? json['EventDescription'] as String?,
      eventLocation: json['eventLocation'] as String? ?? json['EventLocation'] as String?,
      eventDate: parseDate(json['eventDate'] ?? json['EventDate']),
      qrToken: json['qrToken'] as String? ?? json['QrToken'] as String? ?? '',
      status: json['status'] as String? ?? json['Status'] as String? ?? 'Registered',
      attendeeName: json['attendeeName'] as String? ?? json['AttendeeName'] as String?,
      attendeeEmail: json['attendeeEmail'] as String? ?? json['AttendeeEmail'] as String?,
      registeredAt: parseDate(json['registeredAt'] ?? json['RegisteredAt']) ?? DateTime.now(),
      checkedInAt: parseDate(json['checkedInAt'] ?? json['CheckedInAt']),
    );
  }
}
