import 'package:yarn_spinner.framework/yarn_spinner.framework.dart';

class ParserRuleContextExtension {
  static String getTextWithWhitespace(ParserRuleContext context) {
    // We can't use "expressionContext.GetText()" here, because
    // that just concatenates the text of all captured tokens,
    // and doesn't include text on hidden channels (e.g.
    // whitespace and comments).
    var interval = Interval(context.Start.StartIndex, context.Stop.StopIndex);
    return context.Start.InputStream.getText(interval);
  }
}

class YarnSpinnerParser extends Parser {
}
class ExpressionContext extends ParserRuleContext {
  IType type;
}
