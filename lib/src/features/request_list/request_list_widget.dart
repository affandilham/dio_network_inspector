import 'package:flutter/material.dart';
import '../../dio_network_inspector.dart';
import '../../models/network_request.dart';
import '../../core/theme/inspector_colors.dart';
import '../../core/theme/inspector_dimensions.dart';
import '../../components/base_text.dart';
import '../../components/custom_popup_menu_item.dart';
import 'request_list_controller.dart';

class InspectorRequestListWidget extends StatelessWidget {
  final NetworkRequest? selectedRequest;
  final ValueChanged<NetworkRequest> onSelected;

  const InspectorRequestListWidget({
    super.key,
    required this.selectedRequest,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<NetworkRequest>>(
      valueListenable: DioNetworkInspector.instance.requests,
      builder: (context, requests, _) {
        if (requests.isEmpty) {
          return const Center(
            child: BaseText(
              'No requests',
              color: InspectorColors.textSecondary,
            ),
          );
        }
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final isSelected = selectedRequest?.id == req.id;
            return _RequestTile(
              req: req,
              isSelected: isSelected,
              onSelected: onSelected,
            );
          },
        );
      },
    );
  }
}

class _RequestTile extends StatelessWidget {
  final NetworkRequest req;
  final bool isSelected;
  final ValueChanged<NetworkRequest> onSelected;
  final RequestListController _controller = RequestListController();

  _RequestTile({
    required this.req,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryContainer = theme.colorScheme.primaryContainer;
    final hasError = req.error != null;
    final isSuccess = req.statusCode != null &&
        req.statusCode! >= 200 &&
        req.statusCode! < 300;

    Color statusColor = InspectorColors.textSecondary;
    if (hasError || (req.statusCode != null && req.statusCode! >= 400)) {
      statusColor = InspectorColors.error;
    } else if (isSuccess) {
      statusColor = InspectorColors.success;
    }

    final path = Uri.tryParse(req.url)?.path ?? req.url;

    return LayoutBuilder(
      builder: (context, constraints) {
        final durationStr = '${req.duration} ms';
        final durationPainter = TextPainter(
          text: TextSpan(
            text: durationStr,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        final pathStyle = TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        );
        final pathPainter = TextPainter(
          text: TextSpan(text: path, style: pathStyle),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        final availablePathWidth =
            constraints.maxWidth - 93.0 - durationPainter.size.width;
        final isOverflowing = pathPainter.size.width > availablePathWidth;

        Widget content = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onSecondaryTapDown: (details) {
            final overlay = Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
            if (overlay == null) return;

            final localPosition = overlay.globalToLocal(details.globalPosition);

            showMenu(
              context: context,
              position: RelativeRect.fromSize(
                localPosition & Size.zero,
                overlay.size,
              ),
              constraints: const BoxConstraints(),
              color: InspectorColors.background,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(InspectorDimensions.radiusXl),
              ),
              items: [
                const CustomPopupMenuItem(
                  value: 'copy_curl',
                  text: 'Copy as cURL',
                ),
              ],
            ).then((value) {
              if (!context.mounted) return;
              if (value == 'copy_curl') {
                _controller.handleCopyCurl(context, req);
              }
            });
          },
          child: InkWell(
            onTap: () => onSelected(req),
            child: Container(
              color: isSelected ? primaryContainer : null,
              padding: const EdgeInsets.symmetric(
                horizontal: InspectorDimensions.spacingS,
                vertical: InspectorDimensions.spacingM / 2,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: BaseText(
                      req.statusCode?.toString() ?? '...',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: InspectorDimensions.spacingXs),
                  SizedBox(
                    width: 35,
                    child: BaseText(
                      req.method,
                      style: const TextStyle(fontSize: 10),
                      color: InspectorColors.textBlueGrey,
                    ),
                  ),
                  const SizedBox(width: InspectorDimensions.spacingXs),
                  Expanded(
                    child: BaseText(
                      path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: pathStyle,
                    ),
                  ),
                  const SizedBox(width: InspectorDimensions.spacingXs),
                  BaseText(
                    durationStr,
                    style: const TextStyle(fontSize: 10),
                    color: InspectorColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );

        if (isOverflowing) {
          return Tooltip(
            message: path,
            waitDuration: const Duration(milliseconds: 500),
            child: content,
          );
        }
        return content;
      },
    );
  }
}
