import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthResult {
  final String? token;
  final String? name;
  final String? email;
  final String? phone;

  const AuthResult({this.token, this.name, this.email, this.phone});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return AuthResult(
      token: json['token'] as String?,
      name: user?['name'] as String? ?? json['name'] as String?,
      email: user?['email'] as String? ?? json['email'] as String?,
      phone: user?['phone'] as String? ?? json['phone'] as String?,
    );
  }
}

class AuthRepository {
  static const _baseUrl = 'https://www.countryflour.in/api/mobileapi';

  Future<AuthResult> signInWithGoogle({required String idToken}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Auth failed (${response.statusCode}): ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthResult.fromJson(json);
  }
}
