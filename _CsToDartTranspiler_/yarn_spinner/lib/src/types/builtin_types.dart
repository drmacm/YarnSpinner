import 'package:yarn_spinner.framework/src/types/any_type.dart';
import 'package:yarn_spinner.framework/src/types/boolean_type.dart';
import 'package:yarn_spinner.framework/src/types/i_type.dart';
import 'package:yarn_spinner.framework/src/types/number_type.dart';
import 'package:yarn_spinner.framework/src/types/string_type.dart';

class BuiltinTypes {
  /// An undefined type.
  final IType Undefined = null;

  /// Gets the type representing strings.
  static IType string = StringType();

  /// Gets the type representing numbers.
  static IType number = NumberType();

  /// Gets the type representing boolean values.
  static IType boolean = BooleanType();

  /// Gets the type representing any value.
  static IType any = AnyType();

  static Map<Type, IType> typeMappings = {String.runtimeType: BuiltinTypes.String, bool.runtimeType: BuiltinTypes.bool, int.runtimeType: BuiltinTypes.number, double.runtimeType: BuiltinTypes.number, double.runtimeType: BuiltinTypes.number, SByte.runtimeType: BuiltinTypes.number, int.runtimeType: BuiltinTypes.number, int.runtimeType: BuiltinTypes.number, int.runtimeType: BuiltinTypes.number, int.runtimeType: BuiltinTypes.number, int.runtimeType: BuiltinTypes.number, int.runtimeType: BuiltinTypes.number, double.runtimeType: BuiltinTypes.number, Object.runtimeType: BuiltinTypes.any};

  static Iterable<IType> get allBuiltinTypes {
    // Find all static properties of BuiltinTypes that are
    // public
    var propertyInfos = BuiltinTypes.runtimeType.getProperties(System.Reflection.BindingFlags.public | System.Reflection.BindingFlags.static);

    List<IType> result = List<IType>();

    for (var propertyInfo in propertyInfos) {
      // If the type of this property is IType, then this is
      // a built-in type!
      if (propertyInfo.propertyType == IType.runtimeType) {
        // Get that value.
        var builtinType = propertyInfo.getValue(null) as IType;

        // If it's not null (i.e. the undefined type), then
        // add it to the type objects we're returning!
        if (builtinType != null) {
          result.add(builtinType);
        }

      }

    }

    return result;
  }

}
