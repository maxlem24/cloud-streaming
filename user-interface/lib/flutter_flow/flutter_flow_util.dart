import 'package:flutter/material.dart';

abstract class FlutterFlowModel<T extends StatefulWidget> {
  void initState(BuildContext context) {}
  void dispose() {}
}

T createModel<T extends FlutterFlowModel>(BuildContext context, T Function() constructor) {
  final model = constructor();
  model.initState(context);
  return model;
}

extension WidgetListDivide on List<Widget> {
  List<Widget> divide(Widget spacer) {
    if (isEmpty) return this;
    final divided = <Widget>[];
    for (var i = 0; i < length; i++) {
      divided.add(this[i]);
      if (i != length - 1) divided.add(spacer);
    }
    return divided;
  }
}
