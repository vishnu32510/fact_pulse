import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

enum ServiceError {
  unknownError,
  unknownResponseError,
  clientError,
  serverError,
  timeoutError,
  socketError
}

abstract class Services {}

class OpenLinkService extends Services {
  void openUrl({required String link}) async {
    if (!await launchUrl(Uri.parse(link))) {
      throw Exception('Could not launch $link');
    }
  }
}

class HttpServices extends Services {
  Future postMethod(String url, var body) async {
    var bo = convert.jsonEncode(body);
    try {
      var data = await http.post(Uri.parse(url),
          body: bo,
          headers: <String, String>{
            // 'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=UTF-8'
          }).timeout(const Duration(seconds: 20));
      debugPrint(data.body);
      if (data.statusCode == 200 || data.statusCode == 201) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response.toString());
        return response;
      } else if (data.statusCode == 400 || data.statusCode == 404) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response);
        return ServiceError.clientError;
      } else if (data.statusCode == 500) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response);
        return ServiceError.serverError;
      } else {
        return ServiceError.unknownResponseError;
      }
    } on TimeoutException catch (_) {
      return ServiceError.timeoutError;
    } on SocketException catch (_) {
      return ServiceError.socketError;
    } on Exception catch (_) {
      return ServiceError.unknownError;
    }
  }

  Future putMethod(String url, var body) async {
    try {
      var data = await http.put(Uri.parse(url), body: body, headers: <String, String>{
        // 'Authorization': 'Bearer $token',
        // 'Content-Type': 'application/json; charset=UTF-8'
      }).timeout(const Duration(seconds: 20));
      debugPrint(data.body);
      if (data.statusCode == 200) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response);
        return response;
      } else if (data.statusCode == 400 || data.statusCode == 404) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response);
        return ServiceError.clientError;
      } else if (data.statusCode == 500) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response);
        return ServiceError.serverError;
      } else {
        return ServiceError.unknownResponseError;
      }
    } on TimeoutException catch (_) {
      return ServiceError.timeoutError;
    } on SocketException catch (_) {
      return ServiceError.socketError;
    } on Exception catch (_) {
      return ServiceError.unknownError;
    }
  }

  Future deleteMethod(String url) async {
    try {
      var data = await http.delete(Uri.parse(url), headers: <String, String>{
        // 'Authorization': 'Bearer $token',
        // 'Content-Type': 'application/json; charset=UTF-8'
      }).timeout(const Duration(seconds: 20));
      debugPrint(data.body);
      if (data.statusCode == 200 || data.statusCode == 204) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response.toString());
        return response;
      } else if (data.statusCode == 400 || data.statusCode == 404) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response);
        return ServiceError.clientError;
      } else if (data.statusCode == 500) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response);
        return ServiceError.serverError;
      } else {
        return ServiceError.unknownResponseError;
      }
    } on TimeoutException catch (_) {
      return ServiceError.timeoutError;
    } on SocketException catch (_) {
      return ServiceError.socketError;
    } on Exception catch (_) {
      return ServiceError.unknownError;
    }
  }

  Future getMethod(String url) async {
    try {
      var data = await http.get(Uri.parse(url), headers: <String, String>{
        // 'Authorization': 'Bearer $token',
        // 'Content-Type': 'application/json; charset=UTF-8'
      }).timeout(const Duration(seconds: 20));
      debugPrint(data.body);
      if (data.statusCode == 200) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response.toString());
        return response;
      } else if (data.statusCode == 400 || data.statusCode == 404) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response);
        return ServiceError.clientError;
      } else if (data.statusCode == 500) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response);
        return ServiceError.serverError;
      } else {
        return ServiceError.unknownResponseError;
      }
    } on TimeoutException catch (_) {
      return ServiceError.timeoutError;
    } on SocketException catch (_) {
      return ServiceError.socketError;
    } on Exception catch (_) {
      return ServiceError.unknownError;
    }
  }
}
