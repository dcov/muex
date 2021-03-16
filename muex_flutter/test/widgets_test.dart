import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muex/muex.dart';
import 'package:muex_flutter/muex_flutter.dart';

import 'widgets_test.mocks.dart';

part 'widgets_test.g.dart';

abstract class TestModel extends Model {

  factory TestModel({
    required int count
  }) = _$TestModel;

  int get count;
  set count(int value);
}

class TestWidget extends StatefulWidget {

  TestWidget({
    Key? key,
    required this.callback,
  }) : super(key: key);

  final VoidCallback callback;

  @override
  _TestWidgetState createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> with ConnectionCaptureStateMixin {

  @override
  void capture(_) {
    widget.callback();
  }

  @override
  Widget performBuild(BuildContext context) {
    return const SizedBox();
  }
}

@GenerateMocks([Initial, Update])
void widgetsTest() {
  group('widgets', () {
    final model = TestModel(count: 0);
    final initial = MockInitial();
    /// The initial will return [model] so that we can update it later
    when(initial.init()).thenReturn(Init(state: model, then: Then.done()));

    final upd = MockUpdate();
    /// The action will increment the model count in order to trigger rebuilds in the tests below
    when(upd.update(any)).thenAnswer((_) {
      model.count++;
      return Then.done();
    });

    testWidgets('ConnectionStateMixin', (WidgetTester tester) async {
      final viewKey = GlobalKey();
      int callbackCount = 0;
      await tester.pumpWidget(wrapLoop(
        initial: initial,
        view: TestWidget(
          key: viewKey,
          callback: () {
            /// Use the model count value so that changes to it are tracked
            final _ = model.count;
            callbackCount++;
          })));

      expect(callbackCount, 1);

      viewKey.currentContext!.then(Then(upd));
      await tester.pumpAndSettle();

      /// Expect that the callback was called as a result of the dispatched action
      expect(callbackCount, 2);
    });

    testWidgets('Connector', (WidgetTester tester) async {
      /// The number of times the [Connector] widget below has called its builder
      int connectorBuildCount = 0;
      /// The [BuildContext] the [Connector] widget below provides to its builder
      late BuildContext connectorContext;
      /// Insert the [Connector] into the tree
      await tester.pumpWidget(wrapLoop(
        initial: initial,
        view: Connector(
          builder: (BuildContext context) {
            /// Increment the build count
            connectorBuildCount++;
            /// Update the context
            connectorContext  = context;

            /// Use the state so that it can be tracked, and we can rebuild when it changes
            final TestModel state = context.state as TestModel;
            return SizedBox(width: state.count.toDouble(), height: state.count.toDouble());
          })));

      /// The [Connector] should have only built once so far
      expect(connectorBuildCount, 1);

      /// Dispatch the action
      connectorContext.then(Then(upd));
      await tester.pumpAndSettle();

      /// The [Connector] should have rebuilt due to the action that was dispatched
      expect(connectorBuildCount, 2);
    });

    testWidgets('Connector tree', (WidgetTester tester) async {
      final viewKey = GlobalKey();
      int rootBuildCount = 0;
      int nodeBuildCount = 0;
      int leafBuildCount = 0;

      await tester.pumpWidget(wrapLoop(
        initial: initial,
        view: SizedBox(
          key: viewKey,
          child: Connector(
            builder: (_) {
              rootBuildCount++;
              final _ = model.count;
              return Connector(
                builder: (_) {
                  nodeBuildCount++;
                  final _ = model.count;
                  return Connector(
                    builder: (_) {
                      leafBuildCount++;
                      final _ = model.count;
                      return SizedBox();
                    });
                });
            }))));

      expect(rootBuildCount, 1);
      expect(nodeBuildCount, 1);
      expect(leafBuildCount, 1);

      viewKey.currentContext!.then(Then(upd));
      await tester.pumpAndSettle();

      expect(rootBuildCount, 2);
      expect(nodeBuildCount, 2);
      expect(leafBuildCount, 2);
    });
  });
}

