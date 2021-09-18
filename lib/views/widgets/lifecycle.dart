import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

///
/// Widget Lifecycle Mixin
///
/// Adds more familar and unavailable lifecycle methods for StatefulWidgets in Flutter
/// that web developers may be more familar with in React, Vue, etc
///
mixin Lifecycle<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    // NOTE: SchedulerBinding still needed in screen child views vs. didDepsChange()
    SchedulerBinding.instance?.addPostFrameCallback((_) {
      onMounted();
    });

    super.initState();
  }

  /// Called only once, after [initState]
  void onMounted() {}
}
