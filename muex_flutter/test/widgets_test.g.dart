// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widgets_test.dart';

// **************************************************************************
// ModelGenerator
// **************************************************************************

class _$TestModel implements TestModel {
  _$TestModel({
    int count,
  }) {
    this._count = count;
  }
  int get count {
    ModelContext.instance.didGet(this, (diff) => diff.count = true);
    return _count;
  }

  int _count;
  set count(int value) {
    ModelContext.instance.debugEnsureUpdate();
    if (value != _count) {
      _count = value;
      ModelContext.instance.didUpdate(this, (diff) => diff.count = true);
    }
  }

  @override
  __$TestModelDiff createDiff() => __$TestModelDiff();
}

class __$TestModelDiff implements Diff {
  bool count = false;
  @override
  bool compare(__$TestModelDiff other) {
    return (this.count && other.count);
  }
}
