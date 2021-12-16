import 'package:yarn_spinner.framework/src/types/builtin_types.dart';
import 'package:yarn_spinner.framework/src/types/i_type.dart';

class FunctionType implements IType {
  /// <inheritdoc
  @override
  String get name => "Function";


  /// <inheritdoc
  @override
  String get description {
    List<String> parameterNames = List<String>();
    for (var param in parameters) {
      if (param == null) {
        parameterNames.add("Undefined");
      }
      else {
        parameterNames.add(param.name);
      }
    }

    var returnTypeName = returnType?.name ?? "Undefined";

    return "(${String.join(", ", parameterNames)}) -> ${returnTypeName}";
  }

  @override
  set description(String value) {
    throw InvalidOperationException();
  }


  /// <inheritdoc
  @override
  IType get parent => BuiltinTypes.any;


  IType returnType;

  List<IType> parameters = List<IType>();

  /// <inheritdoc
  // Functions do not have any methods themselves
  @override
  Map<String, Delegate> get methods => null;

  void addParameter(IType parameterType) {
    parameters.add(parameterType);
  }
}
