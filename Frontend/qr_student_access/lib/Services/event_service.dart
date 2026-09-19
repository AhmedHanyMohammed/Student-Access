import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/event.dart';
import '../Models/pass_data.dart';
import 'api_config.dart';
import 'auth_service.dart';

class EventService {
  static final EventService instance = EventService._internal();
  EventService._internal();

  /// Fetches the list of active events from the backend.
  Future<List<EventItem>> getEvents() async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/events');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => EventItem.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load events (status ${response.statusCode})');
    }
  }

  /// Registers the authenticated user for an event and receives the QR pass.
  Future<PassData> registerForEvent(int eventId) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/registrations');
    final headers = await AuthService.instance.getAuthHeaders();

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({'eventId': eventId}),
    );

    final data = _decodeBody(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return PassData.fromJson(data);
    } else {
      final message = data['message'] ?? 'Event registration failed.';
      throw Exception(message);
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
      final data = _decodeBody(response.body);
      throw Exception(data['message'] ?? 'Failed to load pass.');
    }
  }

  /// Retrieves all registrations for the current user.
  Future<List<PassData>> getMyRegistrations() async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/registrations/my');
    final headers = await AuthService.instance.getAuthHeaders();

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => PassData.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load registrations.');
    }
  }

  Map<String, dynamic> _decodeBody(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {'message': body};
    }
  }
}
