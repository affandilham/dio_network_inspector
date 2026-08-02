import 'package:flutter/material.dart';
import '../../dio_network_inspector.dart';
import '../../models/network_request.dart';
import '../../core/theme/inspector_colors.dart';
import '../../core/theme/inspector_dimensions.dart';
import '../../core/theme/inspector_typography.dart';
import '../../components/base_text.dart';
import '../../components/custom_popup_menu_item.dart';
import '../../components/overflow_tooltip.dart';
import 'request_list_controller.dart';

enum _RequestFilter { all, success, errors, slow, get, post }

class InspectorRequestListWidget extends StatefulWidget {
  final NetworkRequest? selectedRequest;
  final ValueChanged<NetworkRequest> onSelected;

  const InspectorRequestListWidget({
    super.key,
    required this.selectedRequest,
    required this.onSelected,
  });

  @override
  State<InspectorRequestListWidget> createState() =>
      _InspectorRequestListWidgetState();
}

class _InspectorRequestListWidgetState
    extends State<InspectorRequestListWidget> {
  final _searchController = TextEditingController();
  _RequestFilter _filter = _RequestFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: ValueListenableBuilder<List<NetworkRequest>>(
            valueListenable: DioNetworkInspector.instance.requests,
            builder: (context, requests, _) {
              final query = _searchController.text.trim().toLowerCase();
              final filtered = requests.where((request) {
                final matchesSearch =
                    query.isEmpty ||
                    request.url.toLowerCase().contains(query) ||
                    request.method.toLowerCase().contains(query) ||
                    (request.statusCode?.toString().contains(query) ?? false);
                final isError =
                    request.error != null || (request.statusCode ?? 0) >= 400;
                final matchesFilter = switch (_filter) {
                  _RequestFilter.all => true,
                  _RequestFilter.success =>
                    !isError &&
                        (request.statusCode ?? 0) >= 200 &&
                        (request.statusCode ?? 0) < 300,
                  _RequestFilter.errors => isError,
                  _RequestFilter.slow => request.duration >= 1000,
                  _RequestFilter.get => request.method.toUpperCase() == 'GET',
                  _RequestFilter.post => request.method.toUpperCase() == 'POST',
                };
                return matchesSearch && matchesFilter;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: BaseText(
                    requests.isEmpty
                        ? 'No requests yet'
                        : 'No matching requests',
                    color: InspectorColors.textSecondary,
                  ),
                );
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final request = filtered[index];
                  return _RequestTile(
                    req: request,
                    isSelected: widget.selectedRequest?.id == request.id,
                    onSelected: widget.onSelected,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(
        horizontal: InspectorDimensions.spacingS,
      ),
      decoration: const BoxDecoration(
        color: InspectorColors.surface,
        border: Border(bottom: BorderSide(color: InspectorColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: InspectorTypography.body,
                decoration: InputDecoration(
                  hintText: 'Search requests',
                  hintStyle: InspectorTypography.body.copyWith(
                    color: InspectorColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 16,
                    color: InspectorColors.textSecondary,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  filled: true,
                  fillColor: InspectorColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      InspectorDimensions.radiusM,
                    ),
                    borderSide: const BorderSide(
                      color: InspectorColors.divider,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      InspectorDimensions.radiusM,
                    ),
                    borderSide: const BorderSide(
                      color: InspectorColors.divider,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      InspectorDimensions.radiusM,
                    ),
                    borderSide: const BorderSide(
                      color: InspectorColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: InspectorDimensions.spacingXs),
          Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: PopupMenuButton<_RequestFilter>(
              tooltip: 'Filter requests',
              position: PopupMenuPosition.under,
              offset: const Offset(0, 4),
              constraints: const BoxConstraints(minWidth: 176),
              color: InspectorColors.background,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  InspectorDimensions.radiusXl,
                ),
              ),
              onSelected: (filter) => setState(() => _filter = filter),
              itemBuilder: (context) => [
                CustomPopupMenuItem(
                  value: _RequestFilter.all,
                  text: 'All requests',
                  isSelected: _filter == _RequestFilter.all,
                ),
                CustomPopupMenuItem(
                  value: _RequestFilter.errors,
                  text: 'Errors only',
                  isSelected: _filter == _RequestFilter.errors,
                ),
                CustomPopupMenuItem(
                  value: _RequestFilter.success,
                  text: 'Successful (2xx)',
                  isSelected: _filter == _RequestFilter.success,
                ),
                CustomPopupMenuItem(
                  value: _RequestFilter.slow,
                  text: 'Slow (≥ 1 second)',
                  isSelected: _filter == _RequestFilter.slow,
                ),
                CustomPopupMenuItem(
                  value: _RequestFilter.get,
                  text: 'GET only',
                  isSelected: _filter == _RequestFilter.get,
                ),
                CustomPopupMenuItem(
                  value: _RequestFilter.post,
                  text: 'POST only',
                  isSelected: _filter == _RequestFilter.post,
                ),
              ],
              child: SizedBox(
                width: 36,
                height: 36,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _filter == _RequestFilter.all
                        ? InspectorColors.background
                        : InspectorColors.primaryContainer,
                    border: Border.all(color: InspectorColors.divider),
                    borderRadius: BorderRadius.circular(
                      InspectorDimensions.radiusM,
                    ),
                  ),
                  child: Icon(
                    Icons.filter_list,
                    size: 18,
                    color: _filter == _RequestFilter.all
                        ? InspectorColors.textBlueGrey
                        : InspectorColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: InspectorDimensions.spacingXs),
          Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: Tooltip(
              message: 'Clear logs (⌘/Ctrl+K)',
              child: Semantics(
                label: 'Clear logs, shortcut Command or Control K',
                button: true,
                child: InkWell(
                  onTap: DioNetworkInspector.instance.clear,
                  borderRadius: BorderRadius.circular(
                    InspectorDimensions.radiusM,
                  ),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: InspectorColors.background,
                        border: Border.all(color: InspectorColors.divider),
                        borderRadius: BorderRadius.circular(
                          InspectorDimensions.radiusM,
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        size: InspectorDimensions.iconM,
                        color: Colors.red,
                      ),
                    ),
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
    final hasError = req.error != null || (req.statusCode ?? 0) >= 400;
    final isSuccess =
        !hasError &&
        req.statusCode != null &&
        req.statusCode! >= 200 &&
        req.statusCode! < 300;
    final statusColor = hasError
        ? InspectorColors.error
        : isSuccess
        ? InspectorColors.success
        : InspectorColors.textSecondary;
    final path = Uri.tryParse(req.url)?.path ?? req.url;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) => _showContextMenu(context, details),
      child: InkWell(
        onTap: () => onSelected(req),
        child: Container(
          height: 40,
          padding: const EdgeInsets.only(
            left: InspectorDimensions.spacingS,
            right: InspectorDimensions.spacingM,
          ),
          decoration: BoxDecoration(
            color: isSelected ? InspectorColors.primaryContainer : null,
            border: Border(
              left: BorderSide(
                color: isSelected
                    ? InspectorColors.primary
                    : Colors.transparent,
                width: 3,
              ),
              bottom: const BorderSide(color: InspectorColors.surface),
            ),
          ),
          child: Row(
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 31),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: BaseText(
                  req.statusCode?.toString() ?? '…',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  color: statusColor,
                ),
              ),
              const SizedBox(width: InspectorDimensions.spacingS),
              SizedBox(
                width: 36,
                child: BaseText(
                  req.method,
                  style: InspectorTypography.mono.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  color: InspectorColors.textBlueGrey,
                ),
              ),
              const SizedBox(width: InspectorDimensions.spacingS),
              Expanded(
                child: OverflowTooltip(
                  message: req.url,
                  style: InspectorTypography.mono.copyWith(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  child: BaseText(
                    path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    isMono: true,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: InspectorDimensions.spacingS),
              BaseText(
                '${req.duration}ms',
                isMono: true,
                style: const TextStyle(fontSize: 10),
                color: InspectorColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, TapDownDetails details) {
    final overlay =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final position = RelativeRect.fromSize(
      overlay.globalToLocal(details.globalPosition) & Size.zero,
      overlay.size,
    );
    showMenu(
      context: context,
      position: position,
      color: InspectorColors.background,
      elevation: 6,
      constraints: const BoxConstraints(minWidth: 176),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(InspectorDimensions.radiusXl),
      ),
      items: const [
        CustomPopupMenuItem(value: 'copy_curl', text: 'Copy as cURL'),
      ],
    ).then((value) {
      if (context.mounted && value == 'copy_curl') {
        _controller.handleCopyCurl(context, req);
      }
    });
  }
}
