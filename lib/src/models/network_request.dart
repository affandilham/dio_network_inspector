import 'package:dio/dio.dart';

class NetworkRequest {
  final int id;
  final String method;
  final String url;
  final DateTime requestTime;
  DateTime? responseTime;
  int? statusCode;
  String? statusMessage;

  Map<String, dynamic>? requestHeaders;
  dynamic requestData;
  Map<String, dynamic>? queryParameters;

  Map<String, dynamic>? responseHeaders;
  dynamic responseData;

  String? error;

  NetworkRequest({
    required this.id,
    required this.method,
    required this.url,
    required this.requestTime,
    this.requestHeaders,
    this.requestData,
    this.queryParameters,
  });

  int get duration {
    if (responseTime == null) return 0;
    return responseTime!.difference(requestTime).inMilliseconds;
  }

  int get size {
    int totalSize = 0;
    if (responseData != null) {
      totalSize += responseData.toString().length;
    }
    return totalSize;
  }

  /// A JSON-friendly representation for inspector UI.
  ///
  /// [FormData] streams cannot be rendered directly and otherwise appear as
  /// `Instance of 'FormData'`. Keep fields and file metadata only: the file
  /// contents are intentionally never read or retained by the inspector.
  dynamic get requestDataForDisplay {
    if (requestData is! FormData) return requestData;

    final formData = requestData as FormData;
    final fields = <String, dynamic>{};
    for (final field in formData.fields) {
      final current = fields[field.key];
      if (current == null) {
        fields[field.key] = field.value;
      } else if (current is List) {
        current.add(field.value);
      } else {
        fields[field.key] = [current, field.value];
      }
    }

    final files = <String, List<Map<String, dynamic>>>{};
    for (final file in formData.files) {
      files.putIfAbsent(file.key, () => []).add({
        'filename': file.value.filename ?? 'file',
        'contentType': file.value.contentType?.toString(),
        'length': file.value.length,
      });
    }

    return {
      'type': 'multipart/form-data',
      'fields': fields,
      if (files.isNotEmpty) 'files': files,
    };
  }

  Map<String, dynamic> get requestHeadersForDisplay => requestHeaders ?? {};
  Map<String, dynamic> get responseHeadersForDisplay => responseHeaders ?? {};
  Map<String, dynamic> get queryParametersForDisplay => queryParameters ?? {};
  dynamic get responseDataForDisplay => responseData;

  Map<String, dynamic> toJson() => {
    'id': id,
    'method': method,
    'url': url,
    'requestTime': requestTime.toIso8601String(),
    'responseTime': responseTime?.toIso8601String(),
    'statusCode': statusCode,
    'statusMessage': statusMessage,
    'requestHeaders': requestHeadersForDisplay,
    'requestData': requestDataForDisplay,
    'queryParameters': queryParameters,
    'responseHeaders': responseHeadersForDisplay,
    'responseData': responseDataForDisplay,
    'error': error,
  };

  factory NetworkRequest.fromJson(Map<String, dynamic> json) {
    final request = NetworkRequest(
      id: json['id'] as int,
      method: json['method'] as String,
      url: json['url'] as String,
      requestTime: DateTime.parse(json['requestTime'] as String),
      requestHeaders: Map<String, dynamic>.from(
        json['requestHeaders'] as Map? ?? const {},
      ),
      requestData: json['requestData'],
      queryParameters: Map<String, dynamic>.from(
        json['queryParameters'] as Map? ?? const {},
      ),
    );
    request.responseTime = json['responseTime'] == null
        ? null
        : DateTime.parse(json['responseTime'] as String);
    request.statusCode = json['statusCode'] as int?;
    request.statusMessage = json['statusMessage'] as String?;
    request.responseHeaders = Map<String, dynamic>.from(
      json['responseHeaders'] as Map? ?? const {},
    );
    request.responseData = json['responseData'];
    request.error = json['error'] as String?;
    return request;
  }
}
