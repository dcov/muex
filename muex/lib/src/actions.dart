import 'dart:async';

import 'package:meta/meta.dart';

@immutable
abstract class Action { }

typedef ActionCallback = Action Function();

class None implements Action {
  factory None() => const None._();
  const None._();
}

class Unchained implements Action {
  Unchained(this.actions);
  final Set<Action> actions;
}

class Chained implements Action {
  Chained(this.actions);
  final Set<Action> actions;
}

abstract class Update<T extends Object> implements Action {

  factory Update(_UpdateCallback<T> callback) = _CallbackUpdate<T>;

  Action update(covariant Object state);
}

abstract class Effect<T extends Object> implements Action {

  factory Effect(_EffectCallback<T> callback) = _CallbackEffect<T>;

  FutureOr<Action> effect(covariant Object container);
}

typedef _EffectCallback<T extends Object> = FutureOr<Action> Function(T container);

class _CallbackEffect<T extends Object> implements Effect<T> {

  _CallbackEffect(this.callback);

  final _EffectCallback<T> callback;

  @override
  FutureOr<Action> effect(T container) {
    return callback(container);
  }
}

typedef _UpdateCallback<T extends Object> = Action Function(T state);

class _CallbackUpdate<T extends Object> implements Update<T> {

  _CallbackUpdate(this.callback);

  final _UpdateCallback<T> callback;

  @override
  Action update(T state) {
    return callback(state);
  }
}
