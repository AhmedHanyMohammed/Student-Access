import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Models/event.dart';
import '../Models/user.dart';
import '../Services/api_config.dart';
import '../Services/auth_service.dart';
import '../Services/event_service.dart';
import 'admin_create_edit_event.dart';
import 'admin_event_details.dart';
import 'event_registration.dart';
import 'login.dart';
import 'my_pass.dart';
import 'scanner.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  static const routeName = '/events';

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<EventItem> _events = [];
  UserProfile? _currentUser;
  int _adminFilterIndex = 0; // 0 = All, 1 = Upcoming, 2 = Past

  @override
  void initState() {
    super.initState();
    _loadUserAndEvents();
  }

  Future<void> _loadUserAndEvents() async {
    final user = await AuthService.instance.getUser();
    if (mounted) {
      setState(() => _currentUser = user);
    }
    await _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _currentUser ?? await AuthService.instance.getUser();
      final categoryFilter = (user != null && !user.isSuperAdmin && user.isAdmin)
          ? user.assignedCategoryId
          : null;
      final events = await EventService.instance.getEvents(
        categoryId: categoryFilter,
      );
      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Could not load events: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Are you sure you want to sign out of EventPass?'),
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
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _showConfigServerDialog() async {
    final currentUrl = await ApiConfig.getBaseUrl();
    final textController = TextEditingController(text: currentUrl);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.settings_ethernet_rounded, color: Color(0xFF6C63FF)),
            SizedBox(width: 10),
            Text(
              'Backend Server IP',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set the host URL of your .NET backend:',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'https://student-access-b0j9.onrender.com',
                filled: true,
                fillColor: const Color(0xFFF6F3FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFECE7FF)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ApiConfig.setCustomBaseUrl(null);
              if (ctx.mounted) Navigator.of(ctx).pop();
              _loadEvents();
            },
            child: const Text(
              'Reset Default',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiConfig.setCustomBaseUrl(textController.text.trim());
              if (ctx.mounted) Navigator.of(ctx).pop();
              _loadEvents();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save & Reload'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, int count) {
    final isSelected = _adminFilterIndex == index;
    return InkWell(
      onTap: () => setState(() => _adminFilterIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6C63FF)
                : Colors.black.withOpacity(0.08),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _currentUser?.fullName.split(' ').first ?? 'there';
    final isAdmin = _currentUser?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FF),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminCreateEditEventScreen(),
                  ),
                );
                if (result != null) {
                  _loadEvents();
                }
              },
              backgroundColor: const Color(0xFF6C63FF),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Create Event',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEvents,
          color: const Color(0xFF6C63FF),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row with User Name and Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isAdmin
                                        ? [
                                            const Color(0xFFFF6B8A),
                                            const Color(0xFFFF8FA3),
                                          ]
                                        : [
                                            const Color(0xFF6C63FF),
                                            const Color(0xFF9089FF),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  firstName.isNotEmpty
                                      ? firstName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Hey, $firstName 👋',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isAdmin
                                              ? const Color(0xFFFF6B8A)
                                              : const Color(0xFF6C63FF),
                                        ),
                                      ),
                                      if (isAdmin) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFFF6B8A,
                                            ).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(_currentUser?.isSuperAdmin == true ? 'SUPERADMIN' : (_currentUser?.assignedCategoryName?.toUpperCase() ?? 'ADMIN'),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFFF6B8A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    _currentUser?.email ?? 'Member',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _HeaderIconButton(
                                icon: Icons.settings_ethernet_rounded,
                                tooltip: 'Configure Server IP',
                                onTap: _showConfigServerDialog,
                              ),
                              const SizedBox(width: 8),
                              _HeaderIconButton(
                                icon: Icons.logout_rounded,
                                tooltip: 'Log Out',
                                iconColor: const Color(0xFFFF4D6D),
                                onTap: _logout,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Large Title
                      Text(
                        isAdmin
                            ? "Campus Event\nManagement"
                            : "What's happening\non campus",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Quick Action Launchers (Admin vs Student)
                      if (isAdmin)
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                title: 'New Event',
                                subtitle: 'Publish campus event',
                                icon: Icons.add_circle_outline_rounded,
                                gradient: const [
                                  Color(0xFF6C63FF),
                                  Color(0xFF8B82FF),
                                ],
                                onTap: () async {
                                  final result = await Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const AdminCreateEditEventScreen(),
                                        ),
                                      );
                                  if (result != null) {
                                    _loadEvents();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                title: 'Gate Scanner',
                                subtitle: 'Admin check-in',
                                icon: Icons.camera_alt_rounded,
                                gradient: const [
                                  Color(0xFF00C2A8),
                                  Color(0xFF26E0C7),
                                ],
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ScannerScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                title: 'My QR Pass',
                                subtitle: 'Show entry code',
                                icon: Icons.qr_code_2_rounded,
                                gradient: const [
                                  Color(0xFF6C63FF),
                                  Color(0xFF8B82FF),
                                ],
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const MyQrPassScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 22),

                      // Section Title & Admin Filter Chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAdmin ? 'Campus Events' : 'Featured Events',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            _isLoading
                                ? 'Loading...'
                                : '${(isAdmin ? _events : _events.where((e) => !e.isPast)).length} total',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(0, 'All', _events.length),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                1,
                                'Upcoming',
                                _events.where((e) => !e.isPast).length,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                2,
                                'Past',
                                _events.where((e) => e.isPast).length,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Content List or Empty/Error State
              if (_isLoading && _events.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  ),
                )
              else if (_errorMessage != null && _events.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MessageState(
                    icon: Icons.wifi_off_rounded,
                    message: _errorMessage!,
                    onRetry: _loadEvents,
                  ),
                )
              else
                Builder(
                  builder: (context) {
                    final upcoming = _events.where((e) => !e.isPast).toList();
                    final past = _events.where((e) => e.isPast).toList();

                    if (!isAdmin) {
                      if (upcoming.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _MessageState(
                            icon: Icons.event_busy_rounded,
                            message:
                                'No active upcoming events right now.\nPull down to check back soon!',
                          ),
                        );
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _EventCard(
                                event: upcoming[index],
                                isAdmin: false,
                                onRefresh: _loadEvents,
                              ),
                            );
                          }, childCount: upcoming.length),
                        ),
                      );
                    }

                    // Admin view based on _adminFilterIndex
                    if (_adminFilterIndex == 1) {
                      if (upcoming.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _MessageState(
                            icon: Icons.event_available_rounded,
                            message: 'No upcoming events currently scheduled.',
                          ),
                        );
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _EventCard(
                                event: upcoming[index],
                                isAdmin: true,
                                onRefresh: _loadEvents,
                              ),
                            );
                          }, childCount: upcoming.length),
                        ),
                      );
                    } else if (_adminFilterIndex == 2) {
                      if (past.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _MessageState(
                            icon: Icons.history_rounded,
                            message: 'No past events found in the system.',
                          ),
                        );
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _EventCard(
                                event: past[index],
                                isAdmin: true,
                                onRefresh: _loadEvents,
                              ),
                            );
                          }, childCount: past.length),
                        ),
                      );
                    }

                    // _adminFilterIndex == 0 (All with visible splitter)
                    if (_events.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _MessageState(
                          icon: Icons.event_busy_rounded,
                          message: 'No events found in the database.',
                        ),
                      );
                    }

                    final showSplitter = upcoming.isNotEmpty && past.isNotEmpty;
                    final totalCount = showSplitter
                        ? upcoming.length + 1 + past.length
                        : (upcoming.isNotEmpty ? upcoming.length : past.length);

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          if (!showSplitter) {
                            final list = upcoming.isNotEmpty ? upcoming : past;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _EventCard(
                                event: list[index],
                                isAdmin: true,
                                onRefresh: _loadEvents,
                              ),
                            );
                          }

                          if (index < upcoming.length) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _EventCard(
                                event: upcoming[index],
                                isAdmin: true,
                                onRefresh: _loadEvents,
                              ),
                            );
                          } else if (index == upcoming.length) {
                            // Visible Splitter between active and past events
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Divider(
                                      color: Color(0xFFDED8F7),
                                      thickness: 1.5,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECE7FF),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFF6C63FF).withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.history_rounded,
                                            size: 15,
                                            color: Color(0xFF6C63FF),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'PAST EVENTS (${past.length})',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF6C63FF),
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(
                                      color: Color(0xFFDED8F7),
                                      thickness: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            final pastIndex = index - upcoming.length - 1;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _EventCard(
                                event: past[pastIndex],
                                isAdmin: true,
                                onRefresh: _loadEvents,
                              ),
                            );
                          }
                        }, childCount: totalCount),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.iconColor = const Color(0xFF1A1A2E),
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, this.isAdmin = false, this.onRefresh});

  final EventItem event;
  final bool isAdmin;
  final VoidCallback? onRefresh;

  static const _accentColors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6B8A),
    Color(0xFF00C2A8),
    Color(0xFFFFA84C),
  ];

  Color _accentFor(String id) {
    final hash = id.codeUnits.fold<int>(0, (a, b) => a + b);
    return _accentColors[hash % _accentColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(event.id);
    final dateFormat = DateFormat('EEE, MMM d · h:mm a');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          if (isAdmin) {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdminEventDetailsScreen(event: event),
              ),
            );
            if (result == true && onRefresh != null) {
              onRefresh!();
            }
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EventRegistrationScreen(event: event),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(event.emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: event.isPast ? Colors.grey[700] : const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        if (event.isPast) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'PAST',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 5),
                        Text(
                          dateFormat.format(event.date),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            event.location,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
