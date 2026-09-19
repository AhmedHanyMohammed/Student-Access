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
    return PassData(
      id: json['id'] as int? ?? 0,
      eventId: json['eventId'] as int? ?? 0,
      eventTitle: json['eventTitle'] as String? ?? 'Event',
      eventDescription: json['eventDescription'] as String?,
      eventLocation: json['eventLocation'] as String?,
      eventDate: json['eventDate'] != null ? DateTime.tryParse(json['eventDate'] as String) : null,
      qrToken: json['qrToken'] as String? ?? '',
      status: json['status'] as String? ?? 'Registered',
      attendeeName: json['attendeeName'] as String?,
      attendeeEmail: json['attendeeEmail'] as String?,
      registeredAt: json['registeredAt'] != null
          ? (DateTime.tryParse(json['registeredAt'] as String) ?? DateTime.now())
          : DateTime.now(),
      checkedInAt: json['checkedInAt'] != null ? DateTime.tryParse(json['checkedInAt'] as String) : null,
    );
  }
}
