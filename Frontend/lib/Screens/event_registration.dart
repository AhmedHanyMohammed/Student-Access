import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../Models/event.dart';
import '../Models/pass_data.dart';
import '../Services/event_service.dart';
import 'my_pass.dart';

class EventRegistrationScreen extends StatefulWidget {
  const EventRegistrationScreen({super.key, required this.event});

  final EventItem event;

  @override
  State<EventRegistrationScreen> createState() =>
      _EventRegistrationScreenState();
}

class _EventRegistrationScreenState extends State<EventRegistrationScreen> {
  bool _isRegistering = false;
  bool _isRegistered = false;
  String? _errorMessage;
  PassData? _passData;

  static const _accent = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _checkExistingRegistration();
  }

  Future<void> _checkExistingRegistration() async {
    try {
      final eventId = int.tryParse(widget.event.id);
      if (eventId != null) {
        final existingPass = await EventService.instance.getMyPass(eventId: eventId);
        if (existingPass != null && mounted) {
          setState(() {
            _isRegistered = true;
            _passData = existingPass;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _register() async {
    setState(() {
      _isRegistering = true;
      _errorMessage = null;
    });

    try {
      final eventId = int.parse(widget.event.id);
      final pass = await EventService.instance.registerForEvent(eventId);

      if (!mounted) return;
      setState(() {
        _isRegistering = false;
        _isRegistered = true;
        _passData = pass;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRegistering = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _EventHeaderCard(
                event: event,
                dateFormat: dateFormat,
                timeFormat: timeFormat,
              ),
              const SizedBox(height: 24),
              if (!_isRegistered) ...[
                const Text(
                  'Secure your spot',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Register now and we\'ll generate a unique QR pass '
                  'you can show at check-in.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(message: _errorMessage!),
                  if (_errorMessage!.toLowerCase().contains('already')) ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MyQrPassScreen(eventId: int.tryParse(widget.event.id)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C2A8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('View My Existing Pass 🎟️'),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isRegistering || widget.event.isPast) ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.event.isPast ? Colors.grey[400] : _accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isRegistering
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.event.isPast ? 'Event Has Ended ⌛' : 'Register Me 🚀',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ] else if (_passData != null)
                _QrPassCard(pass: _passData!),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventHeaderCard extends StatelessWidget {
  const _EventHeaderCard({
    required this.event,
    required this.dateFormat,
    required this.timeFormat,
  });

  final EventItem event;
  final DateFormat dateFormat;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF9089FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              event.description!,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.white.withOpacity(0.9),
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            text: dateFormat.format(event.date),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.schedule_rounded,
            text: timeFormat.format(event.date),
          ),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.location_on_rounded, text: event.location),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.9)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _QrPassCard extends StatelessWidget {
  const _QrPassCard({required this.pass});

  final PassData pass;

  void _copyToken(BuildContext context) {
    Clipboard.setData(ClipboardData(text: pass.qrToken));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Token copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF00C2A8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "You're in! 🎊",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Show this QR code at check-in. Screenshot it or keep it handy in the app.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDED8F7), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: pass.qrToken.isNotEmpty
                      ? pass.qrToken
                      : 'EVENTPASS-${pass.id}-${pass.eventId}',
                  version: QrVersions.auto,
                  size: 210,
                  padding: const EdgeInsets.all(6),
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: Color(0xFF6C63FF),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _copyToken(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F3FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDED8F7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_2_rounded, size: 18, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pass.qrToken.isNotEmpty
                              ? pass.qrToken
                              : 'EVENTPASS-${pass.id}-${pass.eventId}',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy_rounded, size: 15, color: Color(0xFF6C63FF)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MyQrPassScreen(initialPass: pass),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.confirmation_number_outlined, size: 18),
            label: const Text(
              'Open in My QR Pass 🎟️',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6C63FF),
              side: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text(
              'Back to Events',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: const Color(0xFF1A1A2E)),
        ),
      ),
    );
  }
}
