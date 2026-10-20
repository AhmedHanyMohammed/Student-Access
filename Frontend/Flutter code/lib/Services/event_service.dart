import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/event.dart';
import '../Models/pass_data.dart';
import 'api_config.dart';
import 'auth_service.dart';

class EventService {
  static final EventService instance = EventService._internal();
  EventService._internal();

  /// Fetches the list of active events from the backend, optionally filtered by category.
  Future<List<EventItem>> getEvents({int? categoryId}) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final url = categoryId != null && categoryId > 0
        ? '$baseUrl/api/events?categoryId=$categoryId'
        : '$baseUrl/api/events';
    final uri = Uri.parse(url);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => EventItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load events (status ${response.statusCode})');
    }
  }

  /// Fetches an event by its ID.
  Future<EventItem?> getEventById(int id) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/events/$id');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = _decodeBody(response.body);
      return EventItem.fromJson(data);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load event details (status ${response.statusCode})');
    }
  }

  /// Registers the authenticated user for an event and receives the QR pass.
  Future<PassData> registerForEvent(int eventId) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/registrations/join');
    final headers = await AuthService.instance.getAuthHeaders();

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({'eventId': eventId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = _decodeBody(response.body);
      return PassData.fromJson(data);
    } else {
      final message = _extractErrorMessage(response.body, response.statusCode);
      throw Exception(message);
    }
  }

  /// Admin: Creates a new event.
  Future<EventItem> createEvent({
    required String title,
    String? description,
    required DateTime eventDate,
    required String location,
  }) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/events');
    final headers = await AuthService.instance.getAuthHeaders();

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'title': title.trim(),
        'description': description?.trim(),
        'eventDate': eventDate.toUtc().toIso8601String(),
        'location': location.trim(),
      }),
    );

    if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please log out and sign in again.');
    }
    if (response.statusCode == 403) {
      throw Exception(
        'Forbidden. Admin access required. Please sign in with an Admin account.',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = _decodeBody(response.body);
      return EventItem.fromJson(data);
    } else {
      throw Exception(_extractErrorMessage(response.body, response.statusCode));
    }
  }

  /// Admin: Updates an existing event.
  Future<EventItem> updateEvent(
    int id, {
    required String title,
    String? description,
    required DateTime eventDate,
    required String location,
  }) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/events/$id');
    final headers = await AuthService.instance.getAuthHeaders();

    final response = await http.put(
      uri,
      headers: headers,
      body: jsonEncode({
        'title': title.trim(),
        'description': description?.trim(),
        'eventDate': eventDate.toUtc().toIso8601String(),
        'location': location.trim(),
      }),
    );

    if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please log out and sign in again.');
    }
    if (response.statusCode == 403) {
      throw Exception(
        'Forbidden. Admin access required. Please sign in with an Admin account.',
      );
    }

    if (response.statusCode == 200) {
      final data = _decodeBody(response.body);
      return EventItem.fromJson(data);
    } else {
      throw Exception(_extractErrorMessage(response.body, response.statusCode));
    }
  }

  /// Admin: Deletes an event.
  Future<void> deleteEvent(int id) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/events/$id');
    final headers = await AuthService.instance.getAuthHeaders();

    final response = await http.delete(uri, headers: headers);

    if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please log out and sign in again.');
    }
    if (response.statusCode == 403) {
      throw Exception(
        'Forbidden. Admin access required. Please sign in with an Admin account.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response.body, response.statusCode));
    }
  }

  /// Admin: Fetches list of all student registrations for a specific event.
  Future<List<PassData>> getEventRegistrations(int eventId) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/events/$eventId/registrations');
    final headers = await AuthService.instance.getAuthHeaders();

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please log out and sign in again.');
    }
    if (response.statusCode == 403) {
      throw Exception(
        'Forbidden. Admin access required. Please sign in with an Admin account.',
      );
    }

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => PassData.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(_extractErrorMessage(response.body, response.statusCode));
    }
  }

  /// Admin: Removes a student's registration from an event.
  Future<void> removeRegistration(int registrationId) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/registrations/$registrationId');
    final headers = await AuthService.instance.getAuthHeaders();

    final response = await http.delete(uri, headers: headers);

    if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please log out and sign in again.');
    }
    if (response.statusCode == 403) {
      throw Exception(
        'Forbidden. Admin access required. Please sign in with an Admin account.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response.body, response.statusCode));
    }
  }

  /// Retrieves the current QR pass for the authenticated user.
  Future<PassData?> getMyPass({int? eventId}) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final query = eventId != null ? '?eventId=$eventId' : '';
    final uri = Uri.parse('$baseUrl/api/registrations/my-pass$query');
    final headers = await AuthService.instance.getAuthHeaders();

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = _decodeBody(response.body);
      return PassData.fromJson(data);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception(_extractErrorMessage(response.body, response.statusCode));
    }
  }

  /// Retrieves all registrations for the current user.
  Future<List<PassData>> getMyRegistrations() async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/registrations/my-list');
    final headers = await AuthService.instance.getAuthHeaders();

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => PassData.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load registrations.');
    }
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'message': body};
    } catch (_) {
      return {'message': body};
    }
  }

  String _extractErrorMessage(String body, int statusCode) {
    if (body.trim().isEmpty) return 'Request failed (HTTP $statusCode).';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('errors') && decoded['errors'] is Map) {
          final errorsMap = decoded['errors'] as Map;
          final messages = <String>[];
          for (var entry in errorsMap.entries) {
            if (entry.value is List) {
              messages.add((entry.value as List).join(', '));
            } else {
              messages.add(entry.value.toString());
            }
          }
          if (messages.isNotEmpty) {
            return messages.join('; ');
          }
        }
        final msg = decoded['message'] ?? decoded['title'] ?? decoded['detail'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString();
        }
      }
      return body;
    } catch (_) {
      return body;
    }
  }
}
