import 'package:yarn_spinner.framework/src/types/i_bridgeable_type.dart';
import 'package:yarn_spinner.framework/src/types/i_type.dart';
class Value {
  IType type;

  IConvertible InternalValue;

  Value(Value value) {
    type = value.type;
    internalValue = value.internalValue;
  }

  Value(IBridgeableType<IConvertible> type) {
    this.type = type;
    internalValue = type.defaultValue;
  }

  Value(IType type, IConvertible internalValue) {
    this.type = type;
    this.internalValue = internalValue;
  }

  int compareTo(Object obj) {
    // not a value
    Value other = obj as Value;
    if (!(obj is Value)) {
      throw ArgumentError("Object is not a Value");
    }


    // it is a value!
    return (this as Comparable<Value>).compareTo(other);
  }

  T convertTo<T>() {
    Type targetType = T.runtimeType;

    return convertTo1(targetType) as T;
  }

  Object convertTo1(Type targetType) {
    if (targetType == Value.runtimeType) {
      return this;
    }


    return Convert.changeType(internalValue, targetType);
  }

  String toString() {
    return String.format(CultureInfo.currentCulture, "[Value: type={0}, value={1}]", type.name, convertTo<String>());
  }
}
