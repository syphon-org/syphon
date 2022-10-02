import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart' as redux;

typedef Dispatch = dynamic Function(dynamic action);
typedef Selector<State, Output> = Output Function(State state);
typedef EqualityFn<T> = bool Function(T a, T b);

class StoreHook<S> extends Hook<redux.Store<S>> {
  @override
  HookState<redux.Store<S>, Hook<redux.Store<S>>> createState() => StoreHookState<S>();
}

class StoreHookState<S> extends HookState<redux.Store<S>, StoreHook<S>> {
  @override
  redux.Store<S> build(BuildContext context) {
    return StoreProvider.of<S>(context);
  }
}

redux.Store<S> useStore<S>() => use(StoreHook<S>());

Dispatch useDispatch<AppState>() => useStore<AppState>().dispatch;

Output? useSelector<State, Output>(
  Selector<State, Output> selector, {
  EqualityFn? equality,
  Output? fallback,
}) {
  final store = useStore<State>();
  final snap = useStream<Output>(
    store.onChange.map(selector).distinct(equality),
    initialData: selector(store.state),
  );

  return snap.data;
}
