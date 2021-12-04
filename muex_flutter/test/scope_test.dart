import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muex/muex.dart';
import 'package:muex_flutter/muex_flutter.dart';

import 'scope_test.mocks.dart';

@GenerateMocks([Update])
void main() {
  testWidgets('scope test', (WidgetTester tester) async {
    final state = Object();

    /// Test the [BuildContext.state] extension
    final viewKey = GlobalKey();
    await tester.pumpWidget(wrapLoop(
      state: state,
      view: SizedBox(
        key: viewKey,
      ),
    ));

    final context = viewKey.currentContext!;
    expect(context.state, state);

    /// Test the [BuildContext.dispatch] extension
    final upd = MockUpdate();
    var count = 0;
    when(upd.update(any)).thenAnswer((_) {
      count++;
      return None();
    });
    context.then(upd);
    expect(count, 1);
  });
}

