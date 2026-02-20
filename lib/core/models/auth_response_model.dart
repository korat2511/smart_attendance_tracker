import 'user_model.dart';

class AuthResponseModel {
  final bool success;
  final String message;
  final UserModel? user;
  final String? token;
  final String? tokenType;

  AuthResponseModel({
    required this.success,
    required this.message,
    this.user,
    this.token,
    this.tokenType,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      user: json['data'] != null && json['data']['user'] != null
          ? UserModel.fromJson(json['data']['user'] as Map<String, dynamic>)
          : null,
      token: json['data'] != null ? json['data']['token'] as String? : null,
      tokenType: json['data'] != null ? json['data']['token_type'] as String? : null,
    );
  }
}
