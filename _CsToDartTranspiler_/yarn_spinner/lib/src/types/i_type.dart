
abstract class IType {
  String name = null;

  IType parent;

  String description = null;

  Map<String, Delegate> methods;
}
