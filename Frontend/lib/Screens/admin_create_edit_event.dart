import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Models/event.dart';
import '../Services/event_service.dart';
import '../Widgets/app_text_field.dart';

class AdminCreateEditEventScreen extends StatefulWidget {
  const AdminCreateEditEventScreen({super.key, this.eventToEdit});

  final EventItem? eventToEdit;

  @override
  State<AdminCreateEditEventScreen> createState() =>
      _AdminCreateEditEventScreenState();
}

class _AdminCreateEditEventScreenState
    extends State<AdminCreateEditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditing => widget.eventToEdit != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.eventToEdit?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.eventToEdit?.description ?? '',
    );
    _locationController = TextEditingController(
      text: widget.eventToEdit?.location ?? '',
    );

    if (widget.eventToEdit != null) {
      _selectedDate = widget.eventToEdit!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.eventToEdit!.date);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = _selectedDate.isBefore(today)
        ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
        : today;
    final initialDate = _selectedDate.isBefore(firstDate) ? firstDate : _selectedDate;
    final lastDate = today.add(const Duration(days: 365 * 2));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final now = DateTime.now();
      final isToday = _selectedDate.year == now.year &&
          _selectedDate.month == now.month &&
          _selectedDate.day == now.day;

      if (isToday) {
        final pickedDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
        if (pickedDateTime.isBefore(now)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot select a past time for today. Please pick a future time.'),
                backgroundColor: Color(0xFFFF4D6D),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final fullDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (fullDateTime.isBefore(DateTime.now())) {
      setState(() {
        _errorMessage = 'Event date and time cannot be in the past. Please pick a future date and time.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final EventItem savedEvent;
      if (_isEditing) {
        final idInt = int.tryParse(widget.eventToEdit!.id) ?? 0;
        savedEvent = await EventService.instance.updateEvent(
          idInt,
          title: _titleController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          eventDate: fullDateTime,
          location: _locationController.text,
        );
      } else {
        savedEvent = await EventService.instance.createEvent(
          title: _titleController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          eventDate: fullDateTime,
          location: _locationController.text,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Event updated successfully!'
                : 'Event created successfully!',
          ),
          backgroundColor: const Color(0xFF00C2A8),
        ),
      );
      Navigator.of(context).pop(savedEvent);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final formattedDate = dateFormat.format(_selectedDate);
    final formattedTime = timeFormat.format(
      DateTime(2000, 1, 1, _selectedTime.hour, _selectedTime.minute),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FF),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Event' : 'Create Event',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A2E),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                AppTextField(
                  controller: _titleController,
                  label: 'Event Title',
                  prefixIcon: Icons.title_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Description (Optional)',
                  prefixIcon: Icons.description_outlined,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _locationController,
                  label: 'Location',
                  prefixIcon: Icons.location_on_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Location is required'
                      : null,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Event Schedule',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: Color(0xFF6C63FF),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFF6C63FF),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  formattedTime,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isEditing ? 'Save Changes' : 'Create Event 🚀',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
