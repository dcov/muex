import 'dart:async';

import 'package:meta/meta.dart';

@immutable
abstract class _Action { }

abstract class Initial implements _Action {

  Init init();
}

class Init {

  Init({
    required this.state,
    required this.then
  });

  /// The state to initialize the loop with.
  final Object state;

  /// An Action, Effect, or Set<Action>, that should happen after this initialization.
  final Then then;
}

abstract class _ThenAction implements _Action { }

class Then {

  factory Then(_ThenAction action) {
    assert(action is Update || action is Effect,
        'Then can only take an Update or Effect.');

    return Then._(action);
  }

  factory Then.all(Set<_ThenAction> actions) {
    assert(() {
      for (final subAction in actions) {
        if (subAction is! Update && subAction is! Effect) {
          return false;
        }
      }
      return true;
    }(),
    'Then.all can only take a Set with Update or Effect values.');
    return Then._(actions);
  }

  factory Then.done() => Then._(null);

  Then._(this.action);

  final Object? action;
}

abstract class Update<T extends Object> implements _ThenAction {

  factory Update(_UpdateCallback<T> callback) = _CallbackUpdate<T>;

  Then update(covariant Object state);
}

typedef _UpdateCallback<T extends Object> = Then Function(T state);

class _CallbackUpdate<T extends Object> implements Update<T> {

  _CallbackUpdate(this.callback);

  final _UpdateCallback<T> callback;

  @override
  Then update(T state) {
    return callback(state);
  }
}

abstract class Effect<T extends Object> implements _ThenAction {

  factory Effect(_EffectCallback<T> callback) = _CallbackEffect<T>;

  FutureOr<Then> effect(covariant Object container);
}

typedef _EffectCallback<T extends Object> = FutureOr<Then> Function(T container);

class _CallbackEffect<T extends Object> implements Effect<T> {

  _CallbackEffect(this.callback);

  final _EffectCallback<T> callback;

  @override
  FutureOr<Then> effect(T container) {
    return callback(container);
  }
}
