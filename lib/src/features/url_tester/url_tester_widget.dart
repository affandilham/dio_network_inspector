import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../../core/theme/inspector_colors.dart';
import '../../core/theme/inspector_dimensions.dart';
import '../../core/theme/inspector_typography.dart';
import '../../components/base_container.dart';
import '../../components/base_text.dart';

class FormDataField {
  final TextEditingController keyController;
  final TextEditingController valueController;
  bool isFile;

  FormDataField({String key = '', String value = '', this.isFile = false})
    : keyController = TextEditingController(text: key),
      valueController = TextEditingController(text: value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class UrlTesterState {
  String url = '';
  String token = '';
  String method = 'GET';
  String bodyType = 'JSON';
  String bodyText = '';
  String result = '';
  List<Map<String, dynamic>> formDataList = [];

  static final UrlTesterState instance = UrlTesterState._internal();
  UrlTesterState._internal();
}

class InspectorUrlTesterWidget extends StatefulWidget {
  const InspectorUrlTesterWidget({super.key});

  @override
  State<InspectorUrlTesterWidget> createState() =>
      _InspectorUrlTesterWidgetState();
}

class _InspectorUrlTesterWidgetState extends State<InspectorUrlTesterWidget> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String _selectedMethod = 'GET';
  String _result = '';

  String _bodyType = 'JSON';
  final List<FormDataField> _formDataFields = [];

  @override
  void initState() {
    super.initState();
    final state = UrlTesterState.instance;
    _urlController.text = state.url;
    _tokenController.text = state.token;
    _bodyController.text = state.bodyText;
    _selectedMethod = state.method;
    _bodyType = state.bodyType;
    _result = state.result;

    if (state.formDataList.isNotEmpty) {
      for (final map in state.formDataList) {
        _formDataFields.add(
          FormDataField(
            key: map['key'] as String? ?? '',
            value: map['value'] as String? ?? '',
            isFile: map['isFile'] as bool? ?? false,
          ),
        );
      }
    } else {
      _formDataFields.add(FormDataField());
    }
  }

  Future<void> _sendRequest() async {
    if (_urlController.text.isEmpty) {
      setState(() => _result = 'Error: URL cannot be empty.');
      return;
    }

    setState(() {
      _result = 'Sending request...';
    });

    try {
      final dio = Dio();

      dynamic data;
      bool isFormData = _bodyType == 'FormData';

      if (isFormData) {
        final formDataMap = <String, dynamic>{};
        for (final field in _formDataFields) {
          final k = field.keyController.text.trim();
          final v = field.valueController.text.trim();
          if (k.isNotEmpty) {
            if (field.isFile && v.isNotEmpty) {
              formDataMap[k] = await MultipartFile.fromFile(v);
            } else {
              formDataMap[k] = v;
            }
          }
        }
        data = FormData.fromMap(formDataMap);
      } else {
        if (_bodyController.text.isNotEmpty) {
          try {
            data = jsonDecode(_bodyController.text);
          } catch (e) {
            data = _bodyController.text;
          }
        }
      }

      final options = Options(
        method: _selectedMethod,
        headers: {
          if (_tokenController.text.isNotEmpty)
            'Authorization': 'Bearer ${_tokenController.text}',
          if (_bodyController.text.isNotEmpty && !isFormData)
            'Content-Type': 'application/json',
        },
      );

      final response = await dio.request(
        _urlController.text,
        options: options,
        data: data,
      );

      setState(() {
        String dataStr = '';
        try {
          dataStr = const JsonEncoder.withIndent('  ').convert(response.data);
        } catch (_) {
          dataStr = response.data.toString();
        }

        _result =
            'Status: ${response.statusCode}\n\nHeaders:\n${response.headers}\n\nData:\n$dataStr';
      });
    } on DioException catch (e) {
      setState(() {
        String dataStr = '';
        try {
          dataStr = const JsonEncoder.withIndent(
            '  ',
          ).convert(e.response?.data);
        } catch (_) {
          dataStr = e.response?.data?.toString() ?? e.message ?? '';
        }

        _result =
            'Error: ${e.type}\nStatus: ${e.response?.statusCode}\n\nHeaders:\n${e.response?.headers}\n\nData:\n$dataStr';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  void _onUrlChanged(String text) {
    if (text.trimLeft().startsWith('curl ')) {
      String method = 'GET';
      String url = '';
      String token = '';

      final methodRegExp = RegExp(r"(?:-X|--request)\s+([A-Z]+)");
      final methodMatch = methodRegExp.firstMatch(text);
      if (methodMatch != null) {
        method = methodMatch.group(1)!;
      }

      final urlRegExp = RegExp(r'''['"]?(https?://[^\s'"]+)['"]?''');
      final urlMatch = urlRegExp.firstMatch(text);
      if (urlMatch != null) {
        url = urlMatch.group(1)!;
      }

      final tokenRegExp = RegExp(
        r'''(?:-H|--header)\s+['"]?Authorization:\s*Bearer\s+([^'"]+)['"]?''',
        caseSensitive: false,
      );
      final tokenMatch = tokenRegExp.firstMatch(text);
      if (tokenMatch != null) {
        token = tokenMatch.group(1)!;
      }

      final formDataMatches = RegExp(
        r'''(?:-F|--form)\s+['"]([^=]+)=(@?)([^'"]+)['"]''',
      ).allMatches(text);
      bool didPopulateFormData = false;
      bool didPopulateJsonData = false;

      if (formDataMatches.isNotEmpty) {
        for (var f in _formDataFields) {
          f.dispose();
        }
        _formDataFields.clear();

        for (final m in formDataMatches) {
          final key = m.group(1)!;
          final isFile = m.group(2) == '@';
          final val = m.group(3)!;
          _formDataFields.add(
            FormDataField(key: key, value: val, isFile: isFile),
          );
        }
        if (_formDataFields.isEmpty) {
          _formDataFields.add(FormDataField());
        }
        if (methodMatch == null) {
          method = 'POST';
        }
        didPopulateFormData = true;
      } else {
        final bodyRegExp = RegExp(
          r'''(?:-d|--data|--data-raw)\s+(['"])(.*?)\1''',
        );
        final bodyMatch = bodyRegExp.firstMatch(text);
        if (bodyMatch != null) {
          _bodyController.text = bodyMatch.group(2)!;
          if (methodMatch == null) {
            method = 'POST';
          }
          didPopulateJsonData = true;
        }
      }

      if (url.isNotEmpty) {
        _urlController.text = url;
        _urlController.selection = TextSelection.fromPosition(
          TextPosition(offset: url.length),
        );

        setState(() {
          if (['GET', 'POST', 'PUT', 'DELETE'].contains(method)) {
            _selectedMethod = method;
          }
          if (token.isNotEmpty) {
            _tokenController.text = token;
          }
          if (didPopulateFormData) {
            _bodyType = 'FormData';
          } else if (didPopulateJsonData) {
            _bodyType = 'JSON';
          }
        });
      }
    }
  }

  @override
  void dispose() {
    final state = UrlTesterState.instance;
    state.url = _urlController.text;
    state.token = _tokenController.text;
    state.bodyText = _bodyController.text;
    state.method = _selectedMethod;
    state.bodyType = _bodyType;
    state.result = _result;

    state.formDataList = _formDataFields
        .map(
          (f) => {
            'key': f.keyController.text,
            'value': f.valueController.text,
            'isFile': f.isFile,
          },
        )
        .toList();

    _urlController.dispose();
    _tokenController.dispose();
    _bodyController.dispose();
    for (var f in _formDataFields) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseContainer(
      color: InspectorColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(InspectorDimensions.spacingM),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: InspectorColors.divider),
              ),
            ),
            child: const BaseText(
              'URL Tester',
              style: InspectorTypography.title,
            ),
          ),

          // Form
          Flexible(
            flex: 3,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(InspectorDimensions.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: InspectorColors.surface,
                            border: Border.all(color: InspectorColors.divider),
                            borderRadius: BorderRadius.circular(
                              InspectorDimensions.radiusS,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: InspectorDimensions.spacingS,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedMethod,
                              isDense: true,
                              items: ['GET', 'POST', 'PUT', 'DELETE']
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: BaseText(
                                        m,
                                        style: InspectorTypography.body
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedMethod = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: InspectorDimensions.spacingM),
                        Expanded(
                          child: TextField(
                            controller: _urlController,
                            onChanged: _onUrlChanged,
                            decoration: InputDecoration(
                              hintText: 'Enter request URL or paste cURL',
                              hintStyle: InspectorTypography.body.copyWith(
                                color: InspectorColors.textSecondary,
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: InspectorDimensions.spacingM,
                                vertical: InspectorDimensions.spacingM,
                              ),
                              border: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: InspectorColors.divider,
                                ),
                                borderRadius: BorderRadius.circular(
                                  InspectorDimensions.radiusS,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: InspectorColors.divider,
                                ),
                                borderRadius: BorderRadius.circular(
                                  InspectorDimensions.radiusS,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: InspectorColors.primary,
                                ),
                                borderRadius: BorderRadius.circular(
                                  InspectorDimensions.radiusS,
                                ),
                              ),
                            ),
                            style: InspectorTypography.body,
                          ),
                        ),
                        const SizedBox(width: InspectorDimensions.spacingM),
                        ElevatedButton(
                          onPressed: _sendRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: InspectorColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: InspectorDimensions.spacingL,
                              vertical: InspectorDimensions.spacingM,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                InspectorDimensions.radiusS,
                              ),
                            ),
                          ),
                          child: const BaseText(
                            'Send',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: InspectorDimensions.spacingM),
                    TextField(
                      controller: _tokenController,
                      decoration: InputDecoration(
                        hintText: 'Bearer Token (Optional)',
                        hintStyle: InspectorTypography.body.copyWith(
                          color: InspectorColors.textSecondary,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: InspectorDimensions.spacingM,
                          vertical: InspectorDimensions.spacingM,
                        ),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: InspectorColors.divider,
                          ),
                          borderRadius: BorderRadius.circular(
                            InspectorDimensions.radiusS,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: InspectorColors.divider,
                          ),
                          borderRadius: BorderRadius.circular(
                            InspectorDimensions.radiusS,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: InspectorColors.primary,
                          ),
                          borderRadius: BorderRadius.circular(
                            InspectorDimensions.radiusS,
                          ),
                        ),
                      ),
                      style: InspectorTypography.body,
                    ),
                    const SizedBox(height: InspectorDimensions.spacingM),

                    // Body Type Toggle
                    Row(
                      children: [
                        const BaseText(
                          'Body:',
                          style: InspectorTypography.body,
                        ),
                        const SizedBox(width: InspectorDimensions.spacingS),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: InspectorColors.divider),
                            borderRadius: BorderRadius.circular(
                              InspectorDimensions.radiusS,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _bodyType,
                              isDense: true,
                              items: ['JSON', 'FormData']
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: BaseText(
                                        m,
                                        style: InspectorTypography.body,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _bodyType = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: InspectorDimensions.spacingS),

                    // Body Content
                    if (_bodyType == 'JSON')
                      TextField(
                        controller: _bodyController,
                        maxLines: 5,
                        minLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Request Body (JSON, etc.)',
                          hintStyle: InspectorTypography.body.copyWith(
                            color: InspectorColors.textSecondary,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: InspectorDimensions.spacingM,
                            vertical: InspectorDimensions.spacingM,
                          ),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: InspectorColors.divider,
                            ),
                            borderRadius: BorderRadius.circular(
                              InspectorDimensions.radiusS,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: InspectorColors.divider,
                            ),
                            borderRadius: BorderRadius.circular(
                              InspectorDimensions.radiusS,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: InspectorColors.primary,
                            ),
                            borderRadius: BorderRadius.circular(
                              InspectorDimensions.radiusS,
                            ),
                          ),
                        ),
                        style: InspectorTypography.body.copyWith(
                          fontFamily: 'monospace',
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (int i = 0; i < _formDataFields.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller:
                                          _formDataFields[i].keyController,
                                      decoration: InputDecoration(
                                        hintText: 'Key',
                                        isDense: true,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            InspectorDimensions.radiusS,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                      ),
                                      style: InspectorTypography.body,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: InspectorDimensions.spacingS,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: InspectorColors.divider,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        InspectorDimensions.radiusS,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<bool>(
                                        value: _formDataFields[i].isFile,
                                        isDense: true,
                                        items: [
                                          DropdownMenuItem(
                                            value: false,
                                            child: BaseText(
                                              'Text',
                                              style: InspectorTypography.body,
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: true,
                                            child: BaseText(
                                              'File',
                                              style: InspectorTypography.body,
                                            ),
                                          ),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => _formDataFields[i].isFile =
                                                  val,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: InspectorDimensions.spacingS,
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _formDataFields[i]
                                                .valueController,
                                            decoration: InputDecoration(
                                              hintText:
                                                  _formDataFields[i].isFile
                                                  ? 'File path...'
                                                  : 'Value',
                                              isDense: true,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      InspectorDimensions
                                                          .radiusS,
                                                    ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 12,
                                                  ),
                                            ),
                                            style: InspectorTypography.body,
                                          ),
                                        ),
                                        if (_formDataFields[i].isFile)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left:
                                                  InspectorDimensions.spacingS,
                                            ),
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                final file = await openFile();
                                                if (file != null) {
                                                  _formDataFields[i]
                                                          .valueController
                                                          .text =
                                                      file.path;
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    InspectorColors.surface,
                                                foregroundColor:
                                                    InspectorColors.textPrimary,
                                                side: const BorderSide(
                                                  color:
                                                      InspectorColors.divider,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                    ),
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        InspectorDimensions
                                                            .radiusS,
                                                      ),
                                                ),
                                              ),
                                              child: BaseText(
                                                'Browse...',
                                                style: InspectorTypography.body,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _formDataFields[i].dispose();
                                        _formDataFields.removeAt(i);
                                        if (_formDataFields.isEmpty) {
                                          _formDataFields.add(FormDataField());
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _formDataFields.add(FormDataField());
                                });
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: BaseText(
                                'Add Field',
                                style: InspectorTypography.body.copyWith(
                                  color: InspectorColors.primary,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: InspectorColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Result
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(InspectorDimensions.spacingM),
              padding: const EdgeInsets.all(InspectorDimensions.spacingM),
              decoration: BoxDecoration(
                color: InspectorColors.surface,
                border: Border.all(color: InspectorColors.divider),
                borderRadius: BorderRadius.circular(
                  InspectorDimensions.radiusS,
                ),
              ),
              child: SingleChildScrollView(
                child: BaseText(
                  _result.isEmpty ? 'Response will appear here...' : _result,
                  style: InspectorTypography.body.copyWith(
                    fontFamily: 'monospace',
                    color: _result.isEmpty
                        ? InspectorColors.textSecondary
                        : InspectorColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
