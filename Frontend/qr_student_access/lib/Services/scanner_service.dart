import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/scan_result_data.dart';
import 'api_config.dart';
import 'auth_service.dart';

class ScannerService {
  static final ScannerService instance = ScannerService._internal();
  ScannerService._internal();

  /// Submits a scanned QR token to the backend for validation and check-in.
  Future<ScanResultData> scanToken({
    required String qrToken,
    String? scannedBy,
  }) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/scanner/scan');
    final headers = await AuthService.instance.getAuthHeaders();

    final user = await AuthService.instance.getUser();
    final effectiveScanner = scannedBy ?? (user != null ? '${user.fullName} (Admin)' : 'Gate Scanner');

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'qrToken': qrToken.trim(),
        'scannedBy': effectiveScanner,
      }),
    );

    final data = _decodeBody(response.body);

    if (response.statusCode == 200 || response.statusCode == 400 || response.statusCode == 404) {
      return ScanResultData.fromJson(data);
    } else {
      return ScanResultData(
        success: false,
        rawStatus: 'invalid',
        result: 'Invalid',
        message: data['message'] ?? 'Scanner service error (status ${response.statusCode})',
      );
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
