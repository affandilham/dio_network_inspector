import 'package:dio/dio.dart';
import 'package:dio_network_inspector/src/features/request_list/request_list_controller.dart';
import 'package:dio_network_inspector/src/models/network_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RequestListController.generateCurl', () {
    final controller = RequestListController();

    test(
      'generates clean single-line cURL for simple GET request without headers or body',
      () {
        final req = NetworkRequest(
          id: 1,
          method: 'GET',
          url: 'https://api.example.com/items',
          requestTime: DateTime.now(),
        );

        final curl = controller.generateCurl(req);
        expect(curl, equals("curl 'https://api.example.com/items'"));
        expect(curl.contains('-X'), isFalse);
      },
    );

    test(
      'omits redundant -X GET but includes headers formatted on separate lines',
      () {
        final req = NetworkRequest(
          id: 2,
          method: 'GET',
          url: 'https://api.example.com/items',
          requestTime: DateTime.now(),
          requestHeaders: {
            'Authorization': 'Bearer my_token',
            'Accept': 'application/json',
          },
        );

        final curl = controller.generateCurl(req);
        final lines = curl.split(' \\\n  ');
        expect(lines.length, equals(3));
        expect(lines[0], equals("curl 'https://api.example.com/items'"));
        expect(lines[1], equals("-H 'Authorization: Bearer my_token'"));
        expect(lines[2], equals("-H 'Accept: application/json'"));
        expect(curl.contains('-X'), isFalse);
      },
    );

    test(
      'filters out problematic headers like content-length, host, connection, accept-encoding',
      () {
        final req = NetworkRequest(
          id: 3,
          method: 'PUT',
          url:
              'https://beta.gateway.broiler.voltunes.com/purchase-orders/PO~PAKAN~UKJ~082026~0006',
          requestTime: DateTime.now(),
          requestHeaders: {
            'Authorization': 'Bearer secret-token',
            'content-type': 'application/json',
            'content-length': 203,
            'Content-Length': 203,
            'Host': 'beta.gateway.broiler.voltunes.com',
            'Connection': 'keep-alive',
            'accept-encoding': 'gzip, deflate, br',
          },
          requestData: {
            'date_of_need': '2026-09-04T17:00:00.000Z',
            'supplier_id': 515,
            'status': 'input',
          },
        );

        final curl = controller.generateCurl(req);
        expect(curl.toLowerCase().contains('content-length'), isFalse);
        expect(curl.toLowerCase().contains('host:'), isFalse);
        expect(curl.toLowerCase().contains('connection:'), isFalse);
        expect(curl.toLowerCase().contains('accept-encoding:'), isFalse);

        final lines = curl.split(' \\\n  ');
        expect(
          lines[0],
          equals(
            "curl 'https://beta.gateway.broiler.voltunes.com/purchase-orders/PO~PAKAN~UKJ~082026~0006'",
          ),
        );
        expect(lines[1], equals('-X PUT'));
        expect(lines[2], equals("-H 'Authorization: Bearer secret-token'"));
        expect(lines[3], equals("-H 'content-type: application/json'"));
        expect(lines[4], startsWith("-d '"));
        expect(lines[4], contains('"supplier_id":515'));
      },
    );

    test(
      'auto-adds content-type: application/json when missing for JSON body',
      () {
        final req = NetworkRequest(
          id: 4,
          method: 'POST',
          url: 'https://api.example.com/create',
          requestTime: DateTime.now(),
          requestHeaders: {'Authorization': 'Bearer token'},
          requestData: {'name': 'test'},
        );

        final curl = controller.generateCurl(req);
        expect(curl, contains("-H 'content-type: application/json'"));
        expect(curl, contains("-d '{\"name\":\"test\"}'"));
      },
    );

    test('handles FormData properly and strips multipart/form-data header', () {
      final formData = FormData.fromMap({
        'title': 'invoice',
        'file': MultipartFile.fromString(
          'dummy file content',
          filename: 'invoice.pdf',
        ),
      });

      final req = NetworkRequest(
        id: 5,
        method: 'POST',
        url: 'https://api.example.com/upload',
        requestTime: DateTime.now(),
        requestHeaders: {
          'Authorization': 'Bearer token',
          'content-type':
              'multipart/form-data; boundary=dart-dio-boundary-12345',
        },
        requestData: formData,
      );

      final curl = controller.generateCurl(req);
      expect(curl, contains("curl 'https://api.example.com/upload'"));
      expect(curl, contains('-X POST'));
      expect(curl, contains("-H 'Authorization: Bearer token'"));
      // boundary must be stripped
      expect(curl.toLowerCase().contains('multipart/form-data'), isFalse);
      // FormData fields
      expect(curl, contains("-F 'title=invoice'"));
      expect(curl, contains("-F 'file=@invoice.pdf'"));
    });

    test('handles Iterable header values properly', () {
      final req = NetworkRequest(
        id: 6,
        method: 'GET',
        url: 'https://api.example.com/test',
        requestTime: DateTime.now(),
        requestHeaders: {
          'Accept': ['application/json', 'text/plain'],
        },
      );

      final curl = controller.generateCurl(req);
      expect(curl, contains("-H 'Accept: application/json'"));
      expect(curl, contains("-H 'Accept: text/plain'"));
    });

    test('properly escapes single quotes in URL and data', () {
      final req = NetworkRequest(
        id: 7,
        method: 'POST',
        url: "https://api.example.com/user's_items",
        requestTime: DateTime.now(),
        requestData: {'note': "it's great"},
      );

      final curl = controller.generateCurl(req);
      expect(curl, contains(r"https://api.example.com/user'\''s_items"));
      expect(curl, contains(r"it'\''s great"));
    });
  });
}
