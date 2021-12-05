import 'dart:async';

import 'actions.dart';
import 'model.dart';

typedef ConnectionStateChangedCallback = void Function();

class Connection {

  Connection._(
    this._loop,
    this._onConnectionStateChanged,
  );
  
  final _ContextLoop _loop;
  final ConnectionStateChangedCallback _onConnectionStateChanged;
  Map<Model, Diff>? _captured;

  void then(Action action) {
    _loop.then(action);
  }

  void close() {
    _loop._disconnect(this);
  }

  void capture(void fn(Object state)) {
    _captured = _loop._capture(() {
      fn(_loop.state);
    });
  }

  void _didUpdate(Map<Model, Diff> updates) {
    if (_captured?.isNotEmpty == true) {
      for (final update in updates.entries) {
        final diff = _captured![update.key];
        if (diff != null && diff.compare(update.value)) {
          _captured = null;
          _onConnectionStateChanged();
          return;
        }
      }
    }
  }
}

abstract class Loop {

  factory Loop({
    required Object state,
    Object? container,
    Action? then,
  }) {
    final loop = _ContextLoop(state, container ?? Object());
    ModelContext.instance = loop;
    if (then != null) {
      loop._init(then);
    }
    return loop;
  }

  Object get container;

  Object get state;

  Connection connect(ConnectionStateChangedCallback callback);

  FutureOr<void> then(Action action);
}

class _ContextLoop implements ModelContext, Loop {

  _ContextLoop(this.state, this.container);

  @override
  final Object state;

  @override
  final Object container;

  final List<Connection> _connections = <Connection>[];
  final Set<Connection> _needRemoving = <Connection>{};
  bool _dispatchInProgress = false;

  Map<Model, Diff>? _currentCapture;
  Map<Model, Diff>? _currentUpdate;
  bool _initialIsProcessing = false;
  bool _updateIsProcessing = false;
  bool _effectIsProcessing = false;

  bool get _actionIsProcessing {
    return _updateIsProcessing || _effectIsProcessing;
  }

  @override
  Connection connect(ConnectionStateChangedCallback callback) {
    final connection = Connection._(this, callback);
    _connections.add(connection);
    return connection;
  }

  void _disconnect(Connection connection) {
    if (_dispatchInProgress) {
      _needRemoving.add(connection);
    } else {
      _connections.remove(connection);
    }
  }

  Map<Model, Diff> _capture(void fn()) {
    assert(_currentCapture == null, 
        'Tried to start a capture while another capture was in progress.');

    _currentCapture = <Model, Diff>{};

    final fnResult = fn() as dynamic;
    assert(fnResult is! Future,
        'Capture function returned a Future. Capture functions must be synchronous.');

    final captureResult = _currentCapture!;
    _currentCapture = null;
    return captureResult;
  }

  @override
  void didGet<T extends Diff>(Model model, DiffUpdate<T> updateDiff) {
    if (_currentCapture != null) {
      final diff = _currentCapture!.putIfAbsent(model, model.createDiff) as T;
      updateDiff(diff);
    }
  }

  // Callers of this should call [debugEnsureUpdate] first.
  @override
  void didUpdate<T extends Diff>(Model model, DiffUpdate<T> updateDiff) {
    // We don't track updates while the Initial action and any resulting
    // actions are processing.
    if (_initialIsProcessing)
      return;

    final diff = _currentUpdate!.putIfAbsent(model, model.createDiff) as T;
    updateDiff(diff);
  }

  @override
  void debugEnsureUpdate() {
    assert(_initialIsProcessing || (_currentUpdate != null && _updateIsProcessing),
        'A Model was mutated outside of an Update.');
  }

  @override
  FutureOr<void> then(Action action) {
    _initializeUpdateState();
    final result = _processAction(action);
    _finalizeUpdateState();
    return result;
  }

  void _initializeUpdateState() {
    assert(_currentCapture == null);
    assert(_currentUpdate == null);
    _currentUpdate = <Model, Diff>{};
  }

  void _finalizeUpdateState() {
    assert(_currentUpdate != null);
    final state_updates = _currentUpdate!;
    _currentUpdate = null;

    if (state_updates.isEmpty) {
      return;
    }

    for (final connection in _connections) {
      connection._didUpdate(state_updates);
    }

    if (_needRemoving.isNotEmpty) {
      for (final connection in _needRemoving) {
        _connections.remove(connection);
      }
      _needRemoving.clear();
    }
  }

  void _init(Action action) {
    _initialIsProcessing = true;
    _processAction(action);
    _initialIsProcessing = false;
  }

  FutureOr<void> _processAction(Action action) {
    assert(!_actionIsProcessing,
        'Tried to process an Action while a previous Action was still processing.');

    if (action is Unchained) {
      return _processUnchained(action);
    } else if (action is Chained) {
      return _processChained(action);
    } else if (action is Update) {
      return _processUpdate(action);
    } else if (action is Effect) {
      return _processEffect(action);
    } else {
      assert(action is None);
    }
  }

  FutureOr<void> _processUnchained(Unchained unchained) {
    final futures = <Future<void>>[];
    for (final action in unchained.actions) {
      final result = _processAction(action);
      if (result is Future) {
        futures.add(result);
      }
    }

    if (futures.isNotEmpty) {
      final completer = Completer<void>();
      var remaining = futures.length;
      for (final future in futures) {
        future.then((_) {
          assert(remaining > 0);
          remaining--;
          if (remaining == 0) {
            completer.complete();
          }
        });
      }
      return completer.future;
    }
  }

  FutureOr<void> _processChained(Chained chained) {
    var i = 0;
    FutureOr<void> nextInChain([Completer<void>? completer]) {
      if (i < chained.actions.length) {
        final action = chained.actions.elementAt(i);
        i += 1;

        FutureOr<void> result;
        if (_currentUpdate == null) {
          result = then(action);
        } else {
          result = _processAction(action);
        }

        if (result is Future<void>) {
          completer ??= Completer<void>();
          result.then((_) {
            nextInChain(completer);
          });
          return completer.future;
        } else {
          return nextInChain(completer);
        }
      } else if (completer != null) {
        completer.complete();
      }
    }
    return nextInChain();
  }

  FutureOr<void> _processUpdate(Update upd) {
    _updateIsProcessing = true;
    final result = upd.update(state);
    _updateIsProcessing = false;
    return _processAction(result);
  }

  FutureOr<void> _processEffect(Effect eff) {
    _effectIsProcessing = true;
    final result = eff.effect(container);
    _effectIsProcessing = false;

    if (result is Future<Action>) {
      final completer = Completer<void>();
      result.then((Action action) {
        FutureOr<void> nextResult;
        if (_currentUpdate == null) {
          nextResult = then(action);
        } else {
          nextResult = _processAction(action);
        }
        if (nextResult is Future<void>) {
          nextResult.then((_) {
            completer.complete();
          });
        } else {
          completer.complete();
        }
      });
      return completer.future;
    } else {
      return _processAction(result);
    }
  }
}

