
const _didGetSignature = 'ModelContext.instance.didGet';

const _didUpdateSignature = 'ModelContext.instance.didUpdate';

const _debugEnsureUpdateCall = 'ModelContext.instance.debugEnsureUpdate();';

const _lateModifier = 'late ';

class FieldBuffer {

  late String name;

  late String type;

  late bool hasSetter;

  bool get _isNullable => type.endsWith('?');

  String asModelConstructorArgument() {
    StringBuffer result = StringBuffer(!_isNullable ? 'required ' : '');
    if (hasSetter) {
      result.write('$type $name,\n');
    } else {
      result.write('this.$name,\n');
    }
    return result.toString();
  }

  String asModelConstructorBlock() {
    return hasSetter ? '    this._$name = $name;\n' : '';
  }

  String asModelField() {
    if (!hasSetter) {
      return '  final $type $name;\n';
    }

    return '  $type get $name {\n'
           '    $_didGetSignature(this, (diff) => diff.${name} = true);\n'
           '    return _$name;\n'
           '  }\n'
           '  ${!_isNullable ? _lateModifier : ''}$type _$name;\n'
           '  set $name($type value) {\n'
           '    $_debugEnsureUpdateCall\n'
           '    if (value != _$name) {\n'
           '      _$name = value;\n'
           '      $_didUpdateSignature(this, (diff) => diff.$name = true);\n'
           '    }\n'
           '  }\n';
  }

  String asDiffField() {
    return hasSetter ? '  bool $name = false;\n' : '';
  }

  String asDiffComparison() {
    return hasSetter ? '(this.$name && other.$name)' : '';
  }
}

class CollectionFieldBuffer extends FieldBuffer {

  late String collectionLiteral;

  @override
  String asModelConstructorArgument() {
    final result = StringBuffer('$type $name');
    if (!_isNullable)
      result.write(' = const $collectionLiteral');
    result.write(',\n');
    return result.toString();
  }

  @override
  String asModelConstructorBlock() {
    return '    if ($name != null) {\n'
           '      this._$name = Model$type(_${name}InnerGet, _${name}InnerUpdate, $name);\n'
           '    }\n';
  }

  @override
  String asModelField() {
    final buffer = StringBuffer();

    const _lateModifier = 'late ';

    if (!hasSetter) {
      buffer.write(
        '  $type get $name => _$name;\n'
        '  ${_lateModifier}Model$type _$name;\n'
      );
    } else {
      String valueUpdate;
      if (_isNullable) {
        valueUpdate = 
        '    if (value == null) {\n'
        '      _$name = null;\n'
        '    } else {\n'
        '      _$name = Model$type(_${name}InnerGet, _${name}InnerUpdate, value);\n'
        '    }\n';
      } else {
        valueUpdate =
        '    _$name = Model$type(_${name}InnerGet, _${name}InnerUpdate, value);\n';
      }
      buffer.write(
        '  $type get $name {\n'
        '    $_didGetSignature(this, (diff) => diff.${name} = true);\n'
        '    return _$name;\n'
        '  }\n'
        '  ${_lateModifier}Model$type _$name;\n'
        '  set $name($type value) {\n'
        '    if (value == _$name)\n'
        '      return;\n'
        '$valueUpdate'
        '    $_didUpdateSignature(this, (diff) => diff.${name} = true);\n'
        '  }\n'
      );
    }

    buffer.write(
      '  void _${name}InnerGet() {\n'
      '    $_didGetSignature(this, (diff) => diff.${name}Inner = true);\n'
      '  }\n'
      '  void _${name}InnerUpdate() {\n'
      '    $_debugEnsureUpdateCall\n'
      '    $_didUpdateSignature(this, (diff) => diff.${name}Inner = true);\n'
      '  }\n'
    );

    return buffer.toString();
  }

  @override
  String asDiffField() {
    final buffer = StringBuffer();
    if (hasSetter) {
      buffer.write('  bool $name = false;\n');
    }
    buffer.write('  bool ${name}Inner = false;\n');
    return buffer.toString();
  }

  @override
  String asDiffComparison() {
    final buffer = StringBuffer();
    if (hasSetter) {
      buffer.write('(this.$name && other.$name) ||\n');
    }
    buffer.write('(this.${name}Inner && other.${name}Inner)');
    return buffer.toString();
  }
}

class ModelBuffer {

  /// The name of the model that's being generated.
  late String modelName;

  String primaryTypeParameters = '';

  String secondaryTypeParameters = '';

  List<FieldBuffer> fields = List<FieldBuffer>.empty(growable: true);

  // Return the model name minus the dollar sign.
  String get _generatedModelName => r'_$' + modelName;

  String get _modelConstructor {
    if (fields.isEmpty)
      return '';

    final buffer = StringBuffer();
    var fieldsContainVariableOrCollection = false;
    buffer.write('  $_generatedModelName({\n');
    for (final field in fields) {
      buffer.write('    ${field.asModelConstructorArgument()}');
      fieldsContainVariableOrCollection = 
          fieldsContainVariableOrCollection || field.hasSetter || field is CollectionFieldBuffer;
    }
    buffer.write('  })');
    if (fieldsContainVariableOrCollection) {
      buffer.write(' {\n');
      for (final field in fields) {
        buffer.write(field.asModelConstructorBlock());
      }
      buffer.write('  }\n');
    } else {
      buffer.write(';\n');
    }

    return buffer.toString();
  }

  String get _modelFields {
    final buffer = StringBuffer();
    for (final field in fields) {
      buffer.write(field.asModelField());
    }
    return buffer.toString();
  }

  String get _diffName => '${_generatedModelName}Diff';

  String get _diffFields {
    final buffer = StringBuffer();
    for (final field in fields) {
      buffer.write(field.asDiffField());
    }
    return buffer.toString();
  }

  String get _diffComparison {
    if (fields.isEmpty)
      return 'false';

    final buffer = StringBuffer();
    for (int i = 0; i < fields.length; i++) {
      final comparison = fields[i].asDiffComparison();
      if (comparison.isEmpty)
        continue;

      if (buffer.isNotEmpty) {
        buffer.write(' ||\n');
      }

      buffer.write(comparison);
    }
    return buffer.isNotEmpty ? buffer.toString() : 'false';
  }

  @override
  String toString() =>
    'class ${_generatedModelName}${primaryTypeParameters} implements ${modelName}${secondaryTypeParameters} {\n'
    '$_modelConstructor'
    '$_modelFields'
    '  @override\n'
    '  $_diffName createDiff() => $_diffName();\n'
    '}\n'
    '\n'
    'class $_diffName implements Diff {\n'
    '$_diffFields'
    '  @override\n'
    '  bool compare($_diffName other) {\n'
    '    return $_diffComparison;\n'
    '  }\n'
    '}\n';
}

