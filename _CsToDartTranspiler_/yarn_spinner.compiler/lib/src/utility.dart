import 'package:yarn_spinner.compiler.framework/src/compiler.dart';
import 'package:yarn_spinner.framework/yarn_spinner.framework.dart';

class Utility {
  static final Random _Random = Random();

  static String generateYarnFileWithDeclarations(Iterable<Declaration> declarations, [String title = "Program", Iterable<String> tags = null, Map<String, String> headers = null]) {
    var stringBuilder = StringBuilder();

    stringBuilder.appendLine("title: ${title}");

    if (tags != null) {
      stringBuilder.appendLine("tags: ${String.join(" ", tags)}");
    }


    if (headers != null) {
      for (var kvp in headers) {
        stringBuilder.appendLine("${kvp.key}: ${kvp.value}");
      }
    }


    stringBuilder.appendLine("---");

    int count = 0;

    for (var decl in declarations) {
      if (decl.type is FunctionType) {
        throw ArgumentOutOfRangeException("Declaration ${decl.name} is a ${decl.type.name}; it must be a variable.");
      }


      if (String.isNullOrEmpty(decl.description) == false) {
        if (count > 0) {
          // Insert a blank line above this comment, for readibility
          stringBuilder.appendLine();
        }

        stringBuilder.appendLine("/// ${decl.description}");
      }


      stringBuilder.append("<<declare ${decl.name} = ");

      if (decl.type == BuiltinTypes.number) {
        stringBuilder.append(decl.defaultValue);
      }
      else if (decl.type == BuiltinTypes.String) {
        stringBuilder.append('"' + decl.defaultValue as String + '"');
      }
      else if (decl.type == BuiltinTypes.bool) {
        stringBuilder.append(decl.defaultValue as bool ? "true" : "false");
      }
      else {
        throw ArgumentOutOfRangeException("Declaration ${decl.name}'s type must not be ${decl.type.name}.");
      }

      stringBuilder.appendLine(">>");

      count += 1;
    }

    stringBuilder.appendLine("===");

    return stringBuilder.toString();
  }

  static String addTagsToLines(String contents, [ICollection<String> existingLineTags = null]) {
    var compileJob = CompilationJob.createFromString("input", contents);

    compileJob.compilationType = CompilationJob.Type.stringsOnly;

    var result = Compiler.compile(compileJob);

    var untaggedLines = result.stringTable.where((entry) => entry.Value.isImplicitTag);

    var allSourceLines = contents.split(["\n", "\r\n", "\n"], StringSplitOptions.none);


    HashSet<String> existingLines;
    if (existingLineTags != null) {
      existingLines = HashSet<String>(existingLineTags);
    }
    else {
      existingLines = HashSet<String>();
    }

    for (var untaggedLine in untaggedLines) {
      var lineNumber = untaggedLine.Value.lineNumber;
      var tag = "#" + _generateString(existingLines);

      var sourceLine = allSourceLines[lineNumber - 1];
      var updatedSourceLine = sourceLine.replace(untaggedLine.Value.text, "${untaggedLine.Value.text} ${tag}");

      allSourceLines[lineNumber - 1] = updatedSourceLine;

      existingLines.add(tag);
    }

    return String.join(Environment.newLine, allSourceLines);
  }

  static ValueTuple<FileParseResult, Iterable<Diagnostic>> parseSource(String source) {
    var diagnostics = List<Diagnostic>();
    var diagnosticsRef = RefParam(diagnostics);
    var result = Compiler.parseSyntaxTree1("<input>", source, diagnosticsRef);

    diagnostics = diagnosticsRef.value;
    return Tuple2.fromList([result, diagnostics]);
  }

  static String _generateString(ICollection<String> existingKeys) {
    String tag;
    do  {
      tag = String.format(CultureInfo.invariantCulture, "line:{0:x7}", _random.next(16777216));
    }
    while (existingKeys.contains(tag));

    return tag;
  }
}
