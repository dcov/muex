part of '../model.dart';

typedef _DidGetCallback = void Function();

typedef _DidUpdateCallback = void Function();

abstract class ModelCollection {

  ModelCollection(this._didGet, this._didUpdate);

  final _DidGetCallback _didGet;

  final _DidUpdateCallback _didUpdate;

  void _debugEnsureUpdate() {
    ModelContext.instance.debugEnsureUpdate();
  }
}
