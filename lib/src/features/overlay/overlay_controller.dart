import 'package:flutter/material.dart';
import '../../core/contracts/inspector_controller_contract.dart';

class OverlayStateData {
  final bool isOpen;
  final Offset? fabPosition;
  final Rect? windowRect;

  OverlayStateData({
    this.isOpen = false,
    this.fabPosition,
    this.windowRect,
  });

  OverlayStateData copyWith({
    bool? isOpen,
    Offset? fabPosition,
    Rect? windowRect,
  }) {
    return OverlayStateData(
      isOpen: isOpen ?? this.isOpen,
      fabPosition: fabPosition ?? this.fabPosition,
      windowRect: windowRect ?? this.windowRect,
    );
  }
}

class OverlayController extends InspectorControllerContract<OverlayStateData> {
  OverlayController() : super(OverlayStateData());

  @override
  void init() {}

  void toggleOpen(bool isOpen) {
    value = value.copyWith(isOpen: isOpen);
  }

  void updateFabPosition(Offset delta) {
    if (value.fabPosition != null) {
      value = value.copyWith(
        fabPosition: Offset(
          value.fabPosition!.dx + delta.dx,
          value.fabPosition!.dy + delta.dy,
        ),
      );
    }
  }

  void setInitialFabPosition(Offset pos) {
    value = value.copyWith(fabPosition: pos);
  }

  void setWindowRect(Rect rect) {
    value = value.copyWith(windowRect: rect);
  }
}
