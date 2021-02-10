import 'dart:math';

part 'collections/collection.dart';
part 'collections/iterable.dart';
part 'collections/list.dart';
part 'collections/map.dart';
part 'collections/set.dart';

typedef DiffUpdate<T extends Diff> = void Function(T diff);

abstract class Diff {
  bool compare(covariant Diff other);
}

abstract class Model {
  Diff createDiff();
}

abstract class ModelContext {

  static ModelContext get instance {
    assert(_instance != null,
      "Tried to access ModelContext.instance before it was set");
    return _instance;
  }
  static ModelContext _instance;
  static set instance(ModelContext value) {
    _instance = value;
  }

  void didGet<T extends Diff>(Model model, DiffUpdate<T> updateDiff);

  void didUpdate<T extends Diff>(Model model, DiffUpdate<T> updateDiff);

  void debugEnsureUpdate();
}

