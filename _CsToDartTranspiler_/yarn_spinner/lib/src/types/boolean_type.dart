import 'package:yarn_spinner.framework/src/types/builtin_types.dart';
import 'package:yarn_spinner.framework/src/types/i_bridgeable_type.dart';
import 'package:yarn_spinner.framework/src/types/i_type.dart';
import 'package:yarn_spinner.framework/src/types/type_base.dart';
import 'package:yarn_spinner.framework/src/types/type_util.dart';
import 'package:yarn_spinner.framework/src/value.dart';
import 'package:yarn_spinner.framework/src/virtual_machine.dart';

class BooleanType implements TypeBase, IBridgeableType<bool> {
  /// <inheritdoc
  @override
  bool get defaultValue => default;

  /// <inheritdoc
  @override
  String get name => "Bool";

  /// <inheritdoc
  @override
  IType get parent => BuiltinTypes.any;

  /// <inheritdoc
  @override
  String get description => "Bool";

  /// <inheritdoc
  static Map<String, Delegate> get _defaultMethods { 
    var result = {Operator.equalTo.toString(): TypeUtil.getMethod2<bool>(_methodEqualTo), Operator.notEqualTo.toString(): TypeUtil.getMethod2<bool>((a, b) => !_methodEqualTo(a, b)), Operator.and.toString(): TypeUtil.getMethod2<bool>(_methodAnd), Operator.or.toString(): TypeUtil.getMethod2<bool>(_methodOr), Operator.xor.toString(): TypeUtil.getMethod2<bool>(_methodXor), Operator.not.toString(): TypeUtil.getMethod2<bool>(_methodNot)};
    return result;
  }

  BooleanType() {
  }

  static bool _methodEqualTo(Value a, Value b) {
    return a.convertTo<bool>() == b.convertTo<bool>();
  }

  static bool _methodAnd(Value a, Value b) {
    return a.convertTo<bool>() && b.convertTo<bool>();
  }

  static bool _methodOr(Value a, Value b) {
    return a.convertTo<bool>() || b.convertTo<bool>();
  }

  static bool _methodXor(Value a, Value b) {
    return a.convertTo<bool>() ^ b.convertTo<bool>();
  }

  static bool _methodNot(Value a) {
    return !a.convertTo<bool>();
  }

  @override
  bool toBridgedType(Value value) {
    return value.convertTo<bool>();
  }
}
