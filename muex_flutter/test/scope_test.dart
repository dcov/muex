import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:muex/muex.dart';
import 'package:muex_flutter/muex_flutter.dart';

import 'mocks.dart';

void scopeTest() {
  testWidgets('scope', (WidgetTester tester) async {
    final state = Object();
    final initial = MockInitial();
    when(initial.init()).thenReturn(Init(state: state, then: Then.done()));

    /// Test the [BuildContext.state] extension
    final viewKey = GlobalKey();
    await tester.pumpWidget(wrapLoop(
      initial: initial,
      view: SizedBox(
        key: viewKey)));

    final context = viewKey.currentContext;
    expect(context.state, state);

    /// Test the [BuildContext.dispatch] extension
    final upd = MockUpdate();
    var count = 0;
    when(upd.update(any)).thenAnswer((_) {
      count++;
      return Then.done();
    });
    context.then(Then(upd));
    expect(count, 1);
  });
}

