import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_lexer.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser_expression.dart';
class ErrorStrategy extends DefaultErrorStrategy {
  /// <inheritdoc
  void reportNoViableAlternative(Parser recognizer, NoViableAltException e) {
    String msg = null;

    if (_isInsideRule<If_statementContext>(recognizer) && recognizer.RuleContext is YarnSpinnerParserStatementContext && e.StartToken.Type == YarnSpinnerLexer.cOMMAND_START && e.OffendingToken.Type == YarnSpinnerLexer.cOMMAND_ELSE) {
      // We are inside an if statement, we're attempting to parse a
      // statement, and we got an '<<', 'else', and we weren't able
      // to match that. The programmer included an extra '<<else>>'.
      _ = _getEnclosingRule<If_statementContext>(recognizer);

      msg = "More than one <<else>> statement in an <<if>> statement isn't allowed";
    }
    else if (e.StartToken.Type == YarnSpinnerLexer.cOMMAND_START && e.OffendingToken.Type == YarnSpinnerLexer.cOMMAND_END) {
      // We saw a << immediately followed by a >>. The programmer
      // forgot to include command text.
      msg = "Command text expected";
    }


    if (msg == null) {
      msg = "Unexpected \"${e.OffendingToken.Text}\" while reading ${_getFriendlyNameForRuleContext(recognizer.RuleContext, true)}";
    }


    recognizer.notifyErrorListeners(e.OffendingToken, msg, e);
  }

  /// <inheritdoc
  void reportInputMismatch(Parser recognizer, InputMismatchException e) {
    String msg = null;

    switch (recognizer.RuleContext) {
      case If_statementContext: {
        val ifStatement = tmp
        if (e.OffendingToken.Type == YarnSpinnerLexer.bODY_END) {
          // We have exited a body in the middle of an if
          // statement. The programmer forgot to include an
          // <<endif>>.
          msg = "Expected an <<endif>> to match the <<if>> statement on line ${ifStatement.Start.Line}";
        }
        else if (e.OffendingToken.Type == YarnSpinnerLexer.cOMMAND_ELSE && recognizer.getExpectedTokens().contains(YarnSpinnerLexer.cOMMAND_ENDIF)) {
          // We saw an else, but we expected to see an endif. The
          // programmer wrote an additional <<else>>.
          msg = "More than one <<else>> statement in an <<if>> statement isn't allowed";
        }


      }
      case VariableContext: {
        if (e.OffendingToken.Type == YarnSpinnerLexer.fUNC_ID) {
          // We're parsing a variable (which starts with a '$'),
          // but we encountered a FUNC_ID (which doesn't). The
          // programmer forgot to include the '$'.
          msg = "Variable names need to start with a $";
        }


      }
    }

    if (msg == null) {
      msg = "Unexpected \"${e.OffendingToken.Text}\" while reading ${_getFriendlyNameForRuleContext(recognizer.RuleContext, true)}";
    }


    notifyErrorListeners(recognizer, msg, e);
  }

  bool _isInsideRule<TRuleType>(Parser recognizer) {
    RuleContext currentContext = recognizer.RuleContext;

    while (currentContext != null) {
      if (currentContext.getType() == TRuleType.runtimeType) {
        return true;
      }


      currentContext = currentContext.Parent;
    }

    return false;
  }

  TRuleType _getEnclosingRule<TRuleType>(Parser recognizer) {
    RuleContext currentContext = recognizer.RuleContext;

    while (currentContext != null) {
      if (currentContext.getType() == TRuleType.runtimeType) {
        return currentContext as TRuleType;
      }


      currentContext = currentContext.Parent;
    }

    return null;
  }

  String _getFriendlyNameForRuleContext(RuleContext context, [bool withArticle = false]) {
    String ruleName = YarnSpinnerParser.ruleNames[context.RuleIndex];

    String friendlyName = ruleName.replace("_", " ");

    if (withArticle) {
      // If the friendly name's first character is a vowel, the
      // article is 'an'; otherwise, 'a'.
      String firstLetter = System.Linq.Enumerable.first(friendlyName);

      String article;

      List<String> englishVowels = ['a', 'e', 'i', 'o', 'u'];

      article = System.Linq.Enumerable.contains(englishVowels, firstLetter) ? "an" : "a";

      return "${article} ${friendlyName}";
    }
    else {
      return friendlyName;
    }
  }
}
