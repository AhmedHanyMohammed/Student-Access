enum ScanStatus {
  valid,
  alreadyCheckedIn,
  invalid,
  inactive,
  cancelled,
  unknown
}

class ScanResultData {
  final bool success;
  final String rawStatus;
  final String result;
  final String message;
  final String? attendeeName;
  final String? attendeeEmail;
  final String? eventTitle;
  final DateTime? checkedInAt;

  const ScanResultData({
    required this.success,
    required this.rawStatus,
    required this.result,
    required this.message,
    this.attendeeName,
    this.attendeeEmail,
    this.eventTitle,
    this.checkedInAt,
  });

  ScanStatus get status {
    final s = rawStatus.toLowerCase().trim();
    if (s == 'valid' || result.toLowerCase() == 'valid' || result.toLowerCase() == 'success') {
      return ScanStatus.valid;
    }
    if (s == 'already checked in' || result.toLowerCase() == 'alreadycheckedin') {
      return ScanStatus.alreadyCheckedIn;
    }
    if (s == 'invalid' || result.toLowerCase() == 'invalid' || result.toLowerCase() == 'invalidtoken') {
      return ScanStatus.invalid;
    }
    if (s == 'inactive' || result.toLowerCase() == 'inactive' || result.toLowerCase() == 'eventinactive') {
      return ScanStatus.inactive;
    }
    if (s == 'cancelled' || result.toLowerCase() == 'cancelled') {
      return ScanStatus.cancelled;
    }
    return ScanStatus.unknown;
  }

  factory ScanResultData.fromJson(Map<String, dynamic> json) {
    return ScanResultData(
      success: json['success'] as bool? ?? false,
      rawStatus: json['status'] as String? ?? json['result'] as String? ?? 'invalid',
      result: json['result'] as String? ?? '',
      message: json['message'] as String? ?? '',
      attendeeName: json['attendeeName'] as String?,
      attendeeEmail: json['attendeeEmail'] as String?,
      eventTitle: json['eventTitle'] as String?,
      checkedInAt: json['checkedInAt'] != null ? DateTime.tryParse(json['checkedInAt'] as String) : null,
    );
  }
}
