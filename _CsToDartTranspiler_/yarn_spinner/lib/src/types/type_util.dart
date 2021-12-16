import 'package:yarn_spinner.framework/src/types/builtin_types.dart';
import 'package:yarn_spinner.framework/src/types/i_type.dart';
class TypeUtil {
  // Helper functions that allow us to easily cast method groups of
  // certain types to System.Delegate - i.e. we can say:
  // ```
  // int DoCoolThing(Value a, Value b) { ... }
  // var doCoolThingDelegate = TypeUtil.GetMethod(DoCoolThing);
  // ```
  static Delegate getMethod2<TResult>(Func<Value, Value, TResult> f) => f;


  static Delegate getMethod2<T>(Func<Value, T> f) => f;


  static Delegate getMethod2<T>(Func<T> f) => f;


  static IType findImplementingTypeForMethod(IType type, String methodName) {
    if (type == null) {
      throw ArgumentNullException(nameof(type));
    }


    if (String.isNullOrEmpty(methodName)) {
      throw ArgumentError("'${nameof(methodName)}' cannot be null or empty.", nameof(methodName));
    }


    var currentType = type;

    // Walk up the type hierarchy, looking for a type that
    // implements a method by this name
    while (currentType != null) {
      if (currentType.methods != null && currentType.methods.containsKey(methodName)) {
        return currentType;
      }


      currentType = currentType.parent;
    }

    return null;
  }

  static String getCanonicalNameForMethod(IType implementingType, String methodName) {
    if (implementingType == null) {
      throw ArgumentNullException(nameof(implementingType));
    }


    if (String.isNullOrEmpty(methodName)) {
      throw ArgumentError("'${nameof(methodName)}' cannot be null or empty.", nameof(methodName));
    }


    return "${implementingType.name}.${methodName}";
  }

  static void getNamesFromCanonicalName(String canonicalName, RefParam<String> typeName, RefParam<String> methodName) {
    if (String.isNullOrEmpty(canonicalName)) {
      throw ArgumentError("'${nameof(canonicalName)}' cannot be null or empty.", nameof(canonicalName));
    }


    var components = canonicalName.split(['.'], 2);

    if (components.length != 2) {
      throw ArgumentError("Invalid canonical method name ${canonicalName}");
    }


    typeName.value = components[0];
    methodName.value = components[1];
  }

  static bool isSubType(IType parentType, IType subType) {
    if (subType == BuiltinTypes.undefined && parentType == BuiltinTypes.any) {
      // Special case: the undefined type is always a subtype of
      // the Any type, because ALL types are a subtype of the Any
      // type.
      return true;
    }


    if (subType == BuiltinTypes.undefined) {
      // The subtype is undefined. Assume that it is not a
      // subtype of parentType.
      return false;
    }


    var currentType = subType;

    while (currentType != null) {
      // TODO: this is a strict object comparison; a more
      // sophisticated type unification might be better
      if (currentType == parentType) {
        return true;
      }


      currentType = currentType.parent;
    }

    // We reached the top of the type hierarchy, and didn't find
    // parentType. subType is not a subtype of parentType.
    return false;
  }
}
