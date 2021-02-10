part of 'collections_test.dart';

void listTest(MockContext context) {
  group('List', () {
  final CallbackCounter counter = CallbackCounter();
  final List<int> source = Iterable.generate(10).toList().cast<int>();
    ModelList list;
    test('Setup', () {
      list = ModelList(() {}, counter, source.take(2).toList());
      expect(list, orderedEquals(source.take(2)));
      expect(list, hasLength(2));
    });
    test('Functionality', () {
      context._canUpdate = false;
      // Expect that mutating list while context.canUpdate is false will
      // throw an AssertionError.
      expect(() => list[0] = source[2], throwsAssertionError);
      // Expect that the value wasn't updated.
      expect(list[0], source.first);
      counter.expectDidNotChange();
      context._canUpdate = true;
      list[0] = source[2];
      expect(list[0], source[2]);
      counter.expectChanged();

      context._canUpdate = false;
      // Expect that mutating list while context.canUpdate is false will
      // throw an AssertionError
      expect(() => list.first = source.first, throwsAssertionError);
      // Expect that the value wasn't updated.
      expect(list.first, source[2]);
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.first = source.first;
      expect(list.first, source.first);
      counter.expectChanged();

      context._canUpdate = false;
      // Expect that mutating list while context.canUpdate is false will
      // throw an AssertionError
      expect(() => list.last = source[2], throwsAssertionError);
      // Expect that the value wasn't updated.
      expect(list.last, source[1]);
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.last = source[2];
      expect(list.last, source[2]);
      counter.expectChanged();

      context._canUpdate = false;
      // Expect that mutating list while context.canUpdate is false will
      // throw an AssertionError
      expect(() => list.length = 0, throwsAssertionError);
      // Expect that the value wasn't updated.
      expect(list, hasLength(2));
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.length = 0;
      expect(list, isEmpty);
      counter.expectChanged();

      context._canUpdate = false;
      // Expect that mutating list while context.canUpdate is false will
      // throw an AssertionError
      expect(() => list.add(source.first), throwsAssertionError);
      // Expect that the value wasn't updated.
      expect(list, isEmpty);
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.add(source.first);
      expect(list[0], source.first);
      counter.expectChanged();

      context._canUpdate = false;
      // Expect that mutating list while context.canUpdate is false will
      // throw an AssertionError
      expect(() => list.addAll(source.getRange(1, 3)), throwsAssertionError);
      // Expect that the value wasn't updated.
      expect(list, hasLength(1));
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.addAll(source.getRange(1, 3));
      expect(list, orderedEquals(source.getRange(0, 3)));
      counter.expectChanged();

      context._canUpdate = false;
      // Expect that mutating list while context.canUpdate is false will
      // throw an AssertionError
      expect(() => list.clear(), throwsAssertionError);
      // Expect that the value wasn't updated.
      expect(list, isNotEmpty);
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.clear();
      expect(list, isEmpty);
      counter.expectChanged();

      final List<int> slice = source.getRange(0, 5).toList();
      list.addAll(slice);
      counter.expectChanged();

      context._canUpdate = false;
      // Expect that mutating list while context.canUpdate is false will
      // throw an AssertionError
      expect(() => list.shuffle(), throwsAssertionError);
      // Expect that the value wasn't updated.
      expect(list, containsAllInOrder(slice));
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.shuffle();
      expect(list, isNot(orderedEquals(slice)));
      counter.expectChanged();

      list.clear();
      counter.expectChanged();
      list.addAll(slice);
      counter.expectChanged();

      context._canUpdate = false;
      // Expect that mutating list while context.canUpdate is false will
      // throw an AssertionError
      expect(() => list.sort((a, b) => b.hashCode.compareTo(a.hashCode)), throwsAssertionError);
      expect(list, containsAllInOrder(slice));
      counter.expectDidNotChange();
      context._canUpdate = true;
      slice.sort((a, b) => b.hashCode.compareTo(a.hashCode));
      list.sort((a, b) => b.hashCode.compareTo(a.hashCode));
      expect(list, orderedEquals(slice));
      counter.expectChanged();

      list.clear();
      counter.expectChanged();

      context._canUpdate = false;
      // Expect that mutating list while context.canUpdate is false will
      // throw an AssertionError
      expect(() => list.insert(0, source.first), throwsAssertionError);
      // Expect that the value wasn't updated.
      expect(list, isEmpty);
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.insert(0, source.first);
      expect(list.first, source.first);
      counter.expectChanged();

      context._canUpdate = false;
      // Expect that mutating list while context.canUpdate is false will
      // throw an AssertionError
      expect(() => list.insertAll(1, source.getRange(1, 3)), throwsAssertionError);
      // Expect that the value wasn't updated.
      expect(list, hasLength(1));
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.insertAll(1, source.getRange(1, 3));
      expect(list, orderedEquals(source.getRange(0, 3)));
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => list.setAll(0, source.getRange(3, 6)), throwsAssertionError);
      expect(list, containsAllInOrder(source.getRange(0, 3)));
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.setAll(0, source.getRange(3, 6));
      expect(list, orderedEquals(source.getRange(3, 6)));
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => list.remove(source[3]), throwsAssertionError);
      expect(list, contains(source[3]));
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.remove(source[3]);
      expect(list, isNot(contains(source[3])));
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => list.removeAt(0), throwsAssertionError);
      expect(list[0], source[4]);
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.removeAt(0);
      expect(list, isNot(contains(source[4])));
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => list.removeLast(), throwsAssertionError);
      expect(list.first, source[5]);
      counter.expectDidNotChange();
      context._canUpdate = true;
      expect(list.removeLast(), source[5]);
      expect(list, isEmpty);
      counter.expectChanged();

      list.addAll(slice);
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => list.removeWhere((e) => true), throwsAssertionError);
      expect(list, containsAllInOrder(slice));
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.removeWhere((e) => slice.indexOf(e) == 0);
      expect(list, isNot(contains(slice.first)));
      counter.expectChanged();

      list.insert(0, slice.first);
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => list.retainWhere((e) => false), throwsAssertionError);
      expect(list, containsAllInOrder(slice));
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.retainWhere((e) => e != slice.first && e != slice.last);
      expect(list, orderedEquals(slice.getRange(1, 4)));
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => list.setRange(0, 3, source.getRange(5, 10), 2), throwsAssertionError);
      expect(list, containsAllInOrder(slice.getRange(1, 4)));
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.setRange(0, 3, source.getRange(5, 10), 2);
      expect(list, orderedEquals(source.getRange(7, 10)));
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => list.removeRange(0, 3), throwsAssertionError);
      expect(list, containsAllInOrder(source.getRange(7, 10)));
      expect(list, hasLength(3));
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.removeRange(0, 3);
      expect(list, isEmpty);
      counter.expectChanged();

      list.addAll(slice);
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => list.fillRange(0, 5, source.last), throwsAssertionError);
      expect(list, containsAllInOrder(slice));
      expect(list, hasLength(5));
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.fillRange(0, 5, source.last);
      expect(list, orderedEquals(Iterable.generate(5, (_) => source.last)));
      counter.expectChanged();

      context._canUpdate = false;
      expect(() => list.replaceRange(0, 5, source), throwsAssertionError);
      expect(list, containsAllInOrder(Iterable.generate(5, (_) => source.last)));
      counter.expectDidNotChange();
      context._canUpdate = true;
      list.replaceRange(0, 5, source);
      expect(list, orderedEquals(source));
      counter.expectChanged();
    });
  });
}
