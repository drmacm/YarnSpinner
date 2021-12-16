
class Diagnostic {
  String FileName = "(not set)";
  int Line = 0;
  int Column = 0;
  String Message = "(internal error: no message provided)";

  String Context = null;
  DiagnosticSeverity Severity = DiagnosticSeverity.error;

  Diagnostic(String fileName, String message, [DiagnosticSeverity severity = DiagnosticSeverity.error]) {
    this.fileName = fileName;
    this.message = message;
    this.severity = severity;
  }

  Diagnostic(String message, [DiagnosticSeverity severity = DiagnosticSeverity.error]) {
  }

  Diagnostic(String fileName, ParserRuleContext context, String message, [DiagnosticSeverity severity = DiagnosticSeverity.error]) {
    this.fileName = fileName;
    column = context?.Start.Column ?? 0;
    line = context?.Start.Line ?? 0;
    this.message = message;
    this.context = context.getTextWithWhitespace();
    this.severity = severity;
  }

  Diagnostic(String fileName, int line, int column, String message, [DiagnosticSeverity severity = DiagnosticSeverity.error]) {
    this.fileName = fileName;
    this.column = column;
    this.line = line;
    this.message = message;
    this.severity = severity;
  }


  String toString() {
    var sb = StringBuilder();
    sb.append("${line}:${column}: ${severity}: ${message}");

    if (String.isNullOrEmpty(context) == false) {
      sb.appendLine();
      sb.appendLine(context);
    }


    return sb.toString();
  }

  bool equals(Object obj) {
    Diagnostic problem = obj as Diagnostic;
    return obj is Diagnostic && fileName == problem.fileName && line == problem.line && column == problem.column && message == problem.message && context == problem.context && severity == problem.severity;
  }

  @override
  int get hashCode {
    int hashCode = -1856104752;
    hashCode = (hashCode * -1521134295) + EqualityComparer<String>.default.getHashCode(fileName);
    hashCode = (hashCode * -1521134295) + line.getHashCode();
    hashCode = (hashCode * -1521134295) + column.getHashCode();
    hashCode = (hashCode * -1521134295) + EqualityComparer<String>.default.getHashCode(message);
    hashCode = (hashCode * -1521134295) + EqualityComparer<String>.default.getHashCode(context);
    hashCode = (hashCode * -1521134295) + severity.getHashCode();
    return hashCode;
  }
}

class DiagnosticSeverity {
  final int value;
  final String name;
  const DiagnosticSeverity._(this.value, this.name);

  static const error = const DiagnosticSeverity._(0, 'error');
  static const warning = const DiagnosticSeverity._(1, 'warning');
  static const info = const DiagnosticSeverity._(2, 'info');

  static const List<DiagnosticSeverity> values = [
    error,
    warning,
    info,
  ];

  @override
  String toString() => 'DiagnosticSeverity' + '.' + name;

}

class LexerErrorListener implements IAntlrErrorListener<int> {
  final List<Diagnostic> _diagnostics = List<Diagnostic>();

  Iterable<Diagnostic> get diagnostics => _diagnostics;

  void syntaxError(TextWriter output, IRecognizer recognizer, int offendingSymbol, int line, int charPositionInLine, String msg, RecognitionException e) {
    _diagnostics.add(Diagnostic(null, line, charPositionInLine, msg));
  }
}

class ParserErrorListener extends BaseErrorListener {
  final List<Diagnostic> _diagnostics = List<Diagnostic>();

  Iterable<Diagnostic> get diagnostics => _diagnostics;

  void syntaxError(TextWriter output, IRecognizer recognizer, IToken offendingSymbol, int line, int charPositionInLine, String msg, RecognitionException e) {
    var diagnostic = Diagnostic(null, line, charPositionInLine, msg);

    if (offendingSymbol.TokenSource != null) {
      StringBuilder builder = StringBuilder();

      // the line with the error on it
      String input = offendingSymbol.TokenSource.InputStream.toString();
      List<String> lines = input.split('\n');
      String errorLine = lines[line - 1];
      builder.appendLine(errorLine);

      // adding indicator symbols pointing out where the error is
      // on the line
      int start = offendingSymbol.StartIndex;
      int stop = offendingSymbol.StopIndex;
      if (start >= 0 && stop >= 0) {
        // the end point of the error in "line space"
        int end = (stop - start) + charPositionInLine + 1;
        for (int i = 0; i < end; i++) {
          // move over until we are at the point we need to
          // be
          if (i >= charPositionInLine && i < end) {
            builder.append("^");
          }
          else {
            builder.append(" ");
          }
        }
      }


      diagnostic.context = builder.toString();
    }


    _diagnostics.add(diagnostic);
  }
}
