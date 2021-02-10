import 'package:build_test/build_test.dart';
import 'package:muex_gen/src/model_buffer.dart'; 
import 'package:muex_gen/src/model_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

const _sourceName = 'sample_model';
const _source =
'''
library $_sourceName;

import 'package:muex/muex.dart';
import 'package:meta/meta.dart';

part '$_sourceName.g.dart';

abstract class Child extends Model {

  String get string;

  int count;
}

abstract class Inherited {

  String inherited;
}

abstract class Parent extends Model implements Inherited {

  List<int> get intList;

  Child get child;

  Set<Child> children;

  Map<String, String> stringMap;
}
''';

void modelGenTest() {
  test('generateModels test', () async {
    final child = ModelBuffer()
      ..name = 'Child'
      ..fields = [
          FieldBuffer()
            ..name = 'count'
            ..type = 'int'
            ..hasSetter = true,
          FieldBuffer()
            ..name = 'string'
            ..type = 'String'
            ..hasSetter = false
        ];

    final parent = ModelBuffer()
      ..name = r'Parent'
      ..fields = [
          CollectionFieldBuffer()
            ..name = 'children'
            ..type = 'Set<Child>'
            ..collectionLiteral = '{}'
            ..hasSetter = true,
          CollectionFieldBuffer()
            ..name = 'stringMap'
            ..type = 'Map<String, String>'
            ..collectionLiteral = '{}'
            ..hasSetter = true,
          CollectionFieldBuffer()
            ..name = 'intList'
            ..type = 'List<int>'
            ..collectionLiteral = '[]'
            ..hasSetter = false,
          FieldBuffer()
            ..name = 'child'
            ..type = 'Child'
            ..hasSetter = false,
          FieldBuffer()
            ..name = 'inherited'
            ..type = 'String'
            ..hasSetter = true
        ];

    final expectedOutput = (StringBuffer()
      ..write(child)
      ..write(parent))
      .toString();

    final lib = await resolveSource(_source, (resolver) => resolver.findLibraryByName(_sourceName));
    final output = generateModels(LibraryReader(lib));
    expect(output, expectedOutput);
  });
}

