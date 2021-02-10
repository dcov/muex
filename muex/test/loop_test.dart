import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:muex/muex.dart';
import 'package:test/test.dart';

class EmptyContainer { }

class TestModel implements Model {
  int count = 0;

  // This method is implemented by the model code generator in normal usage.
  @override
  TestDiff createDiff() => TestDiff();
}

// This class is generated by the model code generator in normal usage.
class TestDiff implements Diff {
  bool count = false;

  @override
  bool compare(TestDiff other) {
    return count && other.count;
  }
}

// ignore: must_be_immutable
class MockInitial extends Mock implements Initial { }

// ignore: must_be_immutable
class MockUpdate extends Mock implements Update { }

// ignore: must_be_immutable
class MockEffect extends Mock implements Effect { }

void loopTest() {
  group('Loop', () {
    final state = TestModel();
    final upd = MockUpdate();
    final eff = MockEffect();

    Loop loop;
    test('Initialization functionality', () {
      when(upd.update(state)).thenAnswer((_) {
        state.count++;
        return Then.done();
      });

      final initial = MockInitial();
      when(initial.init()).thenReturn(Init(state: state, then: Then(upd)));

      loop = Loop(initial: initial);

      // Expect that the loop correctly initializes its state with the [MockInitial]'s state value.
      expect(loop.state, state);

      // Expect that MockAction was called, thus mutating the state
      expect(state.count, 1);
    });


    test('Update that returns an Update ', () {
      state.count = 0;
      when(upd.update(state)).thenAnswer((_) {
        state.count++;

        if (state.count < 3)
          return Then(upd);

        return Then.done();
      });
      loop.then(Then(upd));
      expect(state.count, 3);
    });

    test('Update that returns an Effect', () {
      state.count = 0;
      when(upd.update(state)).thenAnswer((_) {
        state.count++;
        if (state.count < 2)
          return Then(eff);

        return Then.done();
      });

      when(eff.effect(any)).thenAnswer((_) {
        return Then(upd);
      });

      loop.then(Then(upd));
      expect(state.count, 2);
    });

    test('Asynchronous Effect', () async {
      state.count = 0;
      final completer = Completer<Then>();

      when(upd.update(state)).thenAnswer((_) {
        state.count++;
        if (state.count < 2)
          return Then(eff);

        return Then.done();
      });

      when(eff.effect(any)).thenAnswer((_) => completer.future);

      loop.then(Then(upd));

      // Count should not have reached 2 yet because the effect is being waited on.
      expect(state.count, 1);

      // Complete the effect.
      completer.complete(Then(upd));

      // We have to await the completer here so that it's guaranteed that the loop has finished awaiting it.
      await completer.future;

      // The count should now be 2.
      expect(state.count, 2);
    });

    test('Update/Effect that return a Set of messages', () {
      // CASE: Test that it processes a Set return value correctly.
      var ordering = "";
      when(upd.update(state)).thenAnswer((_) {

        // Update the event so that it doesn't return it anything when it's ran again
        when(upd.update(state)).thenAnswer((_) {
          ordering += "e";
          return Then.done();
        });

        ordering += "e";
        // Note the ordering in which eff and upd are placed in the Set
        return Then.all({
          eff,
          upd
        });
      });

      when(eff.effect(any)).thenAnswer((_) {
        
        // Update the effect so that it doesn't return it anything when it's ran again
        when(eff.effect(any)).thenAnswer((_) {
          ordering += "f";
          return Then.done();
        });

        ordering += "f";
        return Then.all({
          upd,
          eff
        });
      });

      loop.then(Then(upd));

      expect(ordering, "efefe");
    });

    test('Update that returns a Set with an async Effect', () async {
      var ordering = "";
      final completer = Completer();

      when(upd.update(state)).thenAnswer((_) {

        // Update the effect so that it doesn't return it anything when it's ran again
        when(upd.update(state)).thenAnswer((_) {
          ordering += "e";
          return Then.done();
        });

        ordering += "e";
        return Then.all({
          eff,
          upd
        });
      });

      when(eff.effect(any)).thenAnswer((_) async {
        await completer.future;

        // The next time effect is processed it'll be synchronous and won't return anything.
        when(eff.effect(any)).thenAnswer((_) {
          ordering += "f";
          return Then.done();
        });

        ordering += "f";
        return Then.all({
          upd,
          eff
        });
      });

      loop.then(Then(upd));

      expect(ordering, "ee");

      completer.complete();

      await completer.future;

      expect(ordering, "eefef");
    });

    test('Connection opened with no captured state', () {
      int callbackCount = 0;
      final connection = loop.connect(() {
        callbackCount++;
      });

      when(upd.update(state)).thenAnswer((_) {
        state.count++;
        return Then.done();
      });

      loop.then(Then(upd));
      expect(callbackCount, 0);

      connection.close();
    });

    test('Connection opened with captured state', () {
      int callbackCount = 0;
      final connection = loop.connect(() {
        callbackCount++;
      });

      /// For this test we need the [ModelContext] which the [Loop] implementation also implements.
      /// In normal usage [ModelContext] is only used by code generated [Model]s.
      final ModelContext context = loop as ModelContext;

      when(upd.update(state)).thenAnswer((_) {
        context.didUpdate(state, (TestDiff diff) {
          diff.count = true;
        });
        return Then.done();
      });

      connection.capture((_) {
        context.didGet(state, (TestDiff diff) {
          diff.count = true;
        });
      });

      loop.then(Then(upd));
      expect(callbackCount, 1);

      connection.close();
    });
  });
}

