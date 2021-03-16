import 'package:muex/muex.dart';
import 'package:flutter/widgets.dart';

import 'scope.dart';

@optionalTypeArgs
mixin ConnectionCaptureStateMixin<W extends StatefulWidget> on State<W> {

  Loop? _loop;
  Connection? _connection;

  @protected
  void capture(StateSetter setState);

  void _handleChange([bool canRebuild = true]) {
    bool rebuild = false;
    _connection!.capture((_) {
      capture((fn) {
        fn();
        rebuild = true;
      });
    });
    if (rebuild && canRebuild) {
      setState(() { });
    }
  }

  void _maybeConnect() {
    if (_connection == null) {
        /// Connect to the loop and use [_handleChange] as the callback so that it can rebuild if the state changes
        _connection = _loop!.connect(_handleChange);

        /// Call [_handleChange] so that we can capture the state we need to capture, but don't allow a rebuild since a
        /// rebuild has already been scheduled when this is called.
        _handleChange(false);
    }
  }

  void _maybeDisconnect() {
    _connection?.close();
    _connection = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loop = context.loop;

    /// Update [_loop] and [_connection] if the loop has changed.
    if (loop != _loop) {
      _loop = loop;
      _maybeDisconnect();
      _maybeConnect();
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    _maybeDisconnect();
  }

  @override
  void reassemble() {
    super.reassemble();
    _maybeDisconnect();
  }

  @protected
  Widget performBuild(BuildContext context);

  /// Ensures that a [Connection] is established so that it can track changes.
  ///
  /// This should be called everytime [build] is called because the [Connection]
  /// is disposed every time the [State] is deactivated, or reassembled, and the
  /// only way to re-establish the [Connection] is through the [build] method.
  @override
  Widget build(BuildContext context) {
    _maybeConnect();
    return performBuild(context);
  }
}

mixin ConnectionBuildStateMixin<W extends StatefulWidget> on State<W> {

  Loop? _loop;
  Connection? _connection;

  void _handleChange() => setState(() { });

  void _maybeConnect() {
    if (_connection == null) {
      _connection = _loop!.connect(_handleChange);
    }
  }

  void _maybeDisconnect() {
    _connection?.close();
    _connection = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loop = context.loop;
    if (loop != _loop) {
      _loop = loop;
      _maybeDisconnect();
      _maybeConnect();
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    _maybeDisconnect();
  }

  @override
  void reassemble() {
    super.reassemble();
    _maybeDisconnect();
  }

  @protected
  Widget performBuild(BuildContext context);

  @override
  Widget build(BuildContext context) {
    _maybeConnect();
    late Widget result;
    _connection!.capture((_) {
      result = performBuild(context);
    });
    return result;
  }
}

/// Tracks the usage of [Model]s, and rebuilds whenever they are updated.
class Connector extends StatefulWidget {

  Connector({
    Key? key,
    required this.builder,
  }) : super(key: key);

  /// Called to obtain the resulting [Widget].
  ///
  /// This is called at least once to track any mutable values, and then is only
  /// called whenever the tracked values change.
  final WidgetBuilder builder;

  @override
  _ConnectorState createState() => _ConnectorState();
}

class _ConnectorState extends State<Connector> with ConnectionBuildStateMixin {

  @override
  Widget performBuild(BuildContext context) {
    return widget.builder(context);
  }
}
