import 'package:yarn_spinner.framework/src/types/i_type.dart';
abstract class TypeBase implements IType {
  @override
  String name = null;
  @override
  IType parent;
  @override
  String description = null;

  @override
  Map<String, Delegate> get methods => _methods;

  Map<String, Delegate> _methods = Map<String, Delegate>();

  TypeBase(Map<String, Delegate> methods) {
    if (methods == null) {
      return;
    }


    for (var method in methods) {
      _methods.add(method.key, method.value);
    }
  }
}
