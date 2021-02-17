// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widgets_test.dart';

// **************************************************************************
// ModelGenerator
// **************************************************************************

class _$TestModel implements TestModel {
  _$TestModel({
    required int count,
  }) {
    this._count = count;
  }
  int get count {
    ModelContext.instance
        .didGet(this, (_$TestModelDiff diff) => diff.count = true);
    return _count;
  }

  late int _count;
  set count(int value) {
    ModelContext.instance.debugEnsureUpdate();
    if (value != _count) {
      _count = value;
      ModelContext.instance
          .didUpdate(this, (_$TestModelDiff diff) => diff.count = true);
    }
  }

  @override
  _$TestModelDiff createDiff() => _$TestModelDiff();
}

class _$TestModelDiff implements Diff {
  bool count = false;
  @override
  bool compare(_$TestModelDiff other) {
    return (this.count && other.count);
  }
}
