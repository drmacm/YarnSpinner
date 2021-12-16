import 'package:yarn_spinner.framework/src/types/i_type.dart';
import 'package:yarn_spinner.framework/src/types/type_util.dart';
class Library {

  Map<String, Delegate> Delegates = Map<String, Delegate>();

  Delegate getFunction(String name) {
    try {
      return delegates[name];
    }
    on KeyNotFoundException catch () {
      throw InvalidOperationException("Function ${name} is not present in the library.");
    }
  }

  void importLibrary(Library otherLibrary) {
    for (var entry in otherLibrary.delegates) {
      delegates[entry.key] = entry.value;
    }
  }

  void registerFunction1<TResult>(String name, Func<TResult> implementation) {
    registerFunction2(name, implementation as Delegate);
  }

  /// <inheritdoc cref="RegisterFunction{TResult}(string, Func{TResult})
  void registerFunction1<T1, TResult>(String name, Func<T1, TResult> implementation) {
    registerFunction2(name, implementation as Delegate);
  }

  /// <inheritdoc cref="RegisterFunction{TResult}(string, Func{TResult})
  void registerFunction1<T1, T2, TResult>(String name, Func<T1, T2, TResult> implementation) {
    registerFunction2(name, implementation as Delegate);
  }

  /// <inheritdoc cref="RegisterFunction{TResult}(string, Func{TResult})
  void registerFunction1<T1, T2, T3, TResult>(String name, Func<T1, T2, T3, TResult> implementation) {
    registerFunction2(name, implementation as Delegate);
  }

  /// <inheritdoc cref="RegisterFunction{TResult}(string, Func{TResult})
  void registerFunction1<T1, T2, T3, T4, TResult>(String name, Func<T1, T2, T3, T4, TResult> implementation) {
    registerFunction2(name, implementation as Delegate);
  }

  /// <inheritdoc cref="RegisterFunction{TResult}(string, Func{TResult})
  void registerFunction1<T1, T2, T3, T4, T5, TResult>(String name, Func<T1, T2, T3, T4, T5, TResult> implementation) {
    registerFunction2(name, implementation as Delegate);
  }

  /// <inheritdoc cref="RegisterFunction{TResult}(string,
  void registerFunction2(String name, Delegate implementation) {
    delegates.add(name, implementation);
  }

  bool functionExists(String name) {
    return delegates.containsKey(name);
  }

  void deregisterFunction(String name) {
    if (functionExists(name)) {
      delegates.remove(name);
    }

  }

  void registerMethods(IType type) {
    var methods = type.methods;

    if (methods == null) {
      // this Type declares no methods; nothing to do
      return;
    }


    for (var methodDefinition in methods) {
      var methodName = methodDefinition.key;
      var methodImplementation = methodDefinition.value;

      var canonicalName = TypeUtil.getCanonicalNameForMethod(type, methodName);

      registerFunction2(canonicalName, methodImplementation);
    }
  }
}
