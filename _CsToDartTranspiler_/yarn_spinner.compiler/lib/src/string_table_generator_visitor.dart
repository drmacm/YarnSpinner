import 'package:yarn_spinner.compiler.framework/src/compiler.dart';
import 'package:yarn_spinner.compiler.framework/src/error_listener.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_lexer.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser_base_visitor.dart';

class StringTableGeneratorVisitor extends YarnSpinnerParserBaseVisitor<int> {

  final List<Diagnostic> _diagnostics = List<Diagnostic>();

  NodeContext _currentNodeContext;
  String _currentNodeName;
  String _fileName;
  StringTableManager _stringTableManager;


  Iterable<Diagnostic> get diagnostics => _diagnostics;

  StringTableGeneratorVisitor(String fileName, StringTableManager stringTableManager) {
    _fileName = fileName;
    _stringTableManager = stringTableManager;
  }

  int visitNode(NodeContext context) {
    _currentNodeContext = context;

    List<String> tags = List<String>();

    for (var header in context.header()) {
      String headerKey = header.header_key.Text;
      String headerValue = header.header_value?.Text ?? String.empty;

      if (headerKey.equals("title", StringComparison.invariantCulture)) {
        _currentNodeName = header.header_value.Text;
      }


      if (headerKey.equals("tags", StringComparison.invariantCulture)) {
        // Split the list of tags by spaces, and use that
        tags = List<String>(headerValue.split([' '], StringSplitOptions.removeEmptyEntries));
      }

    }

    if (String.isNullOrEmpty(_currentNodeName) == false && tags.contains("rawText")) {
      // This is a raw text node. Use its entire contents as a
      // string and don't use its contents.
      var lineID = Compiler.getLineIDForNodeName(_currentNodeName);
      _stringTableManager.registerString(context.body().getText(), _fileName, _currentNodeName, lineID, context.body().Start.Line, null);
    }
    else {
      // This is a regular node
      // this.Visit(context.body());

      var body = context.body();
      if (body != null) {
        visit(body);
      }

    }

    return 0;
  }

  int visitLine_statement(Line_statementContext context) {
    int lineNumber = context.Start.Line;

    List<HashtagContext> hashtags = context.hashtag();
    var lineIDTag = Compiler.getLineIDTag(hashtags);
    var lineID = lineIDTag?.text.Text ?? null;

    var hashtagText = _getHashtagTexts(hashtags);

    var composedString = null;
    var composedStringRef = RefParam(composedString);
    var expressionCount = 0;
    var expressionCountRef = RefParam(expressionCount);
    _generateFormattedText(context.line_formatted_text().children, composedStringRef, expressionCountRef);

    // Does this string table already have a string with this ID?
    composedString = composedStringRef.value;
    expressionCount = expressionCountRef.value;
    if (lineID != null && _stringTableManager.containsKey(lineID)) {
      // If so, this is an error.
      ParserRuleContext diagnosticContext;

      diagnosticContext = lineIDTag ?? context as ParserRuleContext;

      _diagnostics.add(Diagnostic(_fileName, diagnosticContext, "Duplicate line ID ${lineID}"));

      return 0;
    }


    String stringID = _stringTableManager.registerString(composedString.toString(), _fileName, _currentNodeName, lineID, lineNumber, hashtagText);

    if (lineID == null) {
      var hashtag = HashtagContext(context, 0);
      hashtag.text = CommonToken(YarnSpinnerLexer.hASHTAG_TEXT, stringID);
      context.addChild(hashtag);
    }


    return 0;
  }

  List<String> _getHashtagTexts(List<HashtagContext> hashtags) {
    // Add hashtag
    var hashtagText = List<String>();
    for (var tag in hashtags) {
      hashtagText.add(tag.hASHTAG_TEXT().getText());
    }

    return hashtagText.toArray();
  }

  void _generateFormattedText(IList<IParseTree> nodes, RefParam<String> outputString, RefParam<int> expressionCount) {
    expressionCount.value = 0;
    StringBuilder composedString = StringBuilder();

    // First, visit all of the nodes, which are either terminal
    // text nodes or expressions. if they're expressions, we
    // evaluate them, and inject a positional reference into the
    // final string.
    for (var child in nodes) {
      if (child is ITerminalNode) {
        composedString.append(child.getText());
      }
      else if (child is ParserRuleContext) {
        // Expressions in the final string are denoted as the
        // index of the expression, surrounded by braces { }.
        // However, we don't need to write the braces here
        // ourselves, because the text itself that the parser
        // captured already has them. So, we just need to write
        // the expression count.
        composedString.append(expressionCount.value);
        expressionCount.value += 1;
      }

    }

    outputString.value = composedString.toString().trim();
  }
}
