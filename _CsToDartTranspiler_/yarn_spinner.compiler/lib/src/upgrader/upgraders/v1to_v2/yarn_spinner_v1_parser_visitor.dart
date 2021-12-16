//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     ANTLR Version: 4.8
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

import 'package:yarn_spinner.compiler.framework/src/upgrader/upgraders/v1to_v2/yarn_spinner_v1_parser.dart';

// Generated from /Users/desplesda/Work/yarnspinner/YarnSpinner.Compiler/Upgrader/Upgraders/V1toV2/YarnSpinnerV1Parser.g4 by ANTLR 4.8

// Unreachable code detected
// The variable '...' is assigned but its value is never used
// Missing XML comment for publicly visible type or member '...'
// Ambiguous reference in cref attribute


abstract class IYarnSpinnerV1ParserVisitor<Result> implements IParseTreeVisitor<Result> {
  Result visitDialogue(DialogueContext context);
  Result visitFile_hashtag(File_hashtagContext context);
  Result visitNode(NodeContext context);
  Result visitHeader(HeaderContext context);
  Result visitBody(BodyContext context);
  Result visitStatement(StatementContext context);
  Result visitLine_statement(Line_statementContext context);
  Result visitLine_formatted_text(Line_formatted_textContext context);
  Result visitFormat_function(Format_functionContext context);
  Result visitKeyValuePairNamed(KeyValuePairNamedContext context);
  Result visitKeyValuePairNumber(KeyValuePairNumberContext context);
  Result visitHashtag(HashtagContext context);
  Result visitLine_condition(Line_conditionContext context);
  Result visitExpParens(ExpParensContext context);
  Result visitExpMultDivMod(ExpMultDivModContext context);
  Result visitExpMultDivModEquals(ExpMultDivModEqualsContext context);
  Result visitExpComparison(ExpComparisonContext context);
  Result visitExpNegative(ExpNegativeContext context);
  Result visitExpAndOrXor(ExpAndOrXorContext context);
  Result visitExpPlusMinusEquals(ExpPlusMinusEqualsContext context);
  Result visitExpAddSub(ExpAddSubContext context);
  Result visitExpNot(ExpNotContext context);
  Result visitExpValue(ExpValueContext context);
  Result visitExpEquality(ExpEqualityContext context);
  Result visitValueNumber(ValueNumberContext context);
  Result visitValueTrue(ValueTrueContext context);
  Result visitValueFalse(ValueFalseContext context);
  Result visitValueVar(ValueVarContext context);
  Result visitValueString(ValueStringContext context);
  Result visitValueNull(ValueNullContext context);
  Result visitValueFunc(ValueFuncContext context);
  Result visitVariable(VariableContext context);
  Result visitFunction(FunctionContext context);
  Result visitIf_statement(If_statementContext context);
  Result visitIf_clause(If_clauseContext context);
  Result visitElse_if_clause(Else_if_clauseContext context);
  Result visitElse_clause(Else_clauseContext context);
  Result visitSetVariableToValue(SetVariableToValueContext context);
  Result visitSetExpression(SetExpressionContext context);
  Result visitCall_statement(Call_statementContext context);
  Result visitCommand_statement(Command_statementContext context);
  Result visitCommand_formatted_text(Command_formatted_textContext context);
  Result visitShortcut_option_statement(Shortcut_option_statementContext context);
  Result visitShortcut_option(Shortcut_optionContext context);
  Result visitOptionLink(OptionLinkContext context);
  Result visitOptionJump(OptionJumpContext context);
  Result visitOption_formatted_text(Option_formatted_textContext context);
}
// namespace Yarn.Compiler
