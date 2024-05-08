class ApiConstants {
  static const String baseIp = 'http://192.168.18.6:3000';

  static const String baseUrl = '${ApiConstants.baseIp}/user_service';
  static const String serviceHubBaseUrl = '${ApiConstants.baseIp}/service_hub';
  static const String loginEndpoint = '${ApiConstants.baseUrl}/login';
  static const String signUpEndpoint = '${ApiConstants.baseUrl}/signup';

}
