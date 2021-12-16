import 'package:yarn_spinner.framework/src/types/i_type.dart';
import 'package:yarn_spinner.framework/src/value.dart';
abstract class IBridgeableType<TBridgedType> implements IType {
  TBridgedType defaultValue = null;

  TBridgedType toBridgedType(Value value);
}
