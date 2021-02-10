import 'package:test/test.dart';

final throwsAssertionError = throwsA(isAssertionError);

final isAssertionError = isA<AssertionError>();

Matcher equalsMap(Map expected) {
  return _EqualsMap(expected);
}

class _EqualsMap extends Matcher {

  _EqualsMap(this._expected);

  final Map _expected;

  @override
  bool matches(item, Map matchState) {
    if (item is Map && item.length == _expected.length) {
      for (final MapEntry entry in item.entries) {
        if (!_expected.containsKey(entry.key) ||
            _expected[entry.key] != entry.value)
          return false;
      }
      return true;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    return description
        .add('equals map ')
        .addDescriptionOf(_expected);
  }

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (item is! Map) {
      return mismatchDescription
          .add(' item is not a Map ')
          .addDescriptionOf(item);
    } else if (item.length != _expected.length) {
      return mismatchDescription
          .add(' actual has a different length than expected')
          .add(' expected => ${_expected.length} ')
          .add(' actual => ${item.length}');
    } else {
      return mismatchDescription
          .add(' contents of actual don\'t match expected ')
          .add(' expected => ')
          .addDescriptionOf(_expected)
          .add(' actual => ')
          .addDescriptionOf(item);
    }
  }
}

class CallbackCounter {

  int count = 0;
  int tracker = 0;

  void call() {
    count++;
  }

  void expectDidNotChange() {
    expect(count, equals(tracker));
  }

  void expectChanged() {
    tracker++;
    expect(count, equals(tracker));
  }
}
