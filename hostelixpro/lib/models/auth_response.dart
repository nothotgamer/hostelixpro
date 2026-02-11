// Authentication response models
class LoginResponse {
  final String txId;
  final bool otpSent;
  final String message;
  final int? expiryMs;
  
  LoginResponse({
    required this.txId,
    required this.otpSent,
    required this.message,
    this.expiryMs,
  });
  
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      txId: json['tx_id'],
      otpSent: json['otp_sent'] ?? false,
      message: json['message'] ?? '',
      expiryMs: json['expiry_ms'],
    );
  }
}

class OtpVerifyResponse {
  final String token;
  final int expiresAt;
  final Map<String, dynamic> user;
  
  OtpVerifyResponse({
    required this.token,
    required this.expiresAt,
    required this.user,
  });
  
  factory OtpVerifyResponse.fromJson(Map<String, dynamic> json) {
    return OtpVerifyResponse(
      token: json['token'],
      expiresAt: json['expires_at'],
      user: json['user'],
    );
  }
}
