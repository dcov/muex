import 'dart:async';

import 'package:meta/meta.dart';

@immutable
abstract class Action { }

abstract class ThenAction implements Action { }

class Then {

  factory Then(ThenAction action) {
    assert(action is Update || action is Effect,
        'Then can only take an Update or Effect.');

    return Then._(action);
  }

  factory Then.all(Set<ThenAction> actions) {
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

abstract class Initial implements Action {

  Init init();
}

abstract class Update implements ThenAction {

  Then update(covariant Object state);
}

abstract class Effect implements ThenAction {

  FutureOr<Then> effect(covariant Object container);
}

