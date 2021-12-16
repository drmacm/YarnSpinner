import 'package:yarn_spinner.compiler.framework/src/compiler.dart';
import 'package:yarn_spinner.compiler.framework/src/constant_value_visitor.dart';
import 'package:yarn_spinner.compiler.framework/src/declaration.dart';
import 'package:yarn_spinner.compiler.framework/src/error_listener.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser.dart';
import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser_base_visitor.dart';
import 'package:yarn_spinner.framework/yarn_spinner.framework.dart';

class DeclarationVisitor extends YarnSpinnerParserBaseVisitor<IType> {

  CommonTokenStream _tokens;

  // The collection of variable declarations we know about before
  // starting our work
  Iterable<Declaration> _ExistingDeclarations;

  // The name of the node that we're currently visiting.
  String _currentNodeName = null;

  NodeContext _currentNodeContext;

  String _sourceFileName;

  Iterable<IType> types;

  ICollection<Declaration> newDeclarations;

  ICollection<String> fileTags;

  Iterable<Declaration> get declarations => _existingDeclarations.concat(newDeclarations);

  Iterable<Diagnostic> get diagnostics => _diagnostics;

  List<Diagnostic> _diagnostics = List<Diagnostic>();

  static final Map<String, IType> _KeywordsToBuiltinTypes = {"string": BuiltinTypes.String, "number": BuiltinTypes.number, "bool": BuiltinTypes.bool};

  DeclarationVisitor(String sourceFileName, Iterable<Declaration> existingDeclarations, Iterable<IType> typeDeclarations, CommonTokenStream tokens) {
    _existingDeclarations = existingDeclarations;
    newDeclarations = List<Declaration>();
    fileTags = List<String>();
    _sourceFileName = sourceFileName;
    types = typeDeclarations;
    _tokens = tokens;
  }

  IType visitFile_hashtag(File_hashtagContext context) {
    fileTags.add(context.text.Text);
    return null;
  }

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

  IType visitDeclare_statement(Declare_statementContext context) {
    String description = Compiler.getDocumentComments(_tokens, context);

    // Get the name of the variable we're declaring
    String variableName = context.variable().getText();

    // Does this variable name already exist in our declarations?
    var existingExplicitDeclaration = declarations.where((d) => d.IsImplicit == false).firstOrDefault((d) => d.Name == variableName);
    if (existingExplicitDeclaration != null) {
      // Then this is an error, because you can't have two explicit declarations for the same variable.
      String v = "${existingExplicitDeclaration.Name} has already been declared in ${existingExplicitDeclaration.SourceFileName}, line ${existingExplicitDeclaration.SourceFileLine}";
      _diagnostics.add(Diagnostic(_sourceFileName, context, v));
      return BuiltinTypes.IType;
    }


    // Figure out the value and its type
    var constantValueVisitor = ConstantValueVisitor(context, _sourceFileName, types, _diagnostics);
    var value = constantValueVisitor.visit(context.value());

    // Did the source code name an explicit type?
    if (context.type != null) {
      IType explicitType;

      var explicitTypeRef = RefParam(explicitType);
      if (_keywordsToBuiltinTypes.tryGetValue(context.type.Text, explicitTypeRef) == false) {
        // The type name provided didn't map to a built-in
        // type. Look for the type in our Types collection.
        explicitType = explicitTypeRef.value;
        explicitType = types.firstOrDefault((t) => t.Name == context.type.Text);

        if (explicitType == null) {
          // We didn't find a type by this name.
          String v = "Unknown type ${context.type.Text}";
          _diagnostics.add(Diagnostic(_sourceFileName, context, v));
          return BuiltinTypes.IType;
        }

      }


      // Check that the type we've found is compatible with the
      // type of the value that was provided - if it doesn't,
      // that's a type error
      if (TypeUtil.isSubType(explicitType, value.Type) == false) {
        String v = "Type ${context.type.Text} does not match value ${context.value().getText()} (${value.Type.Name})";
        _diagnostics.add(Diagnostic(_sourceFileName, context, v));
        return BuiltinTypes.IType;
      }

    }


    // We're done creating the declaration!
    int positionInFile = context.Start.Line;

    // The start line of the body is the line after the delimiter
    int nodePositionInFile = _currentNodeContext.bODY_START().Symbol.Line + 1;

    var declaration = Declaration;
    declaration.name = variableName;
    declaration.type = value.Type;
    declaration.defaultValue = value.InternalValue;
    declaration.description = description;
    declaration.sourceFileName = _sourceFileName;
    declaration.sourceFileLine = positionInFile;
    declaration.sourceNodeName = _currentNodeName;
    declaration.sourceNodeLine = positionInFile - nodePositionInFile;
    declaration.isImplicit = false;

    newDeclarations.add(declaration);

    return value.Type;
  }
}
