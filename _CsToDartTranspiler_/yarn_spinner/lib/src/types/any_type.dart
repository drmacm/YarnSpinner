import 'package:yarn_spinner.framework/src/types/i_type.dart';

class AnyType implements IType {
  /// <inheritdoc
  @override
  String get name => "Any";

  /// <inheritdoc
  @override
  IType get parent => null;


  /// <inheritdoc
  @override
  String get description => "Any type.";


  /// <inheritdoc
  @override
  Map<String, Delegate> get methods => null;
}
