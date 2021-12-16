import 'package:yarn_spinner.compiler.framework/src/yarn_spinner_parser_base_listener.dart';

class TypeDeclarationListener extends YarnSpinnerParserBaseListener {
  String _sourceFileName;
  CommonTokenStream _tokens;
  IParseTree _tree;
  List<IType> _typeDeclarations;

  TypeDeclarationListener(String sourceFileName, CommonTokenStream tokens, IParseTree tree, RefParam<List<IType>> typeDeclarations) {
    _sourceFileName = sourceFileName;
    _tokens = tokens;
    _tree = tree;
    _typeDeclarations = typeDeclarations.value;
  }

  Iterable<Diagnostic> get diagnostics => _diagnostics;


  List<Diagnostic> _diagnostics = List<Diagnostic>();
}
