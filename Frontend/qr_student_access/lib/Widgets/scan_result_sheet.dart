import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Models/scan_result_data.dart';

class ScanResultBottomSheet extends StatelessWidget {
  const ScanResultBottomSheet({
    super.key,
    required this.result,
    required this.onScanNext,
  });

  final ScanResultData result;
  final VoidCallback onScanNext;

  static Future<void> show(
    BuildContext context, {
    required ScanResultData result,
    required VoidCallback onScanNext,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScanResultBottomSheet(
        result: result,
        onScanNext: onScanNext,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = result.status;
    final theme = _themeForStatus(status);
    final timeFormat = DateFormat('h:mm:ss a · MMM d');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status Icon Circle
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(theme.icon, size: 44, color: theme.color),
              ),
            ),
            const SizedBox(height: 18),

            // Title & Status Badge
            Center(
              child: Text(
                theme.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  theme.badgeText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Details Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F3FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.attendeeName != null && result.attendeeName!.isNotEmpty) ...[
                    _DetailRow(
                      icon: Icons.person_rounded,
                      label: 'Attendee',
                      value: result.attendeeName!,
                      subValue: result.attendeeEmail,
                    ),
                    const Divider(height: 20),
                  ],
                  if (result.eventTitle != null && result.eventTitle!.isNotEmpty) ...[
                    _DetailRow(
                      icon: Icons.event_rounded,
                      label: 'Event',
                      value: result.eventTitle!,
                    ),
                    const Divider(height: 20),
                  ],
                  if (result.checkedInAt != null) ...[
                    _DetailRow(
                      icon: Icons.access_time_filled_rounded,
                      label: status == ScanStatus.valid ? 'Checked In At' : 'Previous Check-in',
                      value: timeFormat.format(result.checkedInAt!.toLocal()),
                    ),
                  ] else ...[
                    _DetailRow(
                      icon: Icons.info_outline_rounded,
                      label: 'Backend Message',
                      value: result.message.isNotEmpty ? result.message : 'No additional information.',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onScanNext();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Scan Next Pass 📷',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusTheme _themeForStatus(ScanStatus status) {
    switch (status) {
      case ScanStatus.valid:
        return const _StatusTheme(
          color: Color(0xFF00C2A8),
          icon: Icons.check_circle_rounded,
          title: 'Access Granted! 🎉',
          badgeText: 'STATUS: VALID',
        );
      case ScanStatus.alreadyCheckedIn:
        return const _StatusTheme(
          color: Color(0xFFFFA84C),
          icon: Icons.warning_rounded,
          title: 'Already Checked In ⚠️',
          badgeText: 'STATUS: ALREADY CHECKED IN',
        );
      case ScanStatus.invalid:
        return const _StatusTheme(
          color: Color(0xFFFF4D6D),
          icon: Icons.cancel_rounded,
          title: 'Invalid QR Code ❌',
          badgeText: 'STATUS: INVALID',
        );
      case ScanStatus.inactive:
        return const _StatusTheme(
          color: Color(0xFF6C63FF),
          icon: Icons.pause_circle_filled_rounded,
          title: 'Event Inactive ⏸️',
          badgeText: 'STATUS: INACTIVE',
        );
      case ScanStatus.cancelled:
        return const _StatusTheme(
          color: Color(0xFF8E8E93),
          icon: Icons.block_rounded,
          title: 'Pass Cancelled 🚫',
          badgeText: 'STATUS: CANCELLED',
        );
      case ScanStatus.unknown:
        return const _StatusTheme(
          color: Color(0xFF8E8E93),
          icon: Icons.help_rounded,
          title: 'Scan Result',
          badgeText: 'STATUS: UNKNOWN',
        );
    }
  }
}

class _StatusTheme {
  final Color color;
  final IconData icon;
  final String title;
  final String badgeText;

  const _StatusTheme({
    required this.color,
    required this.icon,
    required this.title,
    required this.badgeText,
  });
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF6C63FF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              if (subValue != null && subValue!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subValue!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
