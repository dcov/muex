part of '../model.dart';

class ModelList<E> extends _ModelIterable<E> implements List<E> {

  ModelList(
    _DidGetCallback didGet,
    _DidUpdateCallback didUpdate,
    [List<E> source = const []]
  ) : super(didGet, didUpdate, List<E>()..addAll(source));

  @override
  List<E> get _source => super._source;

  @override
  List<R> cast<R>() {
    _didGet();
    return _source.cast<R>();
  }

  @override
  Iterable<E> get reversed {
    _didGet();
    return _source.reversed;
  }

  @override
  E operator [](int index) {
    _didGet();
    return _source[index];
  }

  @override
  int indexOf(E element, [int start = 0]) {
    _didGet();
    return _source.indexOf(element, start);
  }

  @override
  int lastIndexOf(E element, [int start]) {
    _didGet();
    return _source.lastIndexOf(element, start);
  }

  @override
  int indexWhere(bool test(E element), [int start = 0]) {
    _didGet();
    return _source.indexWhere(test, start);
  }

  @override
  int lastIndexWhere(bool test(E element), [int start]) {
    _didGet();
    return _source.lastIndexWhere(test, start);
  }

  @override
  Iterable<E> getRange(int start, int end) {
    _didGet();
    return _source.getRange(start, end);
  }

  @override
  Map<int, E> asMap() {
    _didGet();
    return _source.asMap();
  }

  @override
  List<E> sublist(int start, [int end]) {
    _didGet();
    return _source.sublist(start, end);
  }

  @override
  List<E> operator +(List<E> other) {
    _didGet();
    return _source + other;
  }

  @override
  void operator []=(int index, E value) {
    _debugEnsureUpdate();
    if (value != _source[index]) {
      _source[index] = value;
      _didUpdate();
    }
  }

  @override
  void set first(E value) {
    _debugEnsureUpdate();
    if (value != _source.first) {
      _source.first = value;
      _didUpdate();
    }
  }

  @override
  void set last(E value) {
    _debugEnsureUpdate();
    if (value != _source.last) {
      _source.last = value;
      _didUpdate();
    }
  }

  @override
  set length(int newLength) {
    _debugEnsureUpdate();
    if (newLength != _source.length) {
      _source.length = newLength;
      _didUpdate();
    }
  }

  @override
  void add(E value) {
    _debugEnsureUpdate();
    _source.add(value);
    _didUpdate();
  }

  @override
  void addAll(Iterable<E> iterable) {
    _debugEnsureUpdate();
    final int oldLength = _source.length;
    _source.addAll(iterable);
    if (_source.length != oldLength) {
      _didUpdate();
    }
  }

  @override
  void sort([int compare(E a, E b)]) {
    _debugEnsureUpdate();
    _source.sort(compare);
    _didUpdate();
  }

  @override
  void shuffle([Random random]) {
    _debugEnsureUpdate();
    _source.shuffle(random);
    _didUpdate();
  }

  @override
  void clear() {
    _debugEnsureUpdate();
    if (_source.isNotEmpty) {
      _source.clear();
      _didUpdate();
    }
  }

  @override
  void insert(int index, E element) {
    _debugEnsureUpdate();
    _source.insert(index, element);
    _didUpdate();
  }



  @override
  void insertAll(int index, Iterable<E> iterable) {
    _debugEnsureUpdate();
    final int oldLength = _source.length;
    _source.insertAll(index, iterable);
    if (_source.length != oldLength) {
      _didUpdate();
    }
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    _debugEnsureUpdate();
    // Convert it to a list in case it's a lazy iterable.
    final List<E> list = iterable.toList();
    if (list.isNotEmpty) {
      _source.setAll(index, list);
      _didUpdate();
    }
  }

  @override
  bool remove(Object value) {
    _debugEnsureUpdate();
    if (_source.remove(value)) {
      _didUpdate();
      return true;
    }
    return false;
  }

  @override
  E removeAt(int index) {
    _debugEnsureUpdate();
    final E value = _source.removeAt(index);
    _didUpdate();
    return value;
  }

  @override
  E removeLast() {
    _debugEnsureUpdate();
    final E value = _source.removeLast();
    _didUpdate();
    return value;
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
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _debugEnsureUpdate();
    _source.setRange(start, end, iterable, skipCount);
    if (end - start > 0) {
      _didUpdate();
    }
  }

  @override
  void removeRange(int start, int end) {
    _debugEnsureUpdate();
    _source.removeRange(start, end);
    if (end - start > 0) {
      _didUpdate();
    }
  }

  @override
  void fillRange(int start, int end, [E fillValue]) {
    _debugEnsureUpdate();
    _source.fillRange(start, end, fillValue);
    if (end - start > 0) {
      _didUpdate();
    }
  }

  @override
  void replaceRange(int start, int end, Iterable<E> replacement) {
    _debugEnsureUpdate();
    _source.replaceRange(start, end, replacement);
    if (end - start > 0) {
      _didUpdate();
    }
  }
}
