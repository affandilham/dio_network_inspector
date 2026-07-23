import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/network_request.dart';

class RequestListController {
  String generateCurl(NetworkRequest req) {
    final buffer = StringBuffer(
      'curl -X ${req.method} ${_shellQuote(req.url)}',
    );
    if (req.requestHeaders != null) {
      req.requestHeaders!.forEach((key, value) {
        buffer.write(' -H ${_shellQuote('$key: $value')}');
      });
    }
    final data = req.requestData;
    if (data is FormData) {
      for (final field in data.fields) {
        buffer.write(' -F ${_shellQuote('${field.key}=${field.value}')}');
      }
      for (final file in data.files) {
        final filename = file.value.filename ?? 'file';
        buffer.write(' -F ${_shellQuote('${file.key}=@$filename')}');
      }
    } else if (data != null) {
      final dataString = data is Map || data is List
          ? jsonEncode(data)
          : data.toString();
      buffer.write(' -d ${_shellQuote(dataString)}');
    }
    return buffer.toString();
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
