import 'package:flutter/foundation.dart';

abstract class InspectorControllerContract<T> extends ValueNotifier<T> {
  InspectorControllerContract(super.value);

  void init();
  void disposeController() {
    dispose();
  }
}
