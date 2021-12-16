import 'package:yarn_spinner.framework/yarn_spinner.framework.dart';

class Declaration {
  String get name => _name;

  set name(String value) => _name = value;


  static Declaration createVariable(String name, IType type, IConvertible defaultValue, [String description = null]) {

    if (type == null) {
      throw ArgumentNullException(nameof(type));
    }


    if (String.isNullOrEmpty(name)) {
      throw ArgumentError("'${nameof(name)}' cannot be null or empty.", nameof(name));
    }


    if (defaultValue == null) {
      throw ArgumentNullException(nameof(defaultValue));
    }


    // What type of default value did we get?
    Type defaultValueType = defaultValue.runtimeType;

    // We're all good to create the new declaration.
    var decl = Declaration;
    decl.name = name;
    decl.defaultValue = defaultValue;
    decl.type = type;
    decl.description = description;

    return decl;
  }

  IConvertible get defaultValue => _defaultValue;

  set defaultValue(IConvertible value) => _defaultValue = value;


  String get description => _description;

  set description(String value) => _description = value;


  String get sourceFileName => _sourceFileName;

  set sourceFileName(String value) => _sourceFileName = value;


  String get sourceNodeName => _sourceNodeName;

  set sourceNodeName(String value) => _sourceNodeName = value;


  int get sourceFileLine => _sourceFileLine;

  set sourceFileLine(int value) => _sourceFileLine = value;


  int get sourceNodeLine => _sourceNodeLine;

  set sourceNodeLine(int value) => _sourceNodeLine = value;


  bool isImplicit = false;

  IType type;

  final String ExternalDeclaration = "(External)";

  String _name;
  IConvertible _defaultValue;
  IType _type;
  String _description;
  String _sourceFileName;
  String _sourceNodeName;
  int _sourceFileLine = 0;
  int _sourceNodeLine = 0;

  Declaration() {
  }

  /// <inheritdoc
  String toString() {
    String result;

    result = "${name} : ${type} = ${defaultValue}";

    if (String.isNullOrEmpty(description)) {
      return result;
    }
    else {
      return result + " (\"${description}\")";
    }
  }

  /// <inheritdoc
  bool equals(Object obj) {
    Declaration otherDecl = obj as Declaration;
    if (obj == null || !(obj is Declaration)) {
      return false;
    }


    return name == otherDecl.name && type == otherDecl.type && defaultValue == otherDecl.defaultValue && description == otherDecl.description;
  }

  /// <inheritdoc
  @override
  int get hashCode {

    return name.getHashCode() ^ type.hashCode ^ defaultValue.hashCode ^ (description ?? String.empty).getHashCode();
  }
}
