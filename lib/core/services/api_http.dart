import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiHttp {
  static const webProxyBase = String.fromEnvironment(
    'JEJUFLOW_API_PROXY',
    defaultValue: 'http://127.0.0.1:8787/',
  );

  static Future<Response<dynamic>> getUri(
    Dio dio,
    Uri uri, {
    bool useWebProxy = true,
  }) {
    if (kIsWeb && useWebProxy) {
      return dio.getUri<dynamic>(
        Uri.parse(webProxyBase).replace(
          queryParameters: {'url': uri.toString()},
        ),
      );
    }
    return dio.getUri<dynamic>(uri);
  }
}
