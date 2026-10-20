import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Models/event.dart';
import '../Models/pass_data.dart';
import '../Services/event_service.dart';
import 'admin_create_edit_event.dart';

class AdminEventDetailsScreen extends StatefulWidget {
  const AdminEventDetailsScreen({super.key, required this.event});

  final EventItem event;

  @override
  State<AdminEventDetailsScreen> createState() =>
      _AdminEventDetailsScreenState();
}

class _AdminEventDetailsScreenState extends State<AdminEventDetailsScreen> {
  late EventItem _event;
  List<PassData> _registrations = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    final eventIdInt = int.tryParse(_event.id) ?? 0;
    if (eventIdInt > 0) {
      try {
        final updated = await EventService.instance.getEventById(eventIdInt);
        if (updated != null && mounted) {
          setState(() {
            _event = updated;
          });
        }
      } catch (_) {}
    }
    await _loadRegistrations();
  }

  Future<void> _loadRegistrations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final eventIdInt = int.tryParse(_event.id) ?? 0;

    try {
      final list = await EventService.instance.getEventRegistrations(
        eventIdInt,
      );
      if (!mounted) return;
      setState(() {
        _registrations = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Event',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to delete "${_event.title}"? All student registrations for this event will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D6D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final idInt = int.tryParse(_event.id) ?? 0;
      try {
        await EventService.instance.deleteEvent(idInt);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted successfully.')),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _removeStudentRegistration(PassData pass) async {
    final name = pass.attendeeName ?? 'Attendee';
    final email = pass.attendeeEmail ?? '';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Student Registration',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Remove registration for $name ${email.isNotEmpty ? "($email)" : ""}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D6D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await EventService.instance.removeRegistration(pass.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration for $name removed.')),
        );
        _loadRegistrations();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy · h:mm a');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_hasChanged);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F3FF),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(_hasChanged),
          ),
          title: const Text(
            'Event Dashboard',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xFF1A1A2E),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Color(0xFF6C63FF)),
              tooltip: 'Edit Event',
              onPressed: () async {
                final result = await Navigator.of(context).push<dynamic>(
                  MaterialPageRoute(
                    builder: (_) =>
                        AdminCreateEditEventScreen(eventToEdit: _event),
                  ),
                );
                if (result != null) {
                  _hasChanged = true;
                  if (result is EventItem) {
                    setState(() {
                      _event = result;
                    });
                    _loadRegistrations();
                  } else {
                    _refreshAll();
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFFF4D6D),
              ),
              tooltip: 'Delete Event',
              onPressed: _deleteEvent,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshAll,
          color: const Color(0xFF6C63FF),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _event.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _event.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_event.description != null &&
                        _event.description!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        _event.description!,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 16,
                          color: Color(0xFF6C63FF),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dateFormat.format(_event.date),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: Color(0xFF6C63FF),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _event.location,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Registrations Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Registered Students',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_registrations.length} Total',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  ),
                )
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                )
              else if (_registrations.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No students registered yet for this event.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _registrations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final pass = _registrations[index];
                    final isCheckedIn =
                        pass.status.toLowerCase() == 'checkedin';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.04),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isCheckedIn
                                ? const Color(0xFF00C2A8).withOpacity(0.15)
                                : const Color(0xFF6C63FF).withOpacity(0.15),
                            child: Icon(
                              isCheckedIn
                                  ? Icons.check_circle_rounded
                                  : Icons.person_outline_rounded,
                              color: isCheckedIn
                                  ? const Color(0xFF00C2A8)
                                  : const Color(0xFF6C63FF),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pass.attendeeName ?? 'Attendee',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pass.attendeeEmail ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCheckedIn
                                            ? Colors.green.shade50
                                            : Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isCheckedIn
                                            ? 'Checked-In'
                                            : 'Registered',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: isCheckedIn
                                              ? Colors.green.shade700
                                              : Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline_rounded,
                              color: Color(0xFFFF4D6D),
                              size: 22,
                            ),
                            tooltip: 'Cancel Registration',
                            onPressed: () => _removeStudentRegistration(pass),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
