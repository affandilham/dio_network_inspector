import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../models/network_request.dart';

class RequestListController {
  
  String generateCurl(NetworkRequest req) {
    final buffer = StringBuffer("curl -X ${req.method} '${req.url}'");
    if (req.requestHeaders != null) {
      req.requestHeaders!.forEach((key, value) {
        buffer.write(" -H '$key: $value'");
      });
    }
    if (req.requestData != null) {
      if (req.requestData is Map || req.requestData is List) {
        final dataString = jsonEncode(req.requestData).replaceAll("'", "'\\''");
        buffer.write(" -d '$dataString'");
      } else {
        final dataString = req.requestData.toString().replaceAll("'", "'\\''");
        buffer.write(" -d '$dataString'");
      }
    }
    return buffer.toString();
  }

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
