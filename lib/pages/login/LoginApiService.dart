import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:node_auth/pages/firstpage.dart';

import '../common/ApiUtils.dart';
import '../const/ApiConstants.dart';
import 'User.dart';

class LoginApiService {
  static var userId = '';

  Future<LoginResponse> doLogin(String email, String password) async {
    try {
      final LoginRequest req = LoginRequest(email: email, password: password);
      final http.Response response = await ApiUtils.instance
          .post(ApiConstants.loginEndpoint, req.toJson(), false);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        var result = LoginResponse.fromJson(json.decode(response.body));

        return LoginResponse.fromJson(json.decode(response.body));
      } else {
        print(response.statusCode);
        return Future.error("Error response from api");
      }
    } catch (e) {
      return Future.error("Error occurred while performing login api $e");
    }
  }


  void navigateDashboardPage(BuildContext context) async {
    await Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => CropDetailsPage()));
  }

}
