import 'package:muex/muex.dart';
import 'package:test/test.dart';

import '../utils.dart';

part 'list_test.dart';
part 'map_test.dart';
part 'set_test.dart';

class MockContext extends ModelContext {

  bool _canUpdate;

  @override
  void debugEnsureUpdate() {
    assert(_canUpdate);
  }

  @override
  void didGet<T extends Diff>(Model moel, DiffUpdate<T> updateDiff) { }

  @override
  void didUpdate<T extends Diff>(Model model, DiffUpdate<T> updateDiff) { }
}

void collectionsTest() {
  group('Collections', () {
    final MockContext context = MockContext();
    ModelContext.instance = context;
    listTest(context);
    setTest(context);
    mapTest(context);
  });
}
