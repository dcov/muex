part of '../model.dart';

class ModelSet<E> extends _ModelIterable<E> implements Set<E> {

  ModelSet(
    _DidGetCallback didGet,
    _DidUpdateCallback didUpdate,
    [Set<E> source = const {}]
  ) : super(didGet, didUpdate, Set<E>()..addAll(source));

  @override
  Set<E> get _source => super._source as Set<E>;

  @override
  Set<R> cast<R>() {
    _didGet();
    return _source.cast<R>();
  }

  @override
  Iterator<E> get iterator {
    _didGet();
    return _source.iterator;
  }

  @override
  E? lookup(Object? object) {
    _didGet();
    return _source.lookup(object);
  }

  @override
  bool containsAll(Iterable<Object?> other) {
    _didGet();
    return _source.containsAll(other);
  }

  @override
  Set<E> intersection(Set<Object?> other) {
    _didGet();
    return _source.intersection(other);
  }

  @override
  Set<E> union(Set<E> other) {
    _didGet();
    return _source.union(other);
  }

  @override
  Set<E> difference(Set<Object?> other) {
    _didGet();
    return _source.difference(other);
  }

  @override
  bool add(E value) {
    _debugEnsureUpdate();
    if (_source.add(value)) {
      _didUpdate();
      return true;
    }
    return false;
  }

  @override
  void addAll(Iterable<E> elements) {
    _debugEnsureUpdate();
    final int oldLength = _source.length;
    _source.addAll(elements);
    if (_source.length != oldLength) {
      _didUpdate();
    }
  }

  @override
  bool remove(Object? value) {
    _debugEnsureUpdate();
    if (_source.remove(value)) {
      _didUpdate();
      return true;
    }
    return false;
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    _debugEnsureUpdate();
    final int oldLength = _source.length;
    _source.removeAll(elements);
    if (_source.length != oldLength) {
      _didUpdate();
    }
  }

  @override
  void retainAll(Iterable<Object?> elements) {
    _debugEnsureUpdate();
    final int oldLength = _source.length;
    _source.retainAll(elements);
    if (_source.length != oldLength) {
      _didUpdate();
    }
  }

  @override
  void removeWhere(bool test(E element)) {
    _debugEnsureUpdate();
    final int oldLength = _source.length;
    _source.removeWhere(test);
    if (_source.length != oldLength) {
      _didUpdate();
    }
  }

  @override
  void retainWhere(bool test(E element)) {
    _debugEnsureUpdate();
    final int oldLength = _source.length;
    _source.retainWhere(test);
    if (_source.length != oldLength) {
      _didUpdate();
    }
  }

  @override
  void clear() {
    _debugEnsureUpdate();
    if (_source.isNotEmpty) {
      _source.clear();
      _didUpdate();
    }
  }
}
