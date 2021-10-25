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

  void then(Then value) {
    _loop.then(value);
  }

  void close() {
    _loop._disconnect(this);
  }

  Map<Model, Diff>? _captured;
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
    required Initial initial,
    Object? container,
  }) {
    final loop = _ContextLoop(initial, container);
    ModelContext.instance = loop;
    return loop;
  }

  Object get container;

  Object get state;

  Connection connect(ConnectionStateChangedCallback callback);

  void then(Then value);
}

class _ContextLoop implements ModelContext, Loop {

  _ContextLoop(
      Initial initial,
      Object? container,
    ) {
    this.container = container ?? Object();
    _processInitial(initial);
  }

  @override
  late final Object container;

  // This is initialized once in _processInitial.
  @override
  late final Object state;

  final _connections = List<Connection>.empty(growable: true);

  @override
  Connection connect(ConnectionStateChangedCallback callback) {
    final connection = Connection._(this, callback);
    _connections.add(connection);
    return connection;
  }

  void _disconnect(Connection connection) {
    _connections.remove(connection);
  }

  Map<Model, Diff>? _currentCapture;
  Map<Model, Diff>? _currentUpdate;
  bool _initialIsProcessing = false;
  bool _updateIsProcessing = false;
  bool _effectIsProcessing = false;

  bool get _thenActionIsProcessing {
    return _updateIsProcessing || _effectIsProcessing;
  }

  @override
  void didGet<T extends Diff>(Model model, DiffUpdate<T> updateDiff) {
    if (_currentCapture != null) {
      final diff = _currentCapture!.putIfAbsent(model, model.createDiff) as T;
      updateDiff(diff);
    }
  }

  @override
  void didUpdate<T extends Diff>(Model model, DiffUpdate<T> updateDiff) {
    // We don't track updates while the Initial action and any resulting
    // ThenActions are processing.
    if (_initialIsProcessing)
      return;

    debugEnsureUpdate();

    final diff = _currentUpdate!.putIfAbsent(model, model.createDiff) as T;
    updateDiff(diff);
  }

  @override
  void debugEnsureUpdate() {
    // We don't track updates while the Initial action and any resulting
    // ThenActions are processing.
    if (_initialIsProcessing)
      return;

    assert(_currentUpdate != null && _updateIsProcessing,
        'A Model was mutated outside of an Update.');
  }

  Map<Model, Diff> _capture(void fn()) {
    assert(_currentCapture == null, 
        'Tried to start a capture while another capture was in progress.');

    // Initialize the map to track any values that are used.
    _currentCapture = <Model, Diff>{};

    // Call the function that we're tracking.
    final fnResult = fn() as dynamic;
    assert(fnResult is! Future,
        'Capture function returned a Future. Capture functions can only be '
        'synchronous.');

    // We're done tracking values that are used so we'll reset our internal state.
    final captureResult = _currentCapture!;
    _currentCapture = null;
    return captureResult;
  }

  void _update(Update update) {
    assert(_currentUpdate == null,
        'Tried to start an Update loop while another Update loop was in progress.');
    assert(_currentCapture == null,
        'Tried to start an Update loop while a capture was in progress.');

    _currentUpdate = <Model, Diff>{};
    _processUpdate(update);
    _dispatchUpdates(_currentUpdate!);
    _currentUpdate = null;
  }

  void _dispatchUpdates(Map<Model, Diff> updates) {
    if (updates.isEmpty) {
      return;
    }
    // Because dispatching updates might cause some Connections to be removed,
    // We have to iterate over the Connections by index to avoid a
    // ConcurrentModificationError.
    for (int i = 0; i < _connections.length; i++) {
      final connection = _connections[i];
      connection._didUpdate(updates);
    }
  }

  void _processInitial(Initial initial) {
    _initialIsProcessing = true;
    final init = initial.init();
    state = init.state;
    _maybeThen(init.then, initial);
    _initialIsProcessing = false;
  }

  void _processUpdate(Update action) {
    _updateIsProcessing = true;
    final result = action.update(state);
    _updateIsProcessing = false;
    _maybeThen(result, action);
  }

  void _processEffect(Effect action) {
    _effectIsProcessing = true;
    final result = action.effect(container);
    _effectIsProcessing = false;
    _maybeThen(result, action);
  }

  void _maybeThen(FutureOr<Then> value, Action creator) {
    if (value is Future<Then>) {
      value.then((Then result) {
        _maybeThen(result, creator);
      });
    } else if (value.action != null) {
      then(value);
    }
  }

  @override
  void then(Then value) {
    assert(value.action != null, 
        'Loop.then called with a Then.done value. Loop.then can only be called with a Then.update, '
        'Then.effect, or Then.all value.');

    // If the Then.action value is processed as a ThenAction, then it is not a
    // Set<ThenAction>, and we don't need to do anything else.
    if (!_maybeProcessThenAction(value.action)) {
      // It is not a ThenAction, so it has to be a Set<ThenAction> and we need
      // to individually process each of the sub actions.
      for (final subAction in (value.action as Set<ThenAction>)) {
        _maybeProcessThenAction(subAction);
      }
    }
  }

  bool _maybeProcessThenAction(Object? value) {
    assert(!_thenActionIsProcessing,
        'Tried to process an Action while a previous Action was still processing.');

    if (value is Update) {
      // If the Initial action is being processed we don't want to track any
      // updates since we shouldn't have any connections at this point.
      // Likewise, if we're already tracking updates it would be an error to
      // reset the tracking state.
      if (_initialIsProcessing || _currentUpdate != null) {
        // Just process the update without worrying about tracking.
        _processUpdate(value);
      } else {
        // We are not processing the Initial action and haven't started tracking
        // updates yet, so we'll start doing so now.
        _update(value);
      }
      return true;
    } else if (value is Effect) {
      _processEffect(value);
      return true;
    }

    return false;
  }
}

