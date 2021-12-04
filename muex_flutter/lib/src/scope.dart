import 'package:muex/muex.dart';
import 'package:flutter/widgets.dart';

export 'package:muex/muex.dart' show
  Loop,
  Then;

class _LoopScope extends InheritedWidget {

  _LoopScope({
    Key? key,
    required this.loop,
    required Widget child
  }) : super(key: key, child: child);

  final Loop loop;

  @override
  bool updateShouldNotify(_LoopScope oldWidget) {
    return oldWidget.loop != this.loop;
  }
}

extension LoopExtensions on BuildContext {

  Loop get loop {
    final _LoopScope? scope = this.dependOnInheritedWidgetOfExactType();
    assert(scope != null);
    return scope!.loop;
  }

  Object get state => loop.state;

  void then(Then value) => loop.then(value);
}

@visibleForTesting
Widget wrapLoop({
    required Object state,
    Object? container,
    Then? initial,
    required Widget view,
  }) {
  return _LoopScope(
    loop: Loop(
      state: state,
      container: container,
      then: initial,
    ),
    child: view,
  );
}

void runLoop({
    required Object state,
    Object? container,
    Then? initial,
    required Widget view,
  }) {
  runApp(wrapLoop(
    state: state,
    container: container,
    initial: initial,
    view: view,
  ));
}

