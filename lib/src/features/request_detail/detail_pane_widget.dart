import 'package:flutter/material.dart';
import '../../models/network_request.dart';
import 'detail_pane_controller.dart';
import '../json_viewer/json_viewer_widget.dart';
import '../../components/custom_popup_menu_item.dart';
import '../../components/base_text.dart';
import '../../components/base_container.dart';
import '../../components/section_title.dart';
import '../../components/detail_row.dart';
import '../../core/theme/inspector_colors.dart';
import '../../core/theme/inspector_typography.dart';
import '../../core/theme/inspector_dimensions.dart';

class InspectorDetailPaneWidget extends StatefulWidget {
  final NetworkRequest request;
  final VoidCallback onClose;

  const InspectorDetailPaneWidget({
    super.key,
    required this.request,
    required this.onClose,
  });

  @override
  State<InspectorDetailPaneWidget> createState() => _InspectorDetailPaneWidgetState();
}

class _InspectorDetailPaneWidgetState extends State<InspectorDetailPaneWidget> {
  late DetailPaneController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DetailPaneController();
  }

  @override
  void dispose() {
    _controller.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tabs Header
        BaseContainer(
          color: InspectorColors.surface,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ValueListenableBuilder<DetailPaneStateData>(
                valueListenable: _controller,
                builder: (context, state, child) {
                  final tabs = ['Headers', 'Payload', 'Preview', 'Response'];
                  final tabWidths = [85.0, 80.0, 80.0, 90.0];
                  final moreButtonWidth = 32.0;

                  List<int> visibleTabs = [];
                  List<int> hiddenTabs = [];

                  double currentWidth = 40.0;
                  bool overflow = false;

                  for (int i = 0; i < tabs.length; i++) {
                    if (!overflow) {
                      double remainingTabsWidth = 0;
                      for (int j = i; j < tabs.length; j++) {
                        remainingTabsWidth += tabWidths[j];
                      }

                      if (currentWidth + remainingTabsWidth <= constraints.maxWidth) {
                        visibleTabs.add(i);
                        currentWidth += tabWidths[i];
                      } else {
                        if (currentWidth + tabWidths[i] + moreButtonWidth <= constraints.maxWidth) {
                          visibleTabs.add(i);
                          currentWidth += tabWidths[i];
                        } else {
                          overflow = true;
                          hiddenTabs.add(i);
                        }
                      }
                    } else {
                      hiddenTabs.add(i);
                    }
                  }

                  if (hiddenTabs.contains(state.selectedTabIndex) && visibleTabs.isNotEmpty) {
                    final lastVisible = visibleTabs.removeLast();
                    visibleTabs.add(state.selectedTabIndex);
                    hiddenTabs.remove(state.selectedTabIndex);
                    hiddenTabs.add(lastVisible);
                    hiddenTabs.sort();
                  }

                  return Row(
                    children: [
                      InkWell(
                        onTap: widget.onClose,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: InspectorDimensions.spacingM,
                            vertical: InspectorDimensions.spacingS,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: InspectorDimensions.iconM,
                            color: InspectorColors.textSecondary,
                          ),
                        ),
                      ),
                      ...visibleTabs.map((i) => _buildTab(tabs[i], i, state.selectedTabIndex)),
                      if (hiddenTabs.isNotEmpty) _buildMoreTabsButton(hiddenTabs, tabs, state.selectedTabIndex),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const Divider(height: 1, thickness: 1, color: InspectorColors.divider),
        Expanded(
          child: SelectionArea(
            child: ValueListenableBuilder<DetailPaneStateData>(
              valueListenable: _controller,
              builder: (context, state, child) {
                return _buildTabContent(state.selectedTabIndex);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String title, int index, int selectedIndex) {
    final isSelected = selectedIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => _controller.selectTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: InspectorDimensions.spacingL,
          vertical: InspectorDimensions.spacingS,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: BaseText(
          title,
          style: isSelected ? InspectorTypography.body.copyWith(fontWeight: FontWeight.bold) : InspectorTypography.body,
          color: isSelected ? InspectorColors.textPrimary : InspectorColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMoreTabsButton(List<int> hiddenTabs, List<String> tabs, int selectedIndex) {
    final isSelectedHidden = hiddenTabs.contains(selectedIndex);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<int>(
        tooltip: 'More tabs',
        position: PopupMenuPosition.under,
        offset: const Offset(0, 0),
        constraints: const BoxConstraints(),
        color: InspectorColors.background,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(InspectorDimensions.radiusXl),
        ),
        onSelected: _controller.selectTab,
        itemBuilder: (BuildContext context) {
          return hiddenTabs.map((i) {
            final isSelected = selectedIndex == i;
            return CustomPopupMenuItem<int>(
              value: i,
              text: tabs[i],
              isSelected: isSelected,
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: InspectorDimensions.spacingS,
            vertical: InspectorDimensions.spacingS,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelectedHidden ? primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Icon(
            Icons.keyboard_double_arrow_right,
            size: InspectorDimensions.iconM,
            color: isSelectedHidden ? InspectorColors.textPrimary : InspectorColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(int selectedIndex) {
    final req = widget.request;
    switch (selectedIndex) {
      case 0: // Headers
        return SingleChildScrollView(
          padding: const EdgeInsets.all(InspectorDimensions.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('General'),
              DetailRow(label: 'Request URL', value: req.url),
              DetailRow(label: 'Request Method', value: req.method),
              DetailRow(
                label: 'Status Code',
                value: '${req.statusCode ?? '-'} ${req.statusMessage ?? ''}',
              ),
              if (req.error != null) ...[
                const SizedBox(height: InspectorDimensions.spacingS),
                DetailRow(label: 'Error', value: req.error!),
              ],
              const SizedBox(height: InspectorDimensions.spacingL),
              const SectionTitle('Response Headers'),
              JsonViewerWidget(
                data: req.responseHeaders ?? <String, dynamic>{},
                key: const ValueKey('headers_response'),
                showToolbar: false,
                isScrollable: false,
              ),
              const SizedBox(height: InspectorDimensions.spacingL),
              const SectionTitle('Request Headers'),
              JsonViewerWidget(
                data: req.requestHeaders ?? <String, dynamic>{},
                key: const ValueKey('headers_request'),
                showToolbar: false,
                isScrollable: false,
              ),
            ],
          ),
        );
      case 1: // Payload
        final hasQuery = req.queryParameters != null && req.queryParameters!.isNotEmpty;
        final hasBody = req.requestData != null;

        if (!hasQuery && !hasBody) {
          return const BaseText(
            'No payload data',
            color: InspectorColors.textSecondary,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasQuery) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: SectionTitle('Query String Parameters'),
              ),
              Expanded(
                child: JsonViewerWidget(
                  data: req.queryParameters!,
                  key: const ValueKey('payload_query'),
                  initiallyExpanded: true,
                ),
              ),
            ],
            if (hasBody) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(12, hasQuery ? 16 : 12, 12, 8),
                child: const SectionTitle('Request Payload'),
              ),
              Expanded(
                child: JsonViewerWidget(
                  data: req.requestData,
                  key: const ValueKey('payload_body'),
                  initiallyExpanded: true,
                ),
              ),
            ],
          ],
        );
      case 2: // Preview (Raw JSON Viewer)
        if (req.responseData == null) {
          return const BaseText(
            'No response data',
            color: InspectorColors.textSecondary,
          );
        }
        return JsonViewerWidget(
          data: req.responseData,
          key: const ValueKey('preview'),
          initiallyExpanded: false,
        );
      case 3: // Response
        if (req.responseData == null) {
          return const BaseText(
            'No response data',
            color: InspectorColors.textSecondary,
          );
        }
        return JsonViewerWidget(
          data: req.responseData,
          key: const ValueKey('response'),
          initiallyExpanded: true,
        );
      default:
        return const SizedBox();
    }
  }
}
