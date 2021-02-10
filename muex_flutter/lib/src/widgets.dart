import 'package:muex/muex.dart';
import 'package:flutter/widgets.dart';

import 'scope.dart';

@optionalTypeArgs
mixin ConnectionStateMixin<W extends StatefulWidget> on State<W> {

  Loop _loop;
  Connection _connection;

  @protected
  void capture(StateSetter setState);

  void _handleChange([bool canRebuild = true]) {
    bool rebuild = false;
    _connection.capture((_) {
      capture((fn) {
        fn();
        rebuild = true;
      });
    });
    if (rebuild && canRebuild)
      setState(() { });
  }

  void _connect() {
      /// Connect to the loop and use [_handleChange] as the callback so that it can rebuild if the state changes
      _connection = _loop.connect(_handleChange);

      /// Call [_handleChange] so that we can capture the state we need to capture, but don't allow a rebuild since a
      /// rebuild has already been scheduled when this is called.
      _handleChange(false);
  }

  void _disconnect() {
    _connection.close();
    _connection = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loop = context.loop;
    assert(loop != null);

    /// Update [_loop] and [_connection] if the loop has changed.
    if (loop != _loop) {
      _loop = loop;
      _connection?.close();
      _connect();
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    /// The [Connection] is disposed here because the [StatefulElement] will
    /// either be disposed right after, or it will be moved to a different
    /// location in the tree, in which case we'll reactivate it during [build]
    /// so that we can preserve the ordering of the tree of [Connector]s.
    /// 
    /// This ordering is important because changes are dispatched from
    /// first-added to last-added (top-to-bottom), because in some cases
    /// ancestor [Connector]s end up removing descendant [Connector]s after a
    /// change occurs. In which case it doesn't make sense to notify a defunct
    /// [Connector] of changes, and avoids unnecessary checks as to the state of
    /// its lifecycle.
    ///
    /// The [Connection] might have already been disposed by a call to
    /// [reassemble] (i.e. hot-reload), which has led to this element being
    /// deactivated, hence the check.
    if (_connection != null) {
      _disconnect();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    /// The [Connection] is disposed during hot-reloads so that any changes to
    /// the values of a [Model] can be tracked.
    if (_connection != null) {
      _disconnect();
    }
  }

  /// Ensures that a [Connection] is established so that it can track changes.
  ///
  /// This should be called everytime [build] is called because the [Connection]
  /// is disposed every time the [State] is deactivated, or reassembled, and the
  /// only way to re-establish the [Connection] is through the [build] method.
  @protected
  @mustCallSuper
  void buildCheck() {
    if (_connection == null) {
      assert(_loop != null);
      _connect();
    }
  }
}

/// Tracks the usage of [Model]s, and rebuilds whenever they are updated.
class Connector extends StatefulWidget {

  Connector({
    Key key,
    @required this.builder,
  }) : assert(builder != null),
       super(key: key);

  /// Called to obtain the resulting [Widget].
  ///
  /// This is called at least once to track any mutable values, and then is only
  /// called whenever the tracked values change.
  final WidgetBuilder builder;

  @override
  _ConnectorState createState() => _ConnectorState();
}

class _ConnectorState extends State<Connector> with ConnectionStateMixin {

  Widget _child;

  @override
  void capture(StateSetter setState) {
    setState((){ 
      _child = widget.builder(context);
      assert(_child != null, 'Connector.builder returned null');
    });
  }

  @override
  Widget build(BuildContext context) {
    buildCheck();
    return _child;
  }
}

