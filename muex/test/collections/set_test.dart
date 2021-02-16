part of 'collections_test.dart';

void setTest(MockContext context) {
  group('Set', () {
    final List<int> source = Iterable.generate(5).toList().cast<int>();
    final CallbackCounter counter = CallbackCounter();
    late ModelSet set;
    test('Setup', () {
      context._canUpdate = true;
      set = ModelSet((){}, counter, {...source.take(2)});
      expect(set, orderedEquals(source.take(2)));
    });
    test('Functionality', () {
      context._canUpdate = false;
      expect(() => set.add(source[2]), throwsAssertionError);
      expect(set, isNot(contains(source[2])));
      counter.expectDidNotChange();
      context._canUpdate = true;
      set.add(source[2]);
      expect(set, contains(source[2]));
      expect(set, hasLength(3));
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => set.addAll(source.getRange(3, 5)), throwsAssertionError);
      expect(set, isNot(containsAll(source.getRange(3, 5))));
      counter.expectDidNotChange();
      context._canUpdate = true;
      set.addAll(source.getRange(3, 5));
      expect(set, containsAllInOrder(source.getRange(3, 5)));
      expect(set, hasLength(5));
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => set.remove(source.first), throwsAssertionError);
      expect(set, contains(source.first));
      counter.expectDidNotChange();
      context._canUpdate = true;
      set.remove(source.first);
      expect(set, isNot(contains(source.first)));
      expect(set, hasLength(4));
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => set.removeAll(source.getRange(1, 3)), throwsAssertionError);
      expect(set, containsAllInOrder(source.getRange(1, 3)));
      counter.expectDidNotChange();
      context._canUpdate = true;
      set.removeAll(source.getRange(1, 3));
      expect(set, isNot(containsAll(source.getRange(1, 3))));
      expect(set, hasLength(2));
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => set.retainAll(source.getRange(3, 4)), throwsAssertionError);
      expect(set, contains(source[4]));
      counter.expectDidNotChange();
      context._canUpdate = true;
      set.retainAll(source.getRange(3, 4));
      expect(set, isNot(contains(source[4])));
      expect(set, hasLength(1));
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => set.removeWhere((e) => true), throwsAssertionError);
      expect(set, contains(source[3]));
      counter.expectDidNotChange();
      context._canUpdate = true;
      set.removeWhere((e) => e == source[3]);
      expect(set, isEmpty);
      counter.expectChanged();

      set.addAll(source.take(4));
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => set.retainWhere((e) => false), throwsAssertionError);
      expect(set, containsAllInOrder(source.take(4)));
      counter.expectDidNotChange();
      context._canUpdate = true;
      set.retainWhere((e) => e != source[0] && e != source[2]);
      expect(set, isNot(containsAll({source[0], source[2]})));
      expect(set, hasLength(2));
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => set.clear(), throwsAssertionError);
      expect(set, isNotEmpty);
      counter.expectDidNotChange();
      context._canUpdate = true;
      set.clear();
      expect(set, isEmpty);
      counter.expectChanged();
    });
  });
}
