part of '../model.dart';

class ModelMap<K, V> extends ModelCollection implements Map<K, V> {

  ModelMap(
    _DidGetCallback didGet,
    _DidUpdateCallback didUpdate,
    [Map<K, V> source = const {}]
  ) : this._source = Map<K, V>()..addAll(source),
      super(didGet, didUpdate);

  final Map<K, V> _source;

  @override
  Map<RK, RV> cast<RK, RV>() {
    _didGet();
    return _source.cast<RK, RV>();
  }

  @override
  bool containsValue(Object? value) {
    _didGet();
    return _source.containsValue(value);
  }

  @override
  bool containsKey(Object? key) {
    _didGet();
    return _source.containsKey(key);
  }

  @override
  V? operator[](Object? key) {
    _didGet();
    return _source[key];
  }

  @override
  Iterable<MapEntry<K, V>> get entries {
    _didGet();
    return _source.entries;
  }

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> f(K key, V value)) {
    _didGet();
    return _source.map(f);
  }

  @override
  void forEach(void f(K key, V value)) {
    _didGet();
    return _source.forEach(f);
  }

  @override
  Iterable<K> get keys {
    _didGet();
    return _source.keys;
  }

  @override
  Iterable<V> get values {
    _didGet();
    return _source.values;
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
  void operator []=(K key, V value) {
    _debugEnsureUpdate();
    if (value != _source[key]) {
      _source[key] = value;
      _didUpdate();
    }
  }

  @override
  void addAll(Map<K, V> other) {
    _debugEnsureUpdate();
    final int oldLength = _source.length;
    _source.addAll(other);
    if (_source.length != oldLength) {
      _didUpdate();
    }
  }

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    _debugEnsureUpdate();
    final int oldLength = _source.length;
    _source.addEntries(newEntries);
    if (_source.length != oldLength) {
      _didUpdate();
    }
  }

  @override
  V update(K key, V update(V value), {V ifAbsent()?}) {
    _debugEnsureUpdate();
    final V? oldValue = _source[key];
    final V result = _source.update(key, update, ifAbsent: ifAbsent);
    if (result != oldValue) {
      _didUpdate();
    }
    return result;
  }

  @override
  void updateAll(V update(K key, V value)) {
    _debugEnsureUpdate();
    bool didUpdate = false;
    _source.updateAll((K key, V value) {
      final V result = update(key, value);
      if (result != value) {
        didUpdate = true;
      }
      return result;
    });
    if (didUpdate) {
      _didUpdate();
    }
  }

  @override
  void removeWhere(bool predicate(K key, V value)) {
    _debugEnsureUpdate();
    final int oldLength = _source.length;
    _source.removeWhere(predicate);
    if (_source.length != oldLength) {
      _didUpdate();
    }
  }

  @override
  V putIfAbsent(K key, V ifAbsent()) {
    _debugEnsureUpdate();
    if (!_source.containsKey(key)) {
      _source[key] = ifAbsent();
      _didUpdate();
    }
    // We can safely assume that it won't be null.
    return _source[key]!;
  }

  @override
  V? remove(Object? key) {
    _debugEnsureUpdate();
    if (_source.containsKey(key)) {
      final V? result = _source.remove(key);
      _didUpdate();
      return result;
    }
    return null;
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
