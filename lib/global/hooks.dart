import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

(T, T Function(T)) useStateful<T>(T initialData) {
  final hook = use(_StateHook(initialData: initialData));
  return (hook.value, (T updated) => hook.value = updated);
}

class _StateHook<T> extends Hook<ValueNotifier<T>> {
  const _StateHook({required this.initialData});

  final T initialData;

  @override
  _StateHookState<T> createState() => _StateHookState();
}

class _StateHookState<T> extends HookState<ValueNotifier<T>, _StateHook<T>> {
  late final _state = ValueNotifier<T>(hook.initialData)..addListener(_listener);

  @override
  void dispose() {
    _state.dispose();
  }

  @override
  ValueNotifier<T> build(BuildContext context) => _state;

  void _listener() {
    setState(() {});
  }

  @override
  Object? get debugValue => _state.value;

  @override
  String get debugLabel => 'useState<$T>';
}
