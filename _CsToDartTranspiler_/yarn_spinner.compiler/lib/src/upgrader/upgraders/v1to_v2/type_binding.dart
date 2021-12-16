import 'package:yarn_spinner.framework/yarn_spinner.framework.dart';
class TypeBinding {
  String VariableName;
  IType Type;

  bool equals(Object obj) {
    TypeBinding binding = obj as TypeBinding;
    return obj is TypeBinding && variableName == binding.variableName && type == binding.type;
  }

  @override
  int get hashCode {
    int hashCode = 2098139523;
    hashCode = (hashCode * -1521134295) + EqualityComparer<String>.default.getHashCode(variableName);
    if (type != null) {
      hashCode = (hashCode * -1521134295) + type.hashCode;
    }

    return hashCode;
  }

  String toString() {
    return "${variableName}: ${type}";
  }

  static List<TypeBinding> unifyBindings(Iterable<TypeBinding> typeBindings) {
    // For each variable, decide whether we know its type (we have
    // 1 binding that is not 'undefined'), or we don't (any other
    // case).

    // Start by grouping all variables by their variable name.
    var variableBindingTypeGroups = typeBindings.groupBy((b) => b.VariableName, (b) => b);

    var unifiedVariableBindings = variableBindingTypeGroups.select((bindingGroup) {
      // If there is precisely one type binding, keep it, if it's
      // defined
      var definedBindings = bindingGroup.where((b) => b.Type != BuiltinTypes.IType);

      if (definedBindings.count() == 1) {
        return definedBindings.first();
      }


      // Otherwise, this type is undefined, because either it has
      // too many defined bindings, or only has an undefined
      // binding
      var result = TypeBinding;
      result.variableName = bindingGroup.Key;
      result.type = BuiltinTypes.IType;
      return result;
     }).toList();

    return unifiedVariableBindings;
  }
}
