import 'package:yarn_spinner.compiler.framework/src/upgrader/i_language_upgrader.dart';
import 'package:yarn_spinner.compiler.framework/src/upgrader/language_upgrader.dart';
import 'package:yarn_spinner.compiler.framework/src/upgrader/upgraders/v1to_v2/yarn_spinner_v1_lexer.dart';
import 'package:yarn_spinner.compiler.framework/src/upgrader/upgraders/v1to_v2/yarn_spinner_v1_parser.dart';
import 'package:yarn_spinner.compiler.framework/src/upgrader/upgraders/v1to_v2/yarn_spinner_v1_parser_base_listener.dart';

class FormatFunctionUpgrader implements ILanguageUpgrader {
  @override
  UpgradeResult upgrade(UpgradeJob upgradeJob) {
    var outputFiles = List<OutputFile>();

    for (var file in upgradeJob.files) {
      var replacements = List<TextReplacement>();

      ICharStream input = CharStreams.fromstring(file.source);
      YarnSpinnerV1Lexer lexer = YarnSpinnerV1Lexer(input);
      CommonTokenStream tokens = CommonTokenStream(lexer);
      YarnSpinnerV1Parser parser = YarnSpinnerV1Parser(tokens);

      var tree = parser.dialogue();

      var walker = ParseTreeWalker();

      var formatFunctionListener = _FormatFunctionListener(file.source, parser, (replacement) => replacements.add(replacement));

      walker.walk(formatFunctionListener, tree);

      outputFiles.add(OutputFile(file.fileName, replacements, file.source));
    }

    var result = UpgradeResult;
    result.files = outputFiles;
    return result;
  }

}
class _FormatFunctionListener extends YarnSpinnerV1ParserBaseListener {
  String _contents;
  YarnSpinnerV1Parser _parser;
  Function<TextReplacement> _replacementCallback;

  _FormatFunctionListener(String contents, YarnSpinnerV1Parser parser, Function<TextReplacement> replacementCallback) {
    _contents = contents;
    _parser = parser;
    _replacementCallback = replacementCallback;
  }

  void exitFormat_function(Format_functionContext context) {
    // V1: [select {$gender} male="male" female="female" other="other"]
    //  function_name: "select" variable: "$gender" key_value_pair="male="male"..."
    //
    // V2: [select value={$gender} male="male" female="female" other="other"/]
    var formatFunctionType = context.function_name?.Text;
    var variableContext = context.variable();

    if (formatFunctionType == null || variableContext == null) {
      // Not actually a format function, but the parser may
      // have misinterpreted it? Do nothing here.
      return;
    }


    var variableName = variableContext.getText();

    StringBuilder sb = StringBuilder();
    sb.append("${formatFunctionType} value={{${variableName}}}");

    for (var kvp in context.key_value_pair()) {
      sb.append(" ${kvp.getText()}");
    }

    sb.append(" /");

    // '[' and ']' are tokens that wrap this format_function,
    // so we're just replacing its innards
    var originalLength = context.Stop.StopIndex + 1 - context.Start.StartIndex;
    var originalStart = context.Start.StartIndex;
    var originalText = _contents.substring(originalStart, originalLength);

    var replacement = TextReplacement();
    replacement.start = context.Start.StartIndex;
    replacement.startLine = context.Start.Line;
    replacement.originalText = originalText;
    replacement.replacementText = sb.toString();
    replacement.comment = "Format functions have been replaced with markup.";

    // Deliver the replacement!
    _replacementCallback(replacement);
  }
}
