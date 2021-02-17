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
    required Initial initial,
    Object? container,
    required Widget view
  }) {
  return _LoopScope(
    loop: Loop(
      initial: initial,
      container: container),
    child: view);
}

void runLoop({
    required Initial initial,
    Object? container,
    required Widget view,
  }) {
  runApp(wrapLoop(
    initial: initial,
    container: container,
    view: view));
}

