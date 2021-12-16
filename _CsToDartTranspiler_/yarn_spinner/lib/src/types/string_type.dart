import 'package:yarn_spinner.framework/src/types/builtin_types.dart';
import 'package:yarn_spinner.framework/src/types/i_bridgeable_type.dart';
import 'package:yarn_spinner.framework/src/types/i_type.dart';
import 'package:yarn_spinner.framework/src/types/type_base.dart';
import 'package:yarn_spinner.framework/src/types/type_util.dart';
import 'package:yarn_spinner.framework/src/value.dart';
import 'package:yarn_spinner.framework/src/virtual_machine.dart';

class StringType implements TypeBase, IBridgeableType<String> {
  StringType() {
  }

  /// <inheritdoc
  @override
  String get name => "String";

  /// <inheritdoc
  @override
  IType get parent => BuiltinTypes.any;

  /// <inheritdoc
  @override
  String description = null;

  /// <inheritdoc
  @override
  String get defaultValue => String.empty;

  static Map<String, Delegate> get _defaultMethods { 
    var result = {Operator.equalTo.toString(): TypeUtil.getMethod2<bool>(_methodEqualTo), Operator.notEqualTo.toString(): TypeUtil.getMethod2<bool>((a, b) => !_methodEqualTo(a, b)), Operator.add.toString(): TypeUtil.getMethod2<String>(_methodConcatenate)};
    return result;
  }

  /// <inheritdoc
  @override
  String toBridgedType(Value value) {
    return value.convertTo<String>();
  }

  /// <inheritdoc
  bool equals(Object obj) {
    return super.equals(obj);
  }

  /// <inheritdoc
  @override
  int get hashCode {
    return super.hashCode;
  }

  /// <inheritdoc
  String toString() {
    return super.toString();
  }

  static String _methodConcatenate(Value arg1, Value arg2) {
    return String.concat(arg1.convertTo<String>(), arg2.convertTo<String>());
  }

  static bool _methodEqualTo(Value a, Value b) {
    return a.convertTo<String>().equals(b.convertTo<String>());
  }
}
