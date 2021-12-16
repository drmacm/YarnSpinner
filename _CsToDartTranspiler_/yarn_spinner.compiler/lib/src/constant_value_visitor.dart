import 'package:yarn_spinner.compiler.framework/src/error_listener.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser_base_visitor.dart';
import 'package:yarn_spinner.framework/yarn_spinner.framework.dart';

class ConstantValueVisitor extends YarnSpinnerParserBaseVisitor<Value> {
  ParserRuleContext _context;
  String _sourceFileName;
  Iterable<IType> _types;
  List<Diagnostic> _diagnostics;

  ConstantValueVisitor(ParserRuleContext context, String sourceFileName, Iterable<IType> types, RefParam<List<Diagnostic>> diagnostics) {
    _context = context;
    _sourceFileName = sourceFileName;
    _types = types;
    _diagnostics = diagnostics.value;
  }

  // Default result is an exception - only specific parse nodes can
  // be visited by this visitor
  Value get defaultResult {
    String message = "Expected a constant type";
    _diagnostics.add(Diagnostic(_sourceFileName, _context, message));
    return Value(BuiltinTypes.IType, null);
  }


  Value visitValueNull(ValueNullContext context) {
    String message = "Null is not a permitted type in Yarn Spinner 2.0 and later";
    _diagnostics.add(Diagnostic(_sourceFileName, context, message));
    return Value(BuiltinTypes.IType, null);
  }

  Value visitValueNumber(ValueNumberContext context) {
    var result;
    var resultRef = RefParam(result);
    if (double.tryParse(context.getText(), resultRef)) {
      result = resultRef.value;
      return Value(BuiltinTypes.number, result);
    }
    else {
      String message = "Failed to parse ${context.getText()} as a float";
      _diagnostics.add(Diagnostic(_sourceFileName, context, message));
      return Value(BuiltinTypes.number, 0.0);
    }
  }

  Value visitValueString(ValueStringContext context) {
    return Value(BuiltinTypes.String, context.sTRING().getText().trim('"'));
  }

  Value visitValueFalse(ValueFalseContext context) {
    return Value(BuiltinTypes.bool, false);
  }

  Value visitValueTrue(ValueTrueContext context) {
    return Value(BuiltinTypes.bool, true);
  }
}
