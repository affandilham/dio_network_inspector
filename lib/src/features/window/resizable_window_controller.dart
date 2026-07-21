import 'package:flutter/material.dart';
import '../../core/contracts/inspector_controller_contract.dart';
import '../../core/theme/inspector_dimensions.dart';

class ResizableWindowController extends InspectorControllerContract<Rect> {
  final ValueChanged<Rect>? onRectChanged;

  ResizableWindowController(super.initialRect, {this.onRectChanged});

  @override
  void init() {}

  void updateRect(double dLeft, double dTop, double dWidth, double dHeight) {
    double newLeft = value.left + dLeft;
    double newTop = value.top + dTop;
    double newWidth = value.width + dWidth;
    double newHeight = value.height + dHeight;

    if (newWidth < InspectorDimensions.minWindowWidth) {
      newLeft = value.left;
      newWidth = value.width;
    }
    if (newHeight < InspectorDimensions.minWindowHeight) {
      newTop = value.top;
      newHeight = value.height;
    }

    value = Rect.fromLTWH(newLeft, newTop, newWidth, newHeight);
    onRectChanged?.call(value);
  }

  void shiftRect(Offset delta) {
    value = value.shift(delta);
    onRectChanged?.call(value);
  }
}
