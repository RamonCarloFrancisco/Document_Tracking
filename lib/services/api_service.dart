//===api_service.dart====
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.1.37/tracker_app';
  static const Duration _timeout = Duration(seconds: 15);

  // Enhanced error handling wrapper
  static Future<T> _handleRequest<T>(
    Future<http.Response> Function() request,
    T Function(Map<String, dynamic>) parser,
  ) async {
    try {
      final response = await request().timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return parser(data);
      } else {
        throw ApiException('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: Unable to connect to server');
    }
  }

  static Future<LoginResult> login(String accessCode) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'access_code': accessCode}),
      ),
      (data) => LoginResult(
        success: data['success'] ?? false,
        message: data['message'] ?? 'Unknown error',
        user: data['user'],
      ),
    );
  }

  static Future<DocumentsResult> getReceivedDocuments(int receiverId) async {
    return _handleRequest(
      () => http.get(
        Uri.parse(
          '$baseUrl/get_received_documents.php?receiver_id=$receiverId',
        ),
      ),
      (data) => DocumentsResult(
        success: data['success'] ?? false,
        message: data['message'] ?? 'Unknown error',
        documents: List<Map<String, dynamic>>.from(data['documents'] ?? []),
      ),
    );
  }

  static Future<UnitsResult> getUnits() async {
    return _handleRequest(
      () => http.get(Uri.parse('$baseUrl/get_units.php')),
      (data) => UnitsResult(
        success: data['success'] ?? false,
        units: List<String>.from(data['units'] ?? []),
      ),
    );
  }

  static Future<UsersResult> getEmployeesByUnit(String unit) async {
    return _handleRequest(
      () => http.get(Uri.parse('$baseUrl/get_users_by_unit.php?unit=$unit')),
      (data) => UsersResult(
        success: data['success'] ?? false,
        message: data['message'] ?? 'Unknown error',
        users: List<Map<String, dynamic>>.from(data['users'] ?? []),
      ),
    );
  }

  static Future<TagDocumentResult> tagDocument({
    required int senderId,
    required String title,
    required String? description,
    required List<int> receiverIds,
  }) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/tag_document.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_id': senderId,
          'title': title,
          'description': description,
          'receiver_ids': receiverIds,
        }),
      ),
      (data) => TagDocumentResult(
        success: data['success'] ?? false,
        message: data['message'] ?? 'Unknown error',
        documentId: data['document_id'],
      ),
    );
  }

  static Future<DocumentRouteResult> getDocumentRoute(
    int documentId,
    int userId,
  ) async {
    return _handleRequest(
      () => http.get(
        Uri.parse(
          '$baseUrl/get_document_route.php?document_id=$documentId&user_id=$userId',
        ),
      ),
      (data) => DocumentRouteResult(
        success: data['success'] ?? false,
        message: data['message'] ?? 'Unknown error',
        route: List<Map<String, dynamic>>.from(data['route'] ?? []),
      ),
    );
  }

  static Future<ForwardDocumentResult> forwardDocument({
    required int documentId,
    required int senderId,
    required List<int> receiverIds,
  }) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/forward_document.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'document_id': documentId,
          'sender_id': senderId,
          'receiver_ids': receiverIds,
        }),
      ),
      (data) => ForwardDocumentResult(
        success: data['success'] ?? false,
        message: data['message'] ?? 'Unknown error',
      ),
    );
  }

  static Future<StatusUpdateResult> updateStatus({
    required int documentId,
    required int receiverId,
    required String status,
  }) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$baseUrl/update_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'document_id': documentId,
          'receiver_id': receiverId,
          'status': status,
        }),
      ),
      (data) => StatusUpdateResult(
        success: data['success'] ?? false,
        message: data['message'] ?? 'Unknown error',
      ),
    );
  }

  static Future<DocumentsResult> searchDocuments({
    required int userId,
    required String query,
    required String type,
  }) async {
    return _handleRequest(
      () => http.get(
        Uri.parse(
          '$baseUrl/search_documents.php?user_id=$userId&query=${Uri.encodeComponent(query)}&type=$type',
        ),
      ),
      (data) => DocumentsResult(
        success: data['success'] ?? false,
        message: data['message'] ?? 'Unknown error',
        documents: List<Map<String, dynamic>>.from(data['documents'] ?? []),
      ),
    );
  }

  static Future<DocumentsResult> getUserDocuments({
    required int userId,
    required String type,
  }) async {
    return _handleRequest(
      () => http.get(
        Uri.parse('$baseUrl/get_user_documents.php?user_id=$userId&type=$type'),
      ),
      (data) => DocumentsResult(
        success: data['success'] ?? false,
        message: data['message'] ?? 'Unknown error',
        documents: List<Map<String, dynamic>>.from(data['documents'] ?? []),
      ),
    );
  }
}

// Result classes for better type safety
class LoginResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? user;

  LoginResult({required this.success, required this.message, this.user});
}

class DocumentsResult {
  final bool success;
  final String message;
  final List<Map<String, dynamic>> documents;

  DocumentsResult({
    required this.success,
    required this.message,
    required this.documents,
  });
}

class UnitsResult {
  final bool success;
  final List<String> units;

  UnitsResult({required this.success, required this.units});
}

class UsersResult {
  final bool success;
  final String message;
  final List<Map<String, dynamic>> users;

  UsersResult({
    required this.success,
    required this.message,
    required this.users,
  });
}

class TagDocumentResult {
  final bool success;
  final String message;
  final int? documentId;

  TagDocumentResult({
    required this.success,
    required this.message,
    this.documentId,
  });
}

class DocumentRouteResult {
  final bool success;
  final String message;
  final List<Map<String, dynamic>> route;

  DocumentRouteResult({
    required this.success,
    required this.message,
    required this.route,
  });
}

class ForwardDocumentResult {
  final bool success;
  final String message;

  ForwardDocumentResult({required this.success, required this.message});
}

class StatusUpdateResult {
  final bool success;
  final String message;

  StatusUpdateResult({required this.success, required this.message});
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
