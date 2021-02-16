part of 'collections_test.dart';

void mapTest(MockContext context) {
  group('Map', () {
    final Map<int, int> source = Map.fromIterables(
      Iterable.generate(5), Iterable.generate(5)
    );
    final CallbackCounter counter = CallbackCounter();
    late ModelMap map;
    test('Setup', () {
      context._canUpdate = true;
      map = ModelMap((){}, counter, Map.from(source));
      expect(map, equalsMap(source));
    });
    test('Functionality', () {
      context._canUpdate = false;
      expect(() => map[4] = null, throwsAssertionError);
      expect(map, containsPair(4, source[4]));
      counter.expectDidNotChange();
      context._canUpdate = true;
      map[4] = null;
      expect(map, isNot(containsValue(source[4])));
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => map.clear(), throwsAssertionError);
      expect(map, isNotEmpty);
      counter.expectDidNotChange();
      context._canUpdate = true;
      map.clear();
      expect(map, isEmpty);
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => map.addAll(source), throwsAssertionError);
      expect(map, isEmpty);
      counter.expectDidNotChange();
      context._canUpdate = true;
      map.addAll(source);
      expect(map, equalsMap(source));
      counter.expectChanged();

      map.clear();
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => map.addEntries(source.entries), throwsAssertionError);
      expect(map, isEmpty);
      counter.expectDidNotChange();
      context._canUpdate = true;
      map.addEntries(source.entries);
      expect(map, equalsMap(source));
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => map.update(0, (v) => null, ifAbsent: () => null), throwsAssertionError);
      expect(map, equalsMap(source));
      counter.expectDidNotChange();
      context._canUpdate = true;
      map.update(
        0,
        (v) => null,
        ifAbsent: () => null
      );
      expect(map, containsPair(0, null));
      counter.expectChanged();

      map[0] = source[0];
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => map.updateAll((k, v) => null), throwsAssertionError);
      expect(map, equalsMap(source));
      counter.expectDidNotChange();
      context._canUpdate = true;
      map.updateAll((k, v) => (k == source[4] ? null : v));
      expect(map, containsPair(4, null));
      counter.expectChanged();

      map[4] = source[4];
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => map.removeWhere((k, v) => true), throwsAssertionError);
      expect(map, equalsMap(source));
      counter.expectDidNotChange();
      context._canUpdate = true;
      map.removeWhere((k, v) => true);
      expect(map, isEmpty);
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => map.putIfAbsent(source[0], () => null), throwsAssertionError);
      expect(map, isEmpty);
      counter.expectDidNotChange();
      context._canUpdate = true;
      map.putIfAbsent(0, () => source[0]);
      expect(map, containsPair(0, source[0]));
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => map.remove(0), throwsAssertionError);
      expect(map, equalsMap({0 : source[0]}));
      counter.expectDidNotChange();
      context._canUpdate = true;
      map.remove(0);
      expect(map, isEmpty);
      counter.expectChanged();
    });
  });
}
