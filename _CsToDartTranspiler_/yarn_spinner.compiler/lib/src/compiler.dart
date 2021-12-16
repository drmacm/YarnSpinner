// Uncomment to ensure that all expressions have a known type at compile time
// #define VALIDATE_ALL_EXPRESSIONS

import 'package:yarn_spinner.compiler.framework/src/code_generation_visitor.dart';
import 'package:yarn_spinner.compiler.framework/src/declaration.dart';
import 'package:yarn_spinner.compiler.framework/src/declaration_visitor.dart';
import 'package:yarn_spinner.compiler.framework/src/error_listener.dart';
import 'package:yarn_spinner.compiler.framework/src/error_strategy.dart';
import 'package:yarn_spinner.compiler.framework/src/string_table_generator_visitor.dart';
import 'package:yarn_spinner.compiler.framework/src/type_check_visitor.dart';
import 'package:yarn_spinner.compiler.framework/src/type_declaration_listener.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_lexer.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser_base_listener.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser_expression.dart';
import 'package:yarn_spinner.framework/yarn_spinner.framework.dart';


class StringTableManager {
  Map<String, StringInfo> StringTable = Map<String, StringInfo>();

  bool get containsImplicitStringTags {
    for (var item in stringTable) {
      if (item.value.isImplicitTag) {
        return true;
      }

    }
    return false;
  }


  String registerString(String text, String fileName, String nodeName, String lineID, int lineNumber, List<String> tags) {
    String lineIDUsed;

    bool isImplicit = false;

    if (lineID == null) {
      lineIDUsed = "line:${fileName}-${nodeName}-${stringTable.count}";

      isImplicit = true;
    }
    else {
      lineIDUsed = lineID;

      isImplicit = false;
    }

    var theString = StringInfo(text, fileName, nodeName, lineNumber, isImplicit, tags);

    // Finally, add this to the string table, and return the line
    // ID.
    stringTable.add(lineIDUsed, theString);

    return lineIDUsed;
  }

  void add(Map<String, StringInfo> otherStringTable) {
    for (var entry in otherStringTable) {
      stringTable.add(entry.key, entry.value);
    }
  }

  bool containsKey(String lineID) {
    return stringTable.containsKey(lineID);
  }
}

class StringInfo {
  String text;

  String nodeName;

  int lineNumber = 0;

  String fileName;

  bool isImplicitTag = false;

  List<String> metadata = [];

  StringInfo(String text, String fileName, String nodeName, int lineNumber, bool isImplicitTag, List<String> metadata) {
    this.text = text;
    this.nodeName = nodeName;
    this.lineNumber = lineNumber;
    this.fileName = fileName;
    this.isImplicitTag = isImplicitTag;

    if (metadata != null) {
      this.metadata = metadata;
    }
    else {
      this.metadata = List<String>();
    }
  }
}

class CompilationJob {

  class File {
    String FileName;
    String Source;
  }


  class Type {
    final int value;
    final String name;
    const Type._(this.value, this.name);

    /// The compiler will do a full compilation, and
    static const fullCompilation = const Type._(0, 'fullCompilation');
    /// The compiler will derive only the variable and
    static const declarationsOnly = const Type._(1, 'declarationsOnly');
    /// The compiler will generate a string table
    static const stringsOnly = const Type._(2, 'stringsOnly');

    static const List<Type> values = [
      fullCompilation,
      declarationsOnly,
      stringsOnly,
    ];

    @override
    String toString() => 'Type' + '.' + name;

  }

  Iterable<File> Files;

  Library Library;

  Type CompilationType = Type.DeclarationsOnly;

  Iterable<Declaration> VariableDeclarations;

  static CompilationJob createFromFiles(Iterable<String> paths, [Library library = null]) {
    var fileList = List<File>();

    // Read every file and add it to the file list
    for (var path in paths) {
      var file0 = File;
      file0.fileName = path;
      file0.source = System.IO.File.readAllText(path);
      fileList.add(file0);
    }

    var result = CompilationJob;
    result.files = fileList.toArray();
    result.library = library;
    return result;
  }

  static CompilationJob createFromFiles1(List<String> paths) {
    return createFromFiles(paths as Iterable<String>);
  }

  static CompilationJob createFromString(String fileName, String source, [Library library = null]) {
    var item = File;
    item.source = source;
    item.fileName = fileName;
    var result = CompilationJob;
    result.files = [item];
    result.library = library;
    return result;
  }
}

class CompilationResult {
  Program program;

  Map<String, StringInfo> stringTable;

  Iterable<Declaration> declarations;

  bool containsImplicitStringTags = false;

  Map<String, Iterable<String>> fileTags;

  Iterable<Diagnostic> diagnostics;

  static CompilationResult combineCompilationResults(Iterable<CompilationResult> results, StringTableManager stringTableManager) {
    CompilationResult finalResult = new CompilationResult();

    var programs = List<Program>();
    var declarations = List<Declaration>();
    var tags = Map<String, Iterable<String>>();
    var diagnostics = List<Diagnostic>();

    for (var result in results) {
      programs.add(result.program);

      if (result.declarations != null) {
        declarations.addRange(result.declarations);
      }


      if (result.fileTags != null) {
        for (var kvp in result.fileTags) {
          tags.add(kvp.key, kvp.value);
        }
      }


      if (result.diagnostics != null) {
        diagnostics.addRange(result.diagnostics);
      }

    }

    var result = CompilationResult;
    result.program = Program.combine(programs.toArray());
    result.stringTable = stringTableManager.stringTable;
    result.declarations = declarations;
    result.containsImplicitStringTags = stringTableManager.containsImplicitStringTags;
    result.fileTags = tags;
    result.diagnostics = diagnostics;
    return result;
  }
}

class Compiler extends YarnSpinnerParserBaseListener {
  /// A regular expression used to detect illegal characters
  final Regex _invalidNodeTitleNameRegex = Regex("[\[<>\]{}\|:\s#\$]");

  int _labelCount = 0;

  Node currentNode;

  bool rawTextNode = false;

  Program program;

  FileParseResult fileParseResult = new FileParseResult();

  Iterable<Declaration> VariableDeclarations = List<Declaration>();

  Library library;

  Iterable<Diagnostic> get diagnostics => _diagnostics;


  List<Diagnostic> _diagnostics = List<Diagnostic>();


  Compiler(FileParseResult fileParseResult) {
    program = Program();
    this.fileParseResult = fileParseResult;
  }

  String parseTree;
  List<String> tokens;

  static CompilationResult compile(CompilationJob compilationJob) {
    var results = List<CompilationResult>();

    // All variable declarations that we've encountered during this
    // compilation job
    var derivedVariableDeclarations = List<Declaration>();

    // All variable declarations that we've encountered, PLUS the
    // ones we knew about before
    var knownVariableDeclarations = List<Declaration>();

    // All type definitions that we've encountered while parsing.
    var typeDeclarations = List<IType>(BuiltinTypes.Iterable<>);

    if (compilationJob.variableDeclarations != null) {
      knownVariableDeclarations.addRange(compilationJob.variableDeclarations);
    }


    var diagnostics = List<Diagnostic>();
 {
      // Get function declarations from the Standard Library
      Tuple2.fromList([Iterable<Declaration>declarationsRef, Iterable<Diagnostic>declarationDiagnosticsRef]) = getDeclarationsFromLibrary(StandardLibrary());

      diagnostics.addRange(declarationDiagnostics);

      knownVariableDeclarations.addRange(declarations);
    }

    // Get function declarations from the library, if provided
    if (compilationJob.library != null) {
      Tuple2.fromList([Iterable<Declaration>declarationsRef, Iterable<Diagnostic>declarationDiagnosticsRef]) = getDeclarationsFromLibrary(compilationJob.library);
      knownVariableDeclarations.addRange(declarations);
      diagnostics.addRange(declarationDiagnostics);
    }


    var parsedFiles = List<FileParseResult>();

    // First pass: parse all files, generate their syntax trees,
    // and figure out what variables they've declared
    var stringTableManager = StringTableManager();

    for (var file in compilationJob.files) {
      var diagnosticsRef = RefParam(diagnostics);
      var parseResult = _parseSyntaxTree(file, diagnosticsRef);
      diagnostics = diagnosticsRef.value;
      parsedFiles.add(parseResult);

      var diagnosticsRef1 = RefParam(diagnostics);
      _registerStrings(file.fileName, stringTableManager, parseResult.tree, diagnosticsRef);
    }

    diagnostics = diagnosticsRef1.value;
    if (compilationJob.compilationType == CompilationJob.Type.stringsOnly) {
      // Stop at this point
      var result = CompilationResult;
      result.declarations = null;
      result.containsImplicitStringTags = stringTableManager.containsImplicitStringTags;
      result.program = null;
      result.stringTable = stringTableManager.stringTable;
      result.diagnostics = diagnostics;
      return result;
    }


    // Find the type definitions in these files.
    var walker = ParseTreeWalker();
    for (var parsedFile in parsedFiles) {
      var typeDeclarationVisitor = TypeDeclarationListener(parsedFile.name, parsedFile.tokens, parsedFile.tree, typeDeclarationsRef);

      walker.walk(typeDeclarationVisitor, parsedFile.tree);

      diagnostics.addRange(typeDeclarationVisitor.diagnostics);
    }

    var fileTags = Map<String, Iterable<String>>();

    // Find the variable declarations in these files.
    for (var parsedFile in parsedFiles) {
      var newDeclarations;
      var newDeclarationsRef = RefParam(newDeclarations);
      var newFileTags;
      var newFileTagsRef = RefParam(newFileTags);
      var declarationDiagnostics;
      var declarationDiagnosticsRef = RefParam(declarationDiagnostics);
      _getDeclarations(parsedFile, knownVariableDeclarations, newDeclarationsRef, typeDeclarations, newFileTagsRef, declarationDiagnosticsRef);

      newDeclarations = newDeclarationsRef.value;
      newFileTags = newFileTagsRef.value;
      declarationDiagnostics = declarationDiagnosticsRef.value;
      derivedVariableDeclarations.addRange(newDeclarations);
      knownVariableDeclarations.addRange(newDeclarations);
      diagnostics.addRange(declarationDiagnostics);

      fileTags.add(parsedFile.name, newFileTags);
    }

    for (var parsedFile in parsedFiles) {
      var checker = TypeCheckVisitor(parsedFile.name, knownVariableDeclarations, typeDeclarations);

      checker.visit(parsedFile.tree);
      derivedVariableDeclarations.addRange(checker.newDeclarations);
      knownVariableDeclarations.addRange(checker.newDeclarations);
      diagnostics.addRange(checker.diagnostics);
    }

    if (compilationJob.compilationType == CompilationJob.Type.declarationsOnly) {
      // Stop at this point
      var result = CompilationResult;
      result.declarations = derivedVariableDeclarations;
      result.containsImplicitStringTags = false;
      result.program = null;
      result.stringTable = null;
      result.fileTags = fileTags;
      result.diagnostics = diagnostics;
      return result;
    }


    for (var parsedFile in parsedFiles) {
      CompilationResult compilationResult = _generateCode(parsedFile, knownVariableDeclarations, compilationJob, stringTableManager);
      results.add(compilationResult);
    }

    var finalResult = CompilationResult.combineCompilationResults(results, stringTableManager);

    // Last step: take every variable declaration we found in all
    // of the inputs, and create an initial value registration for
    // it.
    for (var declaration in knownVariableDeclarations) {
      // We only care about variable declarations here
      if (declaration.type is FunctionType) {
        continue
      }


      if (declaration.type == BuiltinTypes.IType) {
        // This declaration has an undefined type; we will
        // already have created an error message for this, so
        // skip this one.
        continue
      }


      Operand value;

      if (declaration.defaultValue == null) {
        diagnostics.add(Diagnostic("Variable declaration ${declaration.name} (type ${declaration.type?.name ?? "undefined"}) has a null default value. This is not allowed."));
        continue
      }


      if (declaration.type == BuiltinTypes.String) {
        value = Operand(Convert.toString(declaration.defaultValue));
      }
      else if (declaration.type == BuiltinTypes.number) {
        value = Operand(Convert.toSingle(declaration.defaultValue));
      }
      else if (declaration.type == BuiltinTypes.bool) {
        value = Operand(Convert.toBoolean(declaration.defaultValue));
      }
      else {
        throw ArgumentOutOfRangeException("Cannot create an initial value for type ${declaration.type.name}");
      }

      finalResult.program.initialValues.add(declaration.name, value);
    }

    finalResult.declarations = derivedVariableDeclarations;

    finalResult.fileTags = fileTags;

    finalResult.diagnostics = finalResult.diagnostics.concat(diagnostics).distinct();

    // Do not return a program if any Errors were generated (even
    // if bytecode happened to be produced; it is not guaranteed to
    // work correctly.)
    if (finalResult.diagnostics.any((p) => p.Severity == Diagnostic.DiagnosticSeverity.error)) {
      finalResult.program = null;
    }


    return finalResult;
  }

  static void _registerStrings(String fileName, StringTableManager stringTableManager, IParseTree tree, RefParam<List<Diagnostic>> diagnostics) {
    var visitor = StringTableGeneratorVisitor(fileName, stringTableManager);
    visitor.visit(tree);
    diagnostics.value.addRange(visitor.diagnostics);
  }

  static void _getDeclarations(FileParseResult parsedFile, Iterable<Declaration> existingDeclarations, RefParam<Iterable<Declaration>> newDeclarations, Iterable<IType> typeDeclarations, RefParam<Iterable<String>> fileTags, RefParam<Iterable<Diagnostic>> diagnostics) {
    var variableDeclarationVisitor = DeclarationVisitor(parsedFile.name, existingDeclarations, typeDeclarations, parsedFile.tokens);

    var newDiagnosticList = List<Diagnostic>();

    variableDeclarationVisitor.visit(parsedFile.tree);

    newDiagnosticList.addRange(variableDeclarationVisitor.diagnostics);

    // Upon exit, newDeclarations will now contain every variable
    // declaration we found
    newDeclarations.value = variableDeclarationVisitor.newDeclarations;

    fileTags.value = variableDeclarationVisitor.fileTags;

    diagnostics.value = newDiagnosticList;
  }

  static CompilationResult _generateCode(FileParseResult fileParseResult, Iterable<Declaration> variableDeclarations, CompilationJob job, StringTableManager stringTableManager) {
    Compiler compiler = Compiler(fileParseResult);

    compiler.library = job.library;
    compiler.variableDeclarations = variableDeclarations;
    compiler.compile1();

    var result = CompilationResult;
    result.program = compiler.program;
    result.stringTable = stringTableManager.stringTable;
    result.containsImplicitStringTags = stringTableManager.containsImplicitStringTags;
    result.diagnostics = compiler.diagnostics;
    return result;
  }

  static ValueTuple<Iterable<Declaration>, Iterable<Diagnostic>> getDeclarationsFromLibrary(Library library) {
    var declarations = List<Declaration>();

    var diagnostics = List<Diagnostic>();

    for (var function in library.Map<, >) {
      var method = function.Value.Method;

      if (method.ReturnType == Value.runtimeType) {
        // Functions that return the internal type Values are
        // operators, and are type checked by
        // ExpressionTypeVisitor. (Future work: define each
        // polymorph of each operator as a separate function
        // that returns a concrete type, rather than the
        // current method of having a 'Value' wrapper type).
        continue
      }


      // Does the return type of this delegate map to a value
      // that Yarn Spinner can use?
      var yarnReturnType;
      var yarnReturnTypeRef = RefParam(yarnReturnType);
      if (BuiltinTypes.typeMappings.tryGetValue(method.ReturnType, yarnReturnTypeRef) == false) {
        yarnReturnType = yarnReturnTypeRef.value;
        diagnostics.add(Diagnostic("Function ${function.Key} cannot be used in Yarn Spinner scripts: ${method.ReturnType} is not a valid return type."));
        continue
      }


      // Define a new type for this function
      FunctionType functionType = FunctionType();

      var includeMethod = true;

      for (var paramInfo in method.getParameters()) {
        if (paramInfo.ParameterType == Value.runtimeType) {
          // Don't type-check this method - it's an operator
          includeMethod = false;
          break
        }


        if (paramInfo.IsOptional) {
          diagnostics.add(Diagnostic("Function ${function.Key} cannot be used in Yarn Spinner scripts: parameter ${paramInfo.Name} is optional, which isn't supported."));
          continue
        }


        if (paramInfo.IsOut) {
          diagnostics.add(Diagnostic("Function ${function.Key} cannot be used in Yarn Spinner scripts: parameter ${paramInfo.Name} is an out parameter, which isn't supported."));
          continue
        }


        var yarnParameterType;
        var yarnParameterTypeRef = RefParam(yarnParameterType);
        if (BuiltinTypes.typeMappings.tryGetValue(paramInfo.ParameterType, yarnParameterTypeRef) == false) {
          yarnParameterType = yarnParameterTypeRef.value;
          diagnostics.add(Diagnostic("Function ${function.Key} cannot be used in Yarn Spinner scripts: parameter ${paramInfo.Name}'s type (${paramInfo.ParameterType}) cannot be used in Yarn functions"));
          continue
        }


        functionType.addParameter(yarnParameterType);
      }

      if (includeMethod == false) {
        continue
      }


      functionType.IType = yarnReturnType;

      var declaration = Declaration;
      declaration.name = function.Key;
      declaration.type = functionType;
      declaration.sourceFileLine = -1;
      declaration.sourceNodeLine = -1;
      declaration.sourceFileName = Declaration.externalDeclaration;
      declaration.sourceNodeName = null;

      declarations.add(declaration);
    }

    return Tuple2.fromList([declarations, diagnostics]);
  }

  static FileParseResult _parseSyntaxTree(File file, RefParam<List<Diagnostic>> diagnostics) {
    String source = file.source;
    String fileName = file.fileName;

    var diagnosticsRef = RefParam(diagnostics.value);
    var result = parseSyntaxTree1(fileName, source, diagnosticsRef);
    diagnostics.value = diagnosticsRef.value;
    return result;
  }

  static FileParseResult parseSyntaxTree1(String fileName, String source, RefParam<List<Diagnostic>> diagnostics) {
    ICharStream input = CharStreams.fromstring(source);

    YarnSpinnerLexer lexer = YarnSpinnerLexer(input);
    CommonTokenStream tokens = CommonTokenStream(lexer);

    YarnSpinnerParser parser = YarnSpinnerParser(tokens);

    // turning off the normal error listener and using ours
    var parserErrorListener = ParserErrorListener();
    var lexerErrorListener = LexerErrorListener();

    parser.ErrorHandler = ErrorStrategy();

    parser.removeErrorListeners();
    parser.addErrorListener(parserErrorListener);

    lexer.removeErrorListeners();
    lexer.addErrorListener(lexerErrorListener);

    IParseTree tree;

    tree = parser.dialogue();

    var newDiagnostics = lexerErrorListener.diagnostics.concat(parserErrorListener.diagnostics);

    diagnostics.value.addRange(newDiagnostics);

    return FileParseResult(fileName, tree, tokens);
  }

  static List<String> getTokensFromFile(String path) {
    var text = File.readAllText(path);
    return getTokensFromString(text);
  }

  static List<String> getTokensFromString(String text) {
    ICharStream input = CharStreams.fromstring(text);

    YarnSpinnerLexer lexer = YarnSpinnerLexer(input);

    var tokenStringList = List<String>();

    var tokens = lexer.getAllTokens();
    for (var token in tokens) {
      tokenStringList.add("${token.Line}:${token.Column} ${YarnSpinnerLexer.defaultVocabulary.getDisplayName(token.Type)} \"${token.Text}\"");
    }

    return tokenStringList;
  }

  String registerLabel([String commentary = null]) {
    return "L" + _labelCount++ + commentary;
  }

  void _emit(Node node, OpCode code, List<Operand> operands) {
    var instruction = Instruction;
    result.OpCode = code;

    instruction.operands.add(operands);

    node.instructions.add(instruction);
  }

  void emit1(OpCode code, List<Operand> operands) {
    _emit(currentNode, code, operands);
  }

  static HashtagContext getLineIDTag(List<HashtagContext> hashtagContexts) {
    // if there are any hashtags
    if (hashtagContexts != null) {
      for (var hashtagContext in hashtagContexts) {
        String tagText = hashtagContext.text.Text;
        if (tagText.startsWith("line:", StringComparison.invariantCulture)) {
          return hashtagContext;
        }

      }
    }


    return null;
  }

  // this replaces the CompileNode from the old compiler will start
  // walking the parse tree emitting byte code as it goes along this
  // will all get stored into our program var needs a tree to walk,
  // this comes from the ANTLR Parser/Lexer steps
  void compile1() {
    ParseTreeWalker walker = ParseTreeWalker();
    walker.walk(this, fileParseResult.tree);
  }

  // we have found a new node set up the currentNode var ready to
  // hold it and otherwise continue
  void enterNode(NodeContext context) {
    currentNode = Node();
    rawTextNode = false;
  }

  // have left the current node store it into the program wipe the
  // var and make it ready to go again
  void exitNode(NodeContext context) {
    program.nodes[currentNode.name] = currentNode;
    currentNode = null;
    rawTextNode = false;
  }

  // have finished with the header so about to enter the node body
  // and all its statements do the initial setup required before
  // compiling that body statements eg emit a new startlabel
  void exitHeader(HeaderContext context) {
    var headerKey = context.header_key.Text;

    // Use the header value if provided, else fall back to the
    // empty string. This means that a header like "foo: \n" will
    // be stored as 'foo', '', consistent with how it was typed.
    // That is, it's not null, because a header was provided, but
    // it was written as an empty line.
    var headerValue = context.header_value?.Text ?? "";

    if (headerKey.equals("title", StringComparison.invariantCulture)) {
      // Set the name of the node
      currentNode.name = headerValue;

      // Throw an exception if this node name contains illegal
      // characters
      if (_invalidNodeTitleNameRegex.isMatch(currentNode.name)) {
        _diagnostics.add(Diagnostic(fileParseResult.name, context, "The node '${currentNode.name}' contains illegal characters in its title."));
      }

    }


    if (headerKey.equals("tags", StringComparison.invariantCulture)) {
      // Split the list of tags by spaces, and use that
      var tags = headerValue.split([' '], StringSplitOptions.removeEmptyEntries);

      currentNode.tags.add(tags);

      if (currentNode.tags.contains("rawText")) {
        // This is a raw text node. Flag it as such for future
        // compilation.
        rawTextNode = true;
      }

    }

  }

  // have entered the body the header should have finished being
  // parsed and currentNode ready all we do is set up a body visitor
  // and tell it to run through all the statements it handles
  // everything from that point onwards
  void enterBody(BodyContext context) {
    // if it is a regular node
    if (!rawTextNode) {
      // This is the start of a node that we can jump to. Add a
      // label at this point.
      currentNode.labels.add(registerLabel(), currentNode.instructions.Count);

      CodeGenerationVisitor visitor = CodeGenerationVisitor(this);

      for (var statement in context.statement()) {
        visitor.visit(statement);
      }
    }
    else {
      currentNode.sourceTextStringID = Compiler.getLineIDForNodeName(currentNode.name);
    }
  }

  static String getLineIDForNodeName(String name) {
    return "line:" + name;
  }

  void exitBody(BodyContext context) {
    // We have exited the body; emit a 'stop' opcode here.
    _emit(currentNode, OpCode.stop);
  }

  static Iterable<IParseTree> flattenParseTree(IParseTree node) {
    // Get the list of children in this node
    var children = (0 upto node.ChildCount).select((i) => node.getChild(i));

    // Recursively visit each child and append it to a sequence,
    // and then return that sequence
    return children.selectMany((c) => flattenParseTree(c)).concat([node]);
  }

  static String getDocumentComments(CommonTokenStream tokens, ParserRuleContext context, [bool allowCommentsAfter = true]) {
    String description = null;

    var precedingComments = tokens.getHiddenTokensToLeft(context.Start.TokenIndex, YarnSpinnerLexer.cOMMENTS);

    if (precedingComments != null) {
      var precedingDocComments = precedingComments.where((t) => tokens.getTokens().where((ot) => ot.Line == t.Line).where((ot) => ot.Type != YarnSpinnerLexer.iNDENT && ot.Type != YarnSpinnerLexer.dEDENT).where((ot) => ot.Channel == YarnSpinnerLexer.DefaultTokenChannel).count() == 0).where((t) => t.Text.startsWith("///")).select((t) => t.Text.replace("///", .empty).trim());

      if (precedingDocComments.count() > 0) {
        description = String.join(" ", precedingDocComments);
      }

    }


    if (allowCommentsAfter) {
      var subsequentComments = tokens.getHiddenTokensToRight(context.Stop.TokenIndex, YarnSpinnerLexer.cOMMENTS);
      if (subsequentComments != null) {
        var subsequentDocComment = subsequentComments.where((t) => t.Line == context.Stop.Line).where((t) => t.Text.startsWith("///")).select((t) => t.Text.replace("///", .empty).trim()).firstOrDefault();

        if (subsequentDocComment != null) {
          description = subsequentDocComment;
        }

      }

    }


    return description;
  }
}

class FileParseResult {
  String name = null;
  IParseTree tree;
  CommonTokenStream tokens;

  FileParseResult(String name, IParseTree tree, CommonTokenStream tokens) {
    this.name = name;
    this.tree = tree;
    this.tokens = tokens;
  }

  bool equals(Object obj) {
    FileParseResult other = obj as FileParseResult;
    return obj is FileParseResult && name == other.name && EqualityComparer<IParseTree>.default.equals(tree, other.tree) && EqualityComparer<CommonTokenStream>.default.equals(tokens, other.tokens);
  }

  @override
  int get hashCode {
    int hashCode = -1713343069;
    hashCode = hashCode * -1521134295 + EqualityComparer<String>.default.getHashCode(name);
    hashCode = hashCode * -1521134295 + EqualityComparer<IParseTree>.default.getHashCode(tree);
    hashCode = hashCode * -1521134295 + EqualityComparer<CommonTokenStream>.default.getHashCode(tokens);
    return hashCode;
  }
}
