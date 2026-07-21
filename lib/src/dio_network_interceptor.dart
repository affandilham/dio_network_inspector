import 'package:dio/dio.dart';
import 'dio_network_inspector.dart';
import 'models/network_request.dart';

class DioNetworkInterceptor extends Interceptor {
  final Map<RequestOptions, NetworkRequest> _requests = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!DioNetworkInspector.instance.isRecording.value) {
      return super.onRequest(options, handler);
    }
    final request = NetworkRequest(
      id: DioNetworkInspector.instance.generateId(),
      method: options.method,
      url: options.uri.toString(),
      requestTime: DateTime.now(),
      requestHeaders: options.headers,
      requestData: options.data,
      queryParameters: options.queryParameters,
    );
    _requests[options] = request;
    DioNetworkInspector.instance.addRequest(request);
    
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!DioNetworkInspector.instance.isRecording.value) {
      return super.onResponse(response, handler);
    }
    final request = _requests[response.requestOptions];
    if (request != null) {
      request.responseTime = DateTime.now();
      request.statusCode = response.statusCode;
      request.statusMessage = response.statusMessage;
      request.responseHeaders = response.headers.map;
      request.responseData = response.data;
      DioNetworkInspector.instance.updateRequest(request);
      _requests.remove(response.requestOptions);
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!DioNetworkInspector.instance.isRecording.value) {
      return super.onError(err, handler);
    }
    final request = _requests[err.requestOptions];
    if (request != null) {
      request.responseTime = DateTime.now();
      request.statusCode = err.response?.statusCode;
      request.statusMessage = err.response?.statusMessage;
      request.responseHeaders = err.response?.headers.map;
      request.responseData = err.response?.data;
      request.error = err.toString();
      DioNetworkInspector.instance.updateRequest(request);
      _requests.remove(err.requestOptions);
    }
    super.onError(err, handler);
  }
}
