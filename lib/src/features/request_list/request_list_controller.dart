import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/network_request.dart';

class RequestListController {
  static const _ignoredHeaders = {
    'content-length',
    'host',
    'connection',
    'accept-encoding',
  };

  String generateCurl(NetworkRequest req) {
    final method = req.method.trim().toUpperCase();
    final parts = <String>['curl ${_shellQuote(req.url)}'];

    final hasBody = req.requestData != null;
    final isGet = method.isEmpty || method == 'GET';

    if (!isGet || hasBody) {
      parts.add('-X ${method.isEmpty ? 'GET' : method}');
    }

    final isFormData = req.requestData is FormData;
    var hasExplicitContentType = false;

    if (req.requestHeaders != null) {
      req.requestHeaders!.forEach((key, value) {
        if (value == null) return;
        final lowerKey = key.toLowerCase();
        if (_ignoredHeaders.contains(lowerKey)) return;

        final stringValue = value.toString();
        if (lowerKey == 'content-type') {
          hasExplicitContentType = true;
          // If sending FormData, omit multipart/form-data content-type so curl sets the boundary automatically
          if (isFormData &&
              stringValue.toLowerCase().contains('multipart/form-data')) {
            return;
          }
        }

        if (value is Iterable) {
          for (final item in value) {
            if (item != null) {
              parts.add('-H ${_shellQuote('$key: $item')}');
            }
          }
        } else {
          parts.add('-H ${_shellQuote('$key: $stringValue')}');
        }
      });
    }

    final data = req.requestData;
    if (data is FormData) {
      for (final field in data.fields) {
        parts.add('-F ${_shellQuote('${field.key}=${field.value}')}');
      }
      for (final file in data.files) {
        final filename = file.value.filename ?? 'file';
        parts.add('-F ${_shellQuote('${file.key}=@$filename')}');
      }
    } else if (data != null) {
      if (!hasExplicitContentType && (data is Map || data is List)) {
        parts.add('-H ${_shellQuote('content-type: application/json')}');
      }
      final dataString = data is Map || data is List
          ? jsonEncode(data)
          : data.toString();
      parts.add('-d ${_shellQuote(dataString)}');
    }

    if (parts.length == 1) {
      return parts.first;
    }

    return parts.join(' \\\n  ');
  }

  String _shellQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";

  void handleCopyCurl(BuildContext context, NetworkRequest req) {
    final curl = generateCurl(req);
    Clipboard.setData(ClipboardData(text: curl));
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Copied as cURL'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
