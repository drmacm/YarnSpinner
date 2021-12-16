import 'package:yarn_spinner.framework/src/types/builtin_types.dart';
import 'package:yarn_spinner.framework/src/types/i_bridgeable_type.dart';
import 'package:yarn_spinner.framework/src/types/i_type.dart';
import 'package:yarn_spinner.framework/src/types/type_base.dart';
import 'package:yarn_spinner.framework/src/types/type_util.dart';
import 'package:yarn_spinner.framework/src/value.dart';
import 'package:yarn_spinner.framework/src/virtual_machine.dart';

class NumberType implements TypeBase, IBridgeableType<double> {
  /// <inheritdoc
  @override
  double get defaultValue => default;

  /// <inheritdoc
  @override
  String get name => "Number";

  /// <inheritdoc
  @override
  IType get parent => BuiltinTypes.any;

  /// <inheritdoc
  @override
  String get description => "Number";

  static Map<String, Delegate> get _defaultMethods { 
    var result = {Operator.equalTo.toString(): TypeUtil.getMethod2<bool>(_methodEqualTo), Operator.notEqualTo.toString(): TypeUtil.getMethod2<bool>((a, b) => !_methodEqualTo(a, b)), Operator.add.toString(): TypeUtil.getMethod2<double>(_methodAdd), Operator.minus.toString(): TypeUtil.getMethod2<double>(_methodSubtract), Operator.divide.toString(): TypeUtil.getMethod2<double>(_methodDivide), Operator.multiply.toString(): TypeUtil.getMethod2<double>(_methodMultiply), Operator.modulo.toString(): TypeUtil.getMethod2<int>(_methodModulus), Operator.unaryMinus.toString(): TypeUtil.getMethod2<double>(_methodUnaryMinus), Operator.greaterThan.toString(): TypeUtil.getMethod2<bool>(_methodGreaterThan), Operator.greaterThanOrEqualTo.toString(): TypeUtil.getMethod2<bool>(_methodGreaterThanOrEqualTo), Operator.lessThan.toString(): TypeUtil.getMethod2<bool>(_methodLessThan), Operator.lessThanOrEqualTo.toString(): TypeUtil.getMethod2<bool>(_methodLessThanOrEqualTo)};
    return result;
  }

  NumberType() {
  }

  /// <inheritdoc
  @override
  double toBridgedType(Value value) {
    throw NotImplementedException();
  }

  static bool _methodEqualTo(Value a, Value b) {
    return a.convertTo<double>() == b.convertTo<double>();
  }

  static double _methodAdd(Value a, Value b) {
    return a.convertTo<double>() + b.convertTo<double>();
  }

  static double _methodSubtract(Value a, Value b) {
    return a.convertTo<double>() - b.convertTo<double>();
  }

  static double _methodDivide(Value a, Value b) {
    return a.convertTo<double>() / b.convertTo<double>();
  }

  static double _methodMultiply(Value a, Value b) {
    return a.convertTo<double>() * b.convertTo<double>();
  }

  static int _methodModulus(Value a, Value b) {
    return a.convertTo<int>() % b.convertTo<int>();
  }

  static double _methodUnaryMinus(Value a) {
    return -a.convertTo<double>();
  }

  static bool _methodGreaterThan(Value a, Value b) {
    return a.convertTo<double>() > b.convertTo<double>();
  }

  static bool _methodGreaterThanOrEqualTo(Value a, Value b) {
    return a.convertTo<double>() >= b.convertTo<double>();
  }

  static bool _methodLessThan(Value a, Value b) {
    return a.convertTo<double>() < b.convertTo<double>();
  }

  static bool _methodLessThanOrEqualTo(Value a, Value b) {
    return a.convertTo<double>() <= b.convertTo<double>();
  }
}
