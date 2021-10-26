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

abstract class Update implements _ThenAction {

  Then update(covariant Object state);
}

abstract class Effect implements _ThenAction {

  FutureOr<Then> effect(covariant Object container);
}

