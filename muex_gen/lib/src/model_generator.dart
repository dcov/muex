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
      throw UnsupportedError('Classes that implements Model should be abstract.');
    }

    _writeModel(klass, buffer);
  }

  return buffer.toString();
}

void _writeModel(ClassElement klass, StringBuffer result) {
  final buffer = ModelBuffer()
    ..modelType = klass.name;

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

void _convertTypeParameters(
    StringBuffer primaryTypeParameters,
    StringBuffer secondaryTypeParameters,
    List<TypeParameterElement> typeParamsList) {
  primaryTypeParameters.write('<');
  secondaryTypeParameters.write('<');
  for (int i = 0; i < typeParamsList.length; i++) {
    if (i != 0) {
      primaryTypeParameters.write(', ');
      secondaryTypeParameters.write(', ');
    }

    final typeParamElement = typeParamsList[i];
    primaryTypeParameters.write(typeParamElement.name);
    secondaryTypeParameters.write(typeParamElement.name);
    if (typeParamElement.bound != null) {
      final bound = typeParamElement.bound.getDisplayString(withNullability: true);
      primaryTypeParameters.write(' extends $bound');
    }
  }
  primaryTypeParameters.write('>');
  secondaryTypeParameters.write('>');
}

FieldBuffer _parseField(FieldElement field) {
  if (field.getter == null) {
    throw UnsupportedError('${field.name} does not have a getter.');
  }

  final InterfaceType fieldType = field.type as InterfaceType;
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
    ..type = fieldType.getDisplayString(withNullability: true)
    ..hasSetter = field.setter != null;

  return buffer;
}
