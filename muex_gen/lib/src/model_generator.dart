import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:meta/meta.dart';
import 'package:muex/muex.dart';
import 'package:source_gen/source_gen.dart';

import 'model_buffer.dart';

final _modelType = TypeChecker.fromRuntime(Model);

class ModelGenerator extends Generator {

  @override
  String generate(LibraryReader library, _) => generateModels(library);
}

@visibleForTesting
String generateModels(LibraryReader library) {

  final buffer = StringBuffer();
  final elements = library.classes.where(_modelType.isAssignableFrom);

  for (final klass in elements) {
    if (!klass.isAbstract) {
      throw UnsupportedError('Classes that extends Model should be abstract.');
    }

    _writeModel(klass, buffer);
  }

  return buffer.toString();
}

void _writeModel(ClassElement klass, StringBuffer result) {
  final buffer = ModelBuffer()
    ..name = klass.name;

  if (klass.typeParameters.isNotEmpty) {
    final primaryTypeParameters = StringBuffer();
    final secondaryTypeParameters = StringBuffer();
    _convertTypeParameters(primaryTypeParameters, secondaryTypeParameters, klass.typeParameters);
    buffer
      ..primaryTypeParameters = primaryTypeParameters.toString()
      ..secondaryTypeParameters = secondaryTypeParameters.toString();
  }

  buffer.fields.addAll(klass.fields.map(_parseField));
  klass.allSupertypes
    .where((supertype) => !supertype.isDartCoreObject)
    .forEach((supertype) {
      buffer.fields.addAll(supertype.element.fields.map(_parseField));
    });
  result.write(buffer);
}

void _convertTypeParameters(StringBuffer primaryTypeParameters, StringBuffer secondaryTypeParameters, List<TypeParameterElement> tpl) {
  primaryTypeParameters.write('<');
  secondaryTypeParameters.write('<');
  for (int i = 0; i < tpl.length; i++) {
    if (i != 0) {
      primaryTypeParameters.write(', ');
      secondaryTypeParameters.write(', ');
    }

    final tpe = tpl[i];
    primaryTypeParameters.write(tpe.name);
    secondaryTypeParameters.write(tpe.name);
    if (tpe.bound != null) {
      primaryTypeParameters.write(' extends ${tpe.bound.getDisplayString()}');
    }
  }
  primaryTypeParameters.write('>');
  secondaryTypeParameters.write('>');
}

FieldBuffer _parseField(FieldElement field) {
  if (field.getter == null) {
    throw UnsupportedError('${field.name} does not have a getter.');
  }

  final InterfaceType fieldType = field.type;
  final buffer = () {
    if (fieldType.isDartCoreList) {
      return CollectionFieldBuffer()
        ..collectionLiteral = '[]';
    } else if (fieldType.isDartCoreSet) {
      return CollectionFieldBuffer()
        ..collectionLiteral = '{}';
    } else if (fieldType.isDartCoreMap) {
      return CollectionFieldBuffer()
        ..collectionLiteral = '{}';
    } else {
      return FieldBuffer();
    }
  }();
    
  buffer
    ..name = field.name
    ..type = fieldType.getDisplayString()
    ..hasSetter = field.setter != null;

  return buffer;
}

