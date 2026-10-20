class EventItem {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final String location;
  final bool isActive;
  final String emoji;
  final int? categoryId;
  final String? categoryName;

  const EventItem({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.location,
    this.isActive = true,
    this.emoji = '🎉',
    this.categoryId,
    this.categoryName,
  });

  bool get isPast => DateTime.now().isAfter(date);
  bool get isCurrentlyActive => isActive && !isPast;

  factory EventItem.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? 'Event';
    final dateStr =
        json['eventDate'] as String? ??
        json['date'] as String? ??
        DateTime.now().toIso8601String();

    final parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();

    return EventItem(
      id: json['id'].toString(),
      title: title,
      description: json['description'] as String?,
      date: parsedDate.toLocal(),
      location: json['location'] as String? ?? 'Campus',
      isActive: json['isActive'] as bool? ?? true,
      emoji: _deriveEmoji(title),
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
    );
  }

  static String _deriveEmoji(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('tech') ||
        lower.contains('code') ||
        lower.contains('hack')) {
      return '💻';
    }
    if (lower.contains('ai') ||
        lower.contains('workshop') ||
        lower.contains('data')) {
      return '🤖';
    }
    if (lower.contains('fest') ||
        lower.contains('party') ||
        lower.contains('celebrat')) {
      return '🎊';
    }
    if (lower.contains('music') || lower.contains('concert')) {
      return '🎵';
    }
    if (lower.contains('sport') ||
        lower.contains('arena') ||
        lower.contains('game')) {
      return '🏆';
    }
    if (lower.contains('career') ||
        lower.contains('fair') ||
        lower.contains('job')) {
      return '💼';
    }
    return '🚀';
  }
}
