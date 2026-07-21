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
}
