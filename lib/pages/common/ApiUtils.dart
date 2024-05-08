import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:http_interceptor/http/intercepted_client.dart';


class ApiUtils {
  ApiUtils._();

  static final instance = ApiUtils._();
  final client = InterceptedClient.build(
    interceptors: [],
  );

  Future<http.Response> post(String url, Map<String, dynamic> body, bool? withHeader) async {
    String jsonBody = json.encode(body);
    return await client.post(Uri.parse(url), body: jsonBody);
  }


  Future<http.Response> put(String url, Map<String, dynamic> body) async {
    String jsonBody = json.encode(body);
    return await client.put(Uri.parse(url), body: jsonBody);
  }

  Future<http.Response> getWithHeader(String url, Map<String, String>? headers) async {
    print("get call with header ==> ");
    print(url);
    print(headers);
    return await client.get(Uri.parse(url), headers: headers);
  }

  Future<http.Response> get(String url) async {
    print("get call ==> " );
    print(url);
    return await client.get(Uri.parse(url));
  }

}
