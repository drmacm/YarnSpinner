import 'package:yarn_spinner.compiler.framework/src/code_generation_visitor.dart';
import 'package:yarn_spinner.compiler.framework/src/declaration.dart';
import 'package:yarn_spinner.compiler.framework/src/error_listener.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_lexer.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser_base_visitor.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser_expression.dart';
import 'package:yarn_spinner.framework/yarn_spinner.framework.dart';

class TypeCheckVisitor extends YarnSpinnerParserBaseVisitor<IType> {
  // The collection of variable declarations we know about before
  // starting our work
  Iterable<Declaration> _existingDeclarations;

  // The name of the node that we're currently visiting.
  String _currentNodeName = null;

  NodeContext _currentNodeContext;

  String _sourceFileName;

  ICollection<Declaration> newDeclarations;

  Iterable<IType> _types;

  final List<Diagnostic> _diagnostics = List<Diagnostic>();

  Iterable<Declaration> get declarations => _existingDeclarations.concat(newDeclarations);

  TypeCheckVisitor(String sourceFileName, Iterable<Declaration> existingDeclarations, Iterable<IType> types) {
    _existingDeclarations = existingDeclarations;
    newDeclarations = List<Declaration>();
    _types = types;
    _sourceFileName = sourceFileName;
  }

  IType get defaultResult => null;

  Iterable<Diagnostic> get diagnostics => _diagnostics;

  IType visitNode(NodeContext context) {
    _currentNodeContext = context;
    for (var header in context.header()) {
      if (header.header_key.Text == "title") {
        _currentNodeName = header.header_value.Text;
      }

    }

    var body = context.body();

    if (body != null) {
      super.visit(body);
    }


    return null;
  }

  IType visitValueNull(ValueNullContext context) {
    _diagnostics.add(Diagnostic(_sourceFileName, context, "Null is not a permitted type in Yarn Spinner 2.0 and later"));

    return BuiltinTypes.IType;
  }

  IType visitValueString(ValueStringContext context) {
    return BuiltinTypes.String;
  }

  IType visitValueTrue(ValueTrueContext context) {
    return BuiltinTypes.bool;
  }

  IType visitValueFalse(ValueFalseContext context) {
    return BuiltinTypes.bool;
  }

  IType visitValueNumber(ValueNumberContext context) {
    return BuiltinTypes.number;
  }

  IType visitValueVar(ValueVarContext context) {

    return visitVariable(context.variable());
  }

  IType visitVariable(VariableContext context) {
    // The type of the value depends on the declared type of the
    // variable

    var name = context.vAR_ID()?.GetText();

    if (name == null) {
      // We don't have a variable name for this Variable context.
      // The parser will have generated an error for us in an
      // earlier stage; here, we'll bail out.
      return BuiltinTypes.IType;
    }


    for (var declaration in declarations) {
      if (declaration.name == name) {
        return declaration.type;
      }

    }

    // We don't have a declaration for this variable. Return
    // Undefined. Hopefully, other context will allow us to infer a
    // type.
    return BuiltinTypes.IType;
  }

  IType visitValueFunc(ValueFuncContext context) {
    String functionName = context.function_call().fUNC_ID().getText();

    Declaration functionDeclaration = declarations.where((d) => d.Type is FunctionType).firstOrDefault((d) => d.Name == functionName);

    FunctionType functionType;

    if (functionDeclaration == null) {
      // We don't have a declaration for this function. Create an
      // implicit one.

      functionType = FunctionType();
      functionType.IType = BuiltinTypes.IType;

      functionDeclaration = Declaration;
      functionDeclaration.name = functionName;
      functionDeclaration.type = functionType;
      functionDeclaration.isImplicit = true;
      functionDeclaration.description = "Implicit declaration of function at ${_sourceFileName}:${context.Start.Line}:${context.Start.Column}";
      functionDeclaration.sourceFileName = _sourceFileName;
      functionDeclaration.sourceFileLine = context.Start.Line;
      functionDeclaration.sourceNodeName = _currentNodeName;
      functionDeclaration.sourceNodeLine = context.Start.Line - (_currentNodeContext.bODY_START().Symbol.Line + 1);

      // Create the array of parameters for this function based
      // on how many we've seen in this call. Set them all to be
      // undefined; we'll bind their type shortly.
      var parameterTypes = context.function_call().expression().select((e) => BuiltinTypes.IType).toList();

      for (var parameterType in parameterTypes) {
        functionType.addParameter(parameterType);
      }

      newDeclarations.add(functionDeclaration);
    }
    else {
      functionType = functionDeclaration.type as FunctionType;
      if (functionType == null) {
        throw InvalidOperationException("Internal error: decl's type is not a ${nameof(FunctionType)}");
      }

    }

    // Check each parameter of the function
    var suppliedParameters = context.function_call().expression();

    var expectedParameters = functionType.parameters;

    if (suppliedParameters.length != expectedParameters.count()) {
      // Wrong number of parameters supplied
      var parameters = expectedParameters.count() == 1 ? "parameter" : "parameters";

      _diagnostics.add(Diagnostic(_sourceFileName, context, "Function ${functionName} expects ${expectedParameters.count()} ${parameters}, but received ${suppliedParameters.length}"));

      return functionType.returnType;
    }


    for (int i = 0; i < expectedParameters.count(); i++) {
      var suppliedParameter = suppliedParameters[i];

      var expectedType = expectedParameters[i];

      var suppliedType = visit(suppliedParameter);

      if (expectedType == BuiltinTypes.IType) {
        // The type of this parameter hasn't yet been bound.
        // Bind this parameter type to what we've resolved the
        // type to.
        expectedParameters[i] = suppliedType;
        expectedType = suppliedType;
      }


      if (TypeUtil.isSubType(expectedType, suppliedType) == false) {
        _diagnostics.add(Diagnostic(_sourceFileName, context, "${functionName} parameter ${i + 1} expects a ${expectedType.Name}, not a ${suppliedType.Name}"));
        return functionType.returnType;
      }

    }

    // Cool, all the parameters check out!

    // Finally, return the return type of this function.
    return functionType.returnType;
  }

  IType visitExpValue(ExpValueContext context) {
    // Value expressions have the type of their inner value
    IType type = Visit(context.value());
    context.type = type;
    return type;
  }

  IType visitExpParens(ExpParensContext context) {
    // Parens expressions have the type of their inner expression
    IType type = Visit(context.expression());
    context.type = type;
    return type;
  }

  IType visitExpAndOrXor(ExpAndOrXorContext context) {
    IType type = _checkOperation(context, context.expression(), CodeGenerationVisitor.tokensToOperators[context.op.Type], context.op.Text);
    context.type = type;
    return type;
  }

  IType visitSet_statement(Set_statementContext context) {
    var expressionType = Visit(context.expression());
    var variableType = Visit(context.variable());

    var variableName = context.variable().getText();

    List<ParserRuleContext> terms = [context.variable(), context.expression()];

    IType type;

    Operator @operator = Operator.NotEqualTo;

    switch (context.op.Type) {
      case YarnSpinnerLexer.oPERATOR_ASSIGNMENT: {
        // Straight assignment supports any assignment, as long
        // as it's consistent; we already know the type of the
        // expression, so let's check to see if it's assignable
        // to the type of the variable
        if (variableType != BuiltinTypes.IType && TypeUtil.isSubType(variableType, expressionType) == false) {
          String message = "${variableName} (${variableType?.Name ?? "undefined"}) cannot be assigned a ${expressionType?.Name ?? "undefined"}";
          _diagnostics.add(Diagnostic(_sourceFileName, context, message));
        }
        else if (variableType == BuiltinTypes.IType && expressionType != BuiltinTypes.IType) {
          // This variable was undefined, but we have a
          // defined type for the value it was set to. Create
          // an implicit declaration for the variable!

          // The start line of the body is the line after the delimiter
          int nodePositionInFile = _currentNodeContext.bODY_START().Symbol.Line + 1;

          // Generate a declaration for this variable here.
          var decl = Declaration;
          decl.name = variableName;
          decl.description = "${System.IO.Path.getFileName(_sourceFileName)}, node ${_currentNodeName}, line ${context.Start.Line - nodePositionInFile}";
          decl.type = expressionType;
          decl.defaultValue = _defaultValueForType(expressionType);
          decl.sourceFileName = _sourceFileName;
          decl.sourceFileLine = context.Start.Line;
          decl.sourceNodeName = _currentNodeName;
          decl.sourceNodeLine = context.Start.Line - nodePositionInFile;
          decl.isImplicit = true;
          newDeclarations.add(decl);
        }

      }
      case YarnSpinnerLexer.oPERATOR_MATHS_ADDITION_EQUALS: {
        // += supports strings and numbers
        operator = CodeGenerationVisitor.tokensToOperators[YarnSpinnerLexer.oPERATOR_MATHS_ADDITION];
        type = _checkOperation(context, terms, operator, context.op.Text);
      }
      case YarnSpinnerLexer.oPERATOR_MATHS_SUBTRACTION_EQUALS: {
        // -=, *=, /=, %= supports only numbers
        operator = CodeGenerationVisitor.tokensToOperators[YarnSpinnerLexer.oPERATOR_MATHS_SUBTRACTION];
        type = _checkOperation(context, terms, operator, context.op.Text);
      }
      case YarnSpinnerLexer.oPERATOR_MATHS_MULTIPLICATION_EQUALS: {
        operator = CodeGenerationVisitor.tokensToOperators[YarnSpinnerLexer.oPERATOR_MATHS_MULTIPLICATION];
        type = _checkOperation(context, terms, operator, context.op.Text);
      }
      case YarnSpinnerLexer.oPERATOR_MATHS_DIVISION_EQUALS: {
        operator = CodeGenerationVisitor.tokensToOperators[YarnSpinnerLexer.oPERATOR_MATHS_DIVISION];
        type = _checkOperation(context, terms, operator, context.op.Text);
      }
      case YarnSpinnerLexer.oPERATOR_MATHS_MODULUS_EQUALS: {
        operator = CodeGenerationVisitor.tokensToOperators[YarnSpinnerLexer.oPERATOR_MATHS_MODULUS];
        type = _checkOperation(context, terms, operator, context.op.Text);
      }
      default: {
        throw InvalidOperationException("Internal error: ${nameof(visitSet_statement)} got unexpected operand ${context.op.Text}");
      }
    }

    if (expressionType == BuiltinTypes.IType) {
      // We don't know what this is set to, so we'll have to
      // assume it's ok. Return the variable type, if known.
      return variableType;
    }


    return expressionType;
  }

  IType _checkOperation(ParserRuleContext context, List<ParserRuleContext> terms, Operator operationType, String operationDescription, List<IType> permittedTypes) {

    var termTypes = List<IType>();

    var expressionType = BuiltinTypes.IType;

    for (var expression in terms) {
      // Visit this expression, and determine its type.
      IType type = Visit(expression);

      if (type != BuiltinTypes.IType) {
        termTypes.add(type);
        if (expressionType == BuiltinTypes.IType) {
          // This is the first concrete type we've seen. This
          // will be our expression type.
          expressionType = type;
        }

      }

    }

    if (permittedTypes.length == 1 && expressionType == BuiltinTypes.IType) {
      // If we aren't sure of the expression type from
      // parameters, but we only have one permitted one, then
      // assume that the expression type is the single permitted
      // type.
      expressionType = permittedTypes.first();
    }


    if (expressionType == BuiltinTypes.IType) {
      // We still don't know what type of expression this is, and
      // don't have a reasonable guess.

      // Last-ditch effort: is the operator that we were given
      // valid in exactly one type? In that case, we'll decide
      // it's that type.
      var typesImplementingMethod = _types.where((t) => t.Methods != null).where((t) => t.Methods.containsKey(operationType.toString()));

      if (typesImplementingMethod.count() == 1) {
        // Only one type implements the operation we were
        // given. Given no other information, we will assume
        // that it is this type.
        expressionType = typesImplementingMethod.first();
      }
      else if (typesImplementingMethod.count() > 1) {
        // Multiple types implement this operation.
        Iterable<String> typeNames = typesImplementingMethod.select((t) => t.Name);

        String message = "Type of expression \"${context.getTextWithWhitespace()}\" can't be determined without more context (the compiler thinks it could be ${String.join(", or ", typeNames)}). Use a type cast on at least one of the terms (e.g. the string(), number(), bool() functions)";

        _diagnostics.add(Diagnostic(_sourceFileName, context, message));
        return BuiltinTypes.IType;
      }
      else {
        // No types implement this operation (??)
        String message = "Type of expression \"${context.getTextWithWhitespace()}\" can't be determined without more context. Use a type cast on at least one of the terms (e.g. the string(), number(), bool() functions)";
        _diagnostics.add(Diagnostic(_sourceFileName, context, message));
        return BuiltinTypes.IType;
      }
    }


    // Were any of the terms variables for which we don't currently
    // have a declaration for?

    // Start by building a list of all terms that are variables.
    // These are either variable values, or variable names . (The
    // difference between these two is that a ValueVarContext
    // occurs in syntax where the value of the variable is used
    // (like an expression), while a VariableContext occurs in
    // syntax where it's just a variable name (like a set
    // statements)

    // All VariableContexts in the terms of this expression (but
    // not in the children of those terms)
    var variableContexts = terms.select((c) => c.GetChild<YarnSpinnerParser.ValueVarContext>(0)?.variable()).concat(terms.select((c) => c.GetChild<YarnSpinnerParser.VariableContext>(0))).concat(terms.OfType<YarnSpinnerParser.VariableContext>()).concat(terms.OfType<YarnSpinnerParser.ValueVarContext>().select((v) => v.variable())).where((c) => c != null);

    // Get their names
    var variableNames = variableContexts.select((v) => v.vAR_ID().getText()).distinct();

    // Build the list of variable names that we don't have a
    // declaration for. We'll check for explicit declarations first.
    var undefinedVariableNames = variableNames.where((name) => declarations.any((d) => d.Name == name) == false);

    if (undefinedVariableNames.count() > 0) {
      // We have references to variables that we don't have a an
      // explicit declaration for! Time to create implicit
      // references for them!

      // Get the position of this reference in the file
      int positionInFile = context.Start.Line;

      // The start line of the body is the line after the delimiter
      int nodePositionInFile = _currentNodeContext.bODY_START().Symbol.Line + 1;

      for (var undefinedVariableName in undefinedVariableNames) {
        // Generate a declaration for this variable here.
        var decl = Declaration;
        decl.name = undefinedVariableName;
        decl.description = "${System.IO.Path.getFileName(_sourceFileName)}, node ${_currentNodeName}, line ${positionInFile - nodePositionInFile}";
        decl.type = expressionType;
        decl.defaultValue = _defaultValueForType(expressionType);
        decl.sourceFileName = _sourceFileName;
        decl.sourceFileLine = positionInFile;
        decl.sourceNodeName = _currentNodeName;
        decl.sourceNodeLine = positionInFile - nodePositionInFile;
        decl.isImplicit = true;
        newDeclarations.add(decl);
      }
    }


    // All types must be same as the expression type (which is the
    // first defined type we encountered when going through the
    // terms)
    if (termTypes.all((t) => t == expressionType) == false) {
      // Not all the term types we found were the expression
      // type.
      var typeList = String.join(", ", termTypes.select((t) => t.Name));
      String message = "All terms of ${operationDescription} must be the same, not ${typeList}";
      _diagnostics.add(Diagnostic(_sourceFileName, context, message));
      return BuiltinTypes.IType;
    }


    // We've now determined that this expression is of
    // expressionType. In case any of the terms had an undefined
    // type, we'll define it now.
    for (var term in terms) {
      ExpressionContext expression = term as ExpressionContext;
      if (term is ExpressionContext) {
        if (expression.type == BuiltinTypes.IType) {
          expression.type = expressionType;
        }


        FunctionType functionType = expression.Type as FunctionType;
        if (expression.type is FunctionType && functionType.returnType == BuiltinTypes.IType) {
          functionType.IType = expressionType;
        }

      }

    }

    if (operationType != Operator.Operator) {
      // We need to validate that the type we've selected actually
      // implements this operation.
      var implementingType = TypeUtil.findImplementingTypeForMethod(expressionType, operationType.toString());

      if (implementingType == null) {
        String message = "${expressionType.name} has no implementation defined for ${operationDescription}";
        _diagnostics.add(Diagnostic(_sourceFileName, context, message));
        return BuiltinTypes.IType;
      }

    }


    // Is this expression is required to be one of the specified types?
    if (permittedTypes.count() > 0) {
      // Is the type that we've arrived at compatible with one of
      // the permitted types?
      if (permittedTypes.any((t) => TypeUtil.isSubType(t, expressionType))) {
        // It's compatible! Great, return the type we've
        // determined.
        return expressionType;
      }
      else {
        // The expression type wasn't valid!
        var permittedTypesList = String.join(" or ", permittedTypes.select((t) => t?.Name ?? "undefined"));
        var typeList = String.join(", ", termTypes.select((t) => t.Name));

        String message = "Terms of '${operationDescription}' must be ${permittedTypesList}, not ${typeList}";
        _diagnostics.add(Diagnostic(_sourceFileName, context, message));
        return BuiltinTypes.IType;
      }
    }
    else {
      // We weren't given a specific type. The expression type is
      // therefore only valid if it can use the provided
      // operator.

      // Find a type in 'expressionType's hierarchy that
      // implements this method.
      var implementingTypeForMethod = TypeUtil.findImplementingTypeForMethod(expressionType, operationType.toString());

      if (implementingTypeForMethod == null) {
        // The type doesn't have a method for handling this
        // operator, and neither do any of its supertypes. This
        // expression is therefore invalid.

        String message = "Operator ${operationDescription} cannot be used with ${expressionType.name} values";
        _diagnostics.add(Diagnostic(_sourceFileName, context, message));

        return BuiltinTypes.IType;
      }
      else {
        return expressionType;
      }
    }
  }

  static IConvertible _defaultValueForType(IType expressionType) {
    if (expressionType == BuiltinTypes.String) {
      return String.empty;
    }
    else if (expressionType == BuiltinTypes.number) {
      return 0.0;
    }
    else if (expressionType == BuiltinTypes.bool) {
      return false;
    }
    else {
      throw ArgumentOutOfRangeException("No default value for type ${expressionType.name} exists.");
    }
  }

  IType visitIf_clause(If_clauseContext context) {
    VisitChildren(context);
    // If clauses are required to be boolean
    var expressions = [context.expression()];
    return _checkOperation(context, expressions, Operator.Operator, "if statement", BuiltinTypes.bool);
  }

  IType visitElse_if_clause(Else_if_clauseContext context) {
    VisitChildren(context);
    // Else if clauses are required to be boolean
    var expressions = [context.expression()];
    return _checkOperation(context, expressions, Operator.Operator, "elseif statement", BuiltinTypes.bool);
  }

  IType visitExpAddSub(ExpAddSubContext context) {

    var expressions = context.expression();

    IType type;

    var @operator = CodeGenerationVisitor.tokensToOperators[context.op.Type];

    type = _checkOperation(context, expressions, operator, context.op.Text);

    context.type = type;

    return type;
  }

  IType visitExpMultDivMod(ExpMultDivModContext context) {
    var expressions = context.expression();

    var @operator = CodeGenerationVisitor.tokensToOperators[context.op.Type];

    // *, /, % all support numbers only
    IType type = _checkOperation(context, expressions, operator, context.op.Text);
    context.type = type;
    return type;
  }



  IType visitExpComparison(ExpComparisonContext context) {
    List<ParserRuleContext> terms = context.expression();

    var @operator = CodeGenerationVisitor.tokensToOperators[context.op.Type];

    var type = _checkOperation(context, terms, operator, context.op.Text);
    context.type = type;

    // Comparisons always return bool
    return BuiltinTypes.bool;
  }

  IType visitExpEquality(ExpEqualityContext context) {
    List<ParserRuleContext> terms = context.expression();

    var @operator = CodeGenerationVisitor.tokensToOperators[context.op.Type];

    // == and != support any defined type, as long as terms are the
    // same type
    var determinedType = _checkOperation(context, terms, operator, context.op.Text);

    context.type = determinedType;

    // Equality checks always return bool
    return BuiltinTypes.bool;
  }

  IType visitExpNegative(ExpNegativeContext context) {
    List<ParserRuleContext> terms = [context.expression()];

    var @operator = CodeGenerationVisitor.tokensToOperators[context.op.Type];

    IType type = _checkOperation(context, terms, operator, context.op.Text);
    context.type = type;
    return type;
  }

  IType visitExpNot(ExpNotContext context) {
    List<ParserRuleContext> terms = [context.expression()];

    var @operator = CodeGenerationVisitor.tokensToOperators[context.op.Type];

    // ! supports only bool types
    IType type = _checkOperation(context, terms, operator, context.op.Text);
    context.type = type;

    return BuiltinTypes.bool;
  }

  IType visitLine_formatted_text(Line_formatted_textContext context) {
    // Type-check every expression in this line, using the None
    // operator and permitting the expression to be of Any type
    for (var expression in context.expression()) {
      var type = _checkOperation(expression, [expression], Operator.Operator, "inline expression", BuiltinTypes.any);
      expression.type = type;
    }

    return BuiltinTypes.String;
  }
}
