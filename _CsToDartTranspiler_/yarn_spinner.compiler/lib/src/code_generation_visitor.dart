import 'package:yarn_spinner.compiler.framework/src/compiler.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_lexer.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser_base_visitor.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser_expression.dart';
import 'package:yarn_spinner.framework/yarn_spinner.framework.dart';

// the visitor for the body of the node does not really return ints,
// just has to return something might be worth later investigating
// returning Instructions
class CodeGenerationVisitor extends YarnSpinnerParserBaseVisitor<int> {
  Compiler compiler;

  CodeGenerationVisitor(Compiler compiler) {
    this.compiler = compiler;
  }

  int _generateCodeForExpressionsInFormattedText(IList<IParseTree> nodes) {
    int expressionCount = 0;

    // First, visit all of the nodes, which are either terminal
    // text nodes or expressions. if they're expressions, we
    // evaluate them, and inject a positional reference into the
    // final string.
    for (var child in nodes) {
      if (child is ITerminalNode) {
      }
      else if (child is ParserRuleContext) {
        // assume that this is an expression (the parser only
        // permits them to be expressions, but we can't specify
        // that here) - visit it, and we will emit code that
        // pushes the final value of this expression onto the
        // stack. running the line will pop these expressions
        // off the stack.

        Visit(child);
        expressionCount += 1;
      }

    }

    return expressionCount;
  }

  List<String> _getHashtagTexts(List<HashtagContext> hashtags) {
    // Add hashtag
    var hashtagText = List<String>();
    for (var tag in hashtags) {
      hashtagText.add(tag.hASHTAG_TEXT().getText());
    }
    return hashtagText.toArray();
  }

  // a regular ol' line of text
  int visitLine_statement(Line_statementContext context) {
    // TODO: add support for line conditions:
    //
    // Mae: here's a line <<if true>>
    //
    // is identical to
    //
    // <<if true>> Mae: here's a line <<endif>>

    // Evaluate the inline expressions and push the results onto
    // the stack.
    var expressionCount = _generateCodeForExpressionsInFormattedText(context.line_formatted_text().children);

    // Get the lineID for this string from the hashtags
    var lineIDTag = Compiler.getLineIDTag(context.hashtag());

    if (lineIDTag == null) {
      throw InvalidOperationException("Internal error: line should have an implicit or explicit line ID tag, but none was found");
    }


    var lineID = lineIDTag.text.Text;

    compiler.emit1(OpCode.runLine, Operand(lineID), Operand(expressionCount));

    return 0;
  }

  // A set command: explicitly setting a value to an expression <<set
  // $foo to 1>>
  int visitSet_statement(Set_statementContext context) {
    // Ensure that the correct result is on the stack by evaluating
    // the expression. If this assignment includes an operation
    // (e.g. +=), do that work here too.
    switch (context.op.Type) {
      case YarnSpinnerLexer.oPERATOR_ASSIGNMENT: {
        Visit(context.expression());
      }
      case YarnSpinnerLexer.oPERATOR_MATHS_ADDITION_EQUALS: {
        _generateCodeForOperation(Operator.Operator, context.expression().type, context.variable(), context.expression());
      }
      case YarnSpinnerLexer.oPERATOR_MATHS_SUBTRACTION_EQUALS: {
        _generateCodeForOperation(Operator.Operator, context.expression().type, context.variable(), context.expression());
      }
      case YarnSpinnerLexer.oPERATOR_MATHS_MULTIPLICATION_EQUALS: {
        _generateCodeForOperation(Operator.Operator, context.expression().type, context.variable(), context.expression());
      }
      case YarnSpinnerLexer.oPERATOR_MATHS_DIVISION_EQUALS: {
        _generateCodeForOperation(Operator.Operator, context.expression().type, context.variable(), context.expression());
      }
      case YarnSpinnerLexer.oPERATOR_MATHS_MODULUS_EQUALS: {
        _generateCodeForOperation(Operator.Operator, context.expression().type, context.variable(), context.expression());
      }
    }

    // now store the variable and clean up the stack
    String variableName = context.variable().getText();
    compiler.emit1(OpCode.storeVariable, Operand(variableName));
    compiler.emit1(OpCode.pop);
    return 0;
  }

  int visitCall_statement(Call_statementContext context) {
    // Visit our function call, which will invoke the function
    Visit(context.function_call());

    // TODO: if this function returns a value, it will be pushed
    // onto the stack, but there's no way for the compiler to know
    // that, so the stack will not be tidied up. is there a way for
    // that to work?
    return 0;
  }

  // semi-free form text that gets passed along to the game for
  // things like <<turn fred left>> or <<unlockAchievement
  // FacePlant>>
  int visitCommand_statement(Command_statementContext context) {
    var expressionCount = 0;
    var sb = StringBuilder();
    for (var node in context.command_formatted_text().children) {
      if (node is ITerminalNode) {
        sb.append(node.getText());
      }
      else if (node is ParserRuleContext) {
        // Generate code for evaluating the expression at runtime
        Visit(node);

        // Don't include the '{' and '}', because it will have
        // been added as a terminal node already
        sb.append(expressionCount);
        expressionCount += 1;
      }

    }

    var composedString = sb.toString();

    // TODO: look into replacing this as it seems a bit odd
    switch (composedString) {
      case "stop": {
        // "stop" is a special command that immediately stops
        // execution
        compiler.emit1(OpCode.stop);
      }
      default: {
        compiler.emit1(OpCode.runCommand, Operand(composedString), Operand(expressionCount));
      }
    }

    return 0;
  }

  // emits the required bytecode for the function call
  void _handleFunction(String functionName, List<ExpressionContext> parameters) {
    // generate the instructions for all of the parameters
    for (var parameter in parameters) {
      Visit(parameter);
    }

    // push the number of parameters onto the stack
    compiler.emit1(OpCode.pushFloat, Operand(parameters.length));

    // then call the function itself
    compiler.emit1(OpCode.callFunc, Operand(functionName));
  }
  // handles emiting the correct instructions for the function
  int visitFunction_call(Function_callContext context) {
    String functionName = context.fUNC_ID().getText();

    _handleFunction(functionName, context.expression());

    return 0;
  }

  // if statement ifclause (elseifclause)* (elseclause)? <<endif>>
  int visitIf_statement(If_statementContext context) {
    context.addErrorNode(null);
    // label to give us a jump point for when the if finishes
    String endOfIfStatementLabel = compiler.registerLabel("endif");

    // handle the if
    var ifClause = context.if_clause();
    generateClause(endOfIfStatementLabel, ifClause.statement(), ifClause.expression());

    // all elseifs
    for (var elseIfClause in context.else_if_clause()) {
      generateClause(endOfIfStatementLabel, elseIfClause.statement(), elseIfClause.expression());
    }

    // the else, if there is one
    var elseClause = context.else_clause();
    if (elseClause != null) {
      generateClause(endOfIfStatementLabel, elseClause.statement(), null);
    }


    compiler.currentNode.labels.add(endOfIfStatementLabel, compiler.currentNode.instructions.Count);

    return 0;
  }

  void generateClause(String jumpLabel, List<StatementContext> children, ExpressionContext expression) {
    String endOfClauseLabel = compiler.registerLabel("skipclause");

    // handling the expression (if it has one) will only be called
    // on ifs and elseifs
    if (expression != null) {
      // Code-generate the expression
      Visit(expression);

      compiler.emit1(OpCode.jumpIfFalse, Operand(endOfClauseLabel));
    }


    // running through all of the children statements
    for (var child in children) {
      Visit(child);
    }

    compiler.emit1(OpCode.jumpTo, Operand(jumpLabel));

    if (expression != null) {
      compiler.currentNode.labels.add(endOfClauseLabel, compiler.currentNode.instructions.Count);
      compiler.emit1(OpCode.pop);
    }

  }

  // for the shortcut options (-> line of text <<if expression>>
  // indent statements dedent)+
  int visitShortcut_option_statement(Shortcut_option_statementContext context) {
    String endOfGroupLabel = compiler.registerLabel("group_end");

    var labels = List<String>();

    int optionCount = 0;

    // For each option, create an internal destination label that,
    // if the user selects the option, control flow jumps to. Then,
    // evaluate its associated line_statement, and use that as the
    // option text. Finally, add this option to the list of
    // upcoming options.
    for (var shortcut in context.shortcut_option()) {
      // Generate the name of internal label that we'll jump to
      // if this option is selected. We'll emit the label itself
      // later.
      String optionDestinationLabel = compiler.registerLabel("shortcutoption_${compiler.currentNode.name ?? "node"}_${optionCount + 1}");
      labels.add(optionDestinationLabel);

      // This line statement may have a condition on it. If it
      // does, emit code that evaluates the condition, and add a
      // flag on the 'Add Option' instruction that indicates that
      // a condition exists.

      bool hasLineCondition = false;
      if (shortcut.line_statement().line_condition() != null) {
        // Evaluate the condition, and leave it on the stack
        Visit(shortcut.line_statement().line_condition().expression());

        hasLineCondition = true;
      }


      // We can now prepare and add the option.

      // Start by figuring out the text that we want to add. This
      // will involve evaluating any inline expressions.
      var expressionCount = _generateCodeForExpressionsInFormattedText(shortcut.line_statement().line_formatted_text().children);

      // Get the line ID from the hashtags if it has one
      var lineIDTag = Compiler.getLineIDTag(shortcut.line_statement().hashtag());
      String lineID = lineIDTag.text.Text;

      if (lineIDTag == null) {
        throw InvalidOperationException("Internal error: no line ID provided");
      }


      // And add this option to the list.
      compiler.emit1(OpCode.addOption, Operand(lineID), Operand(optionDestinationLabel), Operand(expressionCount), Operand(hasLineCondition));

      optionCount++;
    }

    // All of the options that we intend to show are now ready to
    // go.
    compiler.emit1(OpCode.showOptions);

    // The top of the stack now contains the name of the label we
    // want to jump to. Jump to it now.
    compiler.emit1(OpCode.jump);

    // We'll now emit the labels and code associated with each
    // option.
    optionCount = 0;
    for (var shortcut in context.shortcut_option()) {
      // Emit the label for this option's code
      compiler.currentNode.labels.add(labels[optionCount], compiler.currentNode.instructions.Count);

      // Run through all the children statements of the shortcut
      // option.
      for (var child in shortcut.statement()) {
        Visit(child);
      }

      // Jump to the end of this shortcut option group.
      compiler.emit1(OpCode.jumpTo, Operand(endOfGroupLabel));

      optionCount++;
    }

    // We made it to the end! Mark the end of the group, so we can
    // jump to it.
    compiler.currentNode.labels.add(endOfGroupLabel, compiler.currentNode.instructions.Count);
    compiler.emit1(OpCode.pop);

    return 0;
  }

  // the calls for the various operations and expressions first the
  // special cases (), unary -, !, and if it is just a value by
  // itself


  // (expression)
  int visitExpParens(ExpParensContext context) {
    return Visit(context.expression());
  }

  // -expression
  int visitExpNegative(ExpNegativeContext context) {
    _generateCodeForOperation(Operator.Operator, context.type, context.expression());

    return 0;
  }

  // (not NOT !)expression
  int visitExpNot(ExpNotContext context) {
    _generateCodeForOperation(Operator.Operator, context.type, context.expression());

    return 0;
  }

  // variable
  int visitExpValue(ExpValueContext context) {
    return Visit(context.value());
  }


  void _generateCodeForOperation(Operator op, IType type, List<ParserRuleContext> operands) {
    // Generate code for each of the operands, so that their value
    // is now on the stack.
    for (var operand in operands) {
      visit(operand);
    }

    // Indicate that we are pushing this many items for comparison
    compiler.emit1(OpCode.pushFloat, Operand(operands.length));

    // Figure out the canonical name for the method that the VM
    // should invoke in order to perform this work
    IType implementingType = TypeUtil.findImplementingTypeForMethod(type, op.toString());

    // Couldn't find an implementation method? That's an error! The
    // type checker should have caught this.
    if (implementingType == null) {
      throw InvalidOperationException("Internal error: Codegen failed to get implementation type for ${op} given input type ${type.name}.");
    }


    String functionName = TypeUtil.getCanonicalNameForMethod(implementingType, op.toString());

    // Call that function.
    compiler.emit1(OpCode.callFunc, Operand(functionName));
  }

  // * / %
  int visitExpMultDivMod(ExpMultDivModContext context) {
    _generateCodeForOperation(tokensToOperators[context.op.Type], context.type, context.expression12(0), context.expression12(1));

    return 0;
  }

  // + -
  int visitExpAddSub(ExpAddSubContext context) {
    _generateCodeForOperation(tokensToOperators[context.op.Type], context.type, context.expression15(0), context.expression15(1));

    return 0;
  }
  // < <= > >=
  int visitExpComparison(ExpComparisonContext context) {
    _generateCodeForOperation(tokensToOperators[context.op.Type], context.type, context.expression13(0), context.expression13(1));

    return 0;
  }

  // == !=
  int visitExpEquality(ExpEqualityContext context) {
    _generateCodeForOperation(tokensToOperators[context.op.Type], context.type, context.expression16(0), context.expression16(1));

    return 0;
  }

  // and && or || xor ^
  int visitExpAndOrXor(ExpAndOrXorContext context) {
    _generateCodeForOperation(tokensToOperators[context.op.Type], context.type, context.expression14(0), context.expression14(1));

    return 0;
  }

  // the calls for the various value types this is a wee bit messy
  // but is easy to extend, easy to read and requires minimal
  // checking as ANTLR has already done all that does have code
  // duplication though
  int visitValueVar(ValueVarContext context) {
    return Visit(context.variable());
  }

  int visitValueNumber(ValueNumberContext context) {
    double number = double.parse(context.nUMBER().getText(), CultureInfo.invariantCulture);
    compiler.emit1(OpCode.pushFloat, Operand(number));

    return 0;
  }

  int visitValueTrue(ValueTrueContext context) {
    compiler.emit1(OpCode.pushBool, Operand(true));

    return 0;
  }

  int visitValueFalse(ValueFalseContext context) {
    compiler.emit1(OpCode.pushBool, Operand(false));
    return 0;
  }

  int visitVariable(VariableContext context) {
    String variableName = context.vAR_ID().getText();
    compiler.emit1(OpCode.pushVariable, Operand(variableName));

    return 0;
  }

  int visitValueString(ValueStringContext context) {
    // stripping the " off the front and back actually is this what
    // we want?
    String stringVal = context.sTRING().getText().trim('"');

    compiler.emit1(OpCode.pushString, Operand(stringVal));

    return 0;
  }
  // all we need do is visit the function itself, it will handle
  // everything
  int visitValueFunc(ValueFuncContext context) {
    Visit(context.function_call());

    return 0;
  }
  // null value
  int visitValueNull(ValueNullContext context) {
    compiler.emit1(OpCode.pushNull);
    return 0;
  }

  int visitDeclare_statement(Declare_statementContext context) {
    // Declare statements do not participate in code generation
    return 0;
  }

  // A <<jump>> command, which immediately jumps to another node.
  int visitJump_statement(Jump_statementContext context) {
    compiler.emit1(OpCode.pushString, Operand(context.destination.Text));
    compiler.emit1(OpCode.runNode);

    return 0;
  }

  // TODO: figure out a better way to do operators
  static final Map<int, Operator> TokensToOperators = {  // operators for the standard expressions
YarnSpinnerLexer.oPERATOR_LOGICAL_LESS_THAN_EQUALS: Operator.Operator, YarnSpinnerLexer.oPERATOR_LOGICAL_GREATER_THAN_EQUALS: Operator.Operator, YarnSpinnerLexer.oPERATOR_LOGICAL_LESS: Operator.Operator, YarnSpinnerLexer.oPERATOR_LOGICAL_GREATER: Operator.Operator, YarnSpinnerLexer.oPERATOR_LOGICAL_EQUALS: Operator.Operator, YarnSpinnerLexer.oPERATOR_LOGICAL_NOT_EQUALS: Operator.Operator, YarnSpinnerLexer.oPERATOR_LOGICAL_AND: Operator.Operator, YarnSpinnerLexer.oPERATOR_LOGICAL_OR: Operator.Operator, YarnSpinnerLexer.oPERATOR_LOGICAL_XOR: Operator.Operator, YarnSpinnerLexer.oPERATOR_LOGICAL_NOT: Operator.Operator, YarnSpinnerLexer.oPERATOR_MATHS_ADDITION: Operator.Operator, YarnSpinnerLexer.oPERATOR_MATHS_SUBTRACTION: Operator.Operator, YarnSpinnerLexer.oPERATOR_MATHS_MULTIPLICATION: Operator.Operator, YarnSpinnerLexer.oPERATOR_MATHS_DIVISION: Operator.Operator, YarnSpinnerLexer.oPERATOR_MATHS_MODULUS: Operator.Operator};
}
