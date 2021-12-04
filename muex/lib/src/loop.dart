import 'dart:async';

import 'actions.dart';
import 'model.dart';

typedef ConnectionStateChangedCallback = void Function();

class Connection {

  Connection._(
    this._loop,
    this._onConnectionStateChanged);
  
  final _ContextLoop _loop;
  final ConnectionStateChangedCallback _onConnectionStateChanged;
  Map<Model, Diff>? _captured;

  void then(Then value) {
    _loop.then(value);
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
    Then? then,
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

  void then(Then value);
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
  void then(Then value, [Object? creator = null]) {
    assert(value.action != null, 
        'Loop.then called with a Then.done value. Loop.then can only be called with a Then.update, '
        'Then.effect, or Then.all value.');
    _beginActionSequence(value.action);
  }

  void _beginActionSequence(Object? action) {
    _initializeUpdateState();
    _processAction(action);
    _finalizeUpdateState();
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

  void _processAction(Object? action) {
    if (action == null)
      return;

    bool processAsUpdateOrEffect(Object action) {
      assert(!_actionIsProcessing,
          'Tried to process an Action while a previous Action was still processing.');

      if (action is Update) {
        _updateIsProcessing = true;
        final result = action.update(state);
        _updateIsProcessing = false;
        _processAction(result.action);

        return true;
      } else if (action is Effect) {
        _effectIsProcessing = true;
        final result = action.effect(container);
        _effectIsProcessing = false;

        if (result is Future<Then>) {
          result.then((Then async_result) {
            if (_currentUpdate == null) {
              _beginActionSequence(async_result.action);
            } else {
              _processAction(async_result.action);
            }
          });
        } else {
          _processAction(result.action);
        }

        return true;
      }

      return false;
    }

    if (!processAsUpdateOrEffect(action)) {
      assert(action is Set, 'Expected a set of actions');
      for (final a in (action as Set)) {
        final processed = processAsUpdateOrEffect(a);
        assert(processed, 'Set of actions contained an invalid object.');
      }
    }
  }

  void _init(Then then) {
    _initialIsProcessing = true;
    _processAction(then.action);
    _initialIsProcessing = false;
  }

  Map<Model, Diff> _capture(void fn()) {
    assert(_currentCapture == null, 
        'Tried to start a capture while another capture was in progress.');

    _currentCapture = <Model, Diff>{};

    final fnResult = fn() as dynamic;
    assert(fnResult is! Future,
        'Capture function returned a Future. Capture functions can only be '
        'synchronous.');

    final captureResult = _currentCapture!;
    _currentCapture = null;
    return captureResult;
  }
}

