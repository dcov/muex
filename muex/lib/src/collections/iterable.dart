part of '../model.dart';

abstract class _ModelIterable<E> extends ModelCollection implements Iterable<E> {

  _ModelIterable(
    _DidGetCallback didGet,
    _DidUpdateCallback didUpdate,
    this._source
  ) : super(didGet, didUpdate);

  final Iterable<E> _source;
  
  @override
  Iterator<E> get iterator {
    _didGet();
    return _source.iterator;
  }

  @override
  Iterable<E> followedBy(Iterable<E> other) {
    _didGet();
    return _source.followedBy(other);
  }

  @override
  Iterable<T> map<T>(T f(E e)) {
    _didGet();
    return _source.map(f);
  }

  @override
  Iterable<E> where(bool test(E element)) {
    _didGet();
    return _source.where(test);
  }

  @override
  Iterable<T> whereType<T>() {
    _didGet();
    return _source.whereType();
  }

  @override
  Iterable<T> expand<T>(Iterable<T> f(E element)) {
    _didGet();
    return _source.expand<T>(f);
  }

  @override
  bool contains(Object element) {
    _didGet();
    return _source.contains(element);
  }

  @override
  void forEach(void f(E element)) {
    _didGet();
    _source.forEach(f);
  }

  @override
  E reduce(E combine(E value, E element)) {
    _didGet();
    return _source.reduce(combine);
  }

  @override
  T fold<T>(T initialValue, T combine(T previousValue, E element)) {
    _didGet();
    return _source.fold<T>(initialValue, combine);
  }

  @override
  bool every(bool test(E element)) {
    _didGet();
    return _source.every(test);
  }

  @override
  String join([String separator = ""]) {
    _didGet();
    return _source.join(separator);
  }

  @override
  bool any(bool test(E element)) {
    _didGet();
    return _source.any(test);
  }

  @override
  List<E> toList({bool growable = true}) {
    _didGet();
    return _source.toList(growable: growable);
  }

  @override
  Set<E> toSet() {
    _didGet();
    return _source.toSet();
  }

  @override
  int get length {
    _didGet();
    return _source.length;
  }

  @override
  bool get isEmpty {
    _didGet();
    return _source.isEmpty;
  }

  @override
  bool get isNotEmpty {
    _didGet();
    return _source.isNotEmpty;
  }

  @override
  Iterable<E> take(int count) {
    _didGet();
    return _source.take(count);
  }

  @override
  Iterable<E> takeWhile(bool test(E value)) {
    _didGet();
    return _source.takeWhile(test);
  }

  @override
  Iterable<E> skip(int count) {
    _didGet();
    return _source.skip(count);
  }

  @override
  Iterable<E> skipWhile(bool test(E value)) {
    _didGet();
    return _source.skipWhile(test);
  }

  @override
  E get first {
    _didGet();
    return _source.first;
  }

  @override
  E get last {
    _didGet();
    return _source.last;
  }

  @override
  E get single {
    _didGet();
    return _source.single;
  }

  @override
  E firstWhere(bool test(E element), {E orElse()}) {
    _didGet();
    return _source.firstWhere(test, orElse: orElse);
  }

  @override
  E lastWhere(bool test(E element), {E orElse()}) {
    _didGet();
    return _source.lastWhere(test, orElse: orElse);
  }

  @override
  E singleWhere(bool test(E element), {E orElse()}) {
    _didGet();
    return _source.singleWhere(test, orElse: orElse);
  }

  @override
  E elementAt(int index) {
    _didGet();
    return _source.elementAt(index);
  }
}
