import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart' as redux;

class _UseStoreHook<S> extends Hook<redux.Store<S>> {
  @override
  HookState<redux.Store<S>, Hook<redux.Store<S>>> createState() => _UseStoreHookState<S>();
}

class _UseStoreHookState<S> extends HookState<redux.Store<S>, _UseStoreHook<S>> {
  @override
  redux.Store<S> build(BuildContext context) => StoreProvider.of<S>(context);
}

typedef Dispatch = dynamic Function(dynamic action);
typedef Selector<State, Output> = Output Function(State state);
typedef EqualityFn<T> = bool Function(T a, T b);

redux.Store<S> useStore<S>() => use(_UseStoreHook());
Dispatch useDispatch<S>() => useStore<S>().dispatch;

Output useSelector<State, Output>(Selector<State, Output> selector, [EqualityFn? equalityFn]) {
  final store = useStore<State>();
  final snap = useStream<Output>(
    store.onChange.map(selector).distinct(equalityFn),
    initialData: selector(store.state),
  );

  return snap.data!;
}
