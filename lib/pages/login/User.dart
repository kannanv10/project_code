class LoginRequest {
  String email;
  String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {"email": email, "password": password};
}

class LoginResponse {
  String accessToken;
  String tokenType;

  LoginResponse({required this.accessToken, required this.tokenType});

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        accessToken: json["accessToken"],
        tokenType: json["tokenType"],
      );
}

class SignUpResponse {
  bool success;
  String message;

  SignUpResponse({required this.success, required this.message});

  factory SignUpResponse.fromJson(Map<String, dynamic> json) => SignUpResponse(
        success: json["success"],
        message: json["message"],
      );
}

class SignUpRequest {
  String email;
  String password;
  String name;
  bool vendor;
  String phonenumber;
  String confirmpassword;
  String provider;
  bool isEmailVerified;
  late String providerId;
  late String imageUrl;
  late bool isPhoneVerified;

  SignUpRequest(
      {required this.email,
      required this.password,
      required this.name,
      required this.vendor,
      required this.phonenumber,
      required this.confirmpassword,
      required this.provider,
      required this.isEmailVerified});

  Map<String, dynamic> toJson() => {
        "email": email,
        "password": password,
        "confirmpassword": confirmpassword,
        "name": name,
        "phoneNumber": phonenumber,
        "vendor": vendor,
        "provider": provider,
        "isEmailVerified": isEmailVerified
      };
}
