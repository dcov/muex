import 'package:test/test.dart';

import 'collections/collections_test.dart';
import 'loop_test.dart';

void main() {
  group('muex', () {
    collectionsTest();
    loopTest();
  });
}
