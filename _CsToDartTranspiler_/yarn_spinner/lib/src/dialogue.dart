/*

The MIT License (MIT)

Copyright (c) 2015-2017 Secret Lab Pty. Ltd. and Yarn Spinner contributors.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

import 'package:yarn_spinner.framework/src/analyser.dart';
import 'package:yarn_spinner.framework/src/library.dart';
import 'package:yarn_spinner.framework/src/number_plurals.dart';
import 'package:yarn_spinner.framework/src/program.dart';
import 'package:yarn_spinner.framework/src/types/builtin_types.dart';
import 'package:yarn_spinner.framework/src/virtual_machine.dart';
import 'package:yarn_spinner.framework/src/yarn_spinner.dart';
import 'package:yarn_spinner.framework/src/yarn_spinner.markup/i_attribute_marker_processor.dart';
import 'package:yarn_spinner.framework/src/yarn_spinner.markup/line_parser.dart';
import 'package:yarn_spinner.framework/src/yarn_spinner.markup/markup_parse_result.dart';


class Line {
  Line(String stringID) {
    iD = stringID;
    substitutions = List<String>();
  }

  String ID;

  List<String> Substitutions = [];
}

class OptionSet {
  OptionSet(List<Option> options) {
    options = options;
  }

  class Option {
    Option(Line line, int id, String destinationNode, bool isAvailable) {
      line = line;
      iD = id;
      destinationNode = destinationNode;
      isAvailable = isAvailable;
    }

    Line line = new Line();

    int iD = 0;

    String destinationNode = null;

    bool isAvailable = false;
  }

  List<Option> options = [];
}

class Command {
  Command(String text) {
    text = text;
  }

  String text = null;
}

typedef void Logger(String message);

/// Provides a mechanism for storing and retrieving instances
abstract class IVariableStorage {
  void setValue(String variableName, String stringValue);

  void setValue1(String variableName, double floatValue);

  void setValue2(String variableName, bool boolValue);

  bool tryGetValue<T>(String variableName, RefParam<T> result);

  void clear();
}

class MemoryVariableStore implements IVariableStorage {
  Map<String, Object> _variables = Map<String, Object>();

  /// <inheritdoc
  @override
  bool tryGetValue<T>(String variableName, RefParam<T> result) {
    var foundValue;
    var foundValueRef = RefParam(foundValue);
    if (_variables.tryGetValue(variableName, foundValueRef)) {
      foundValue = foundValueRef.value;
      if (T.runtimeType.isAssignableFrom(foundValue.runtimeType)) {
        result.value = foundValue as T;
        return true;
      }
      else {
        throw ArgumentError("Variable ${variableName} is present, but is of type ${foundValue.runtimeType}, not ${T.runtimeType}");
      }
    }


    result.value = default;
    return false;
  }

  /// <inheritdoc
  @override
  void clear() {
    _variables.clear();
  }

  @override
  void setValue(String variableName, String stringValue) {
    _variables[variableName] = stringValue;
  }

  @override
  void setValue3(String variableName, double floatValue) {
    _variables[variableName] = floatValue;
  }

  @override
  void setValue4(String variableName, bool boolValue) {
    _variables[variableName] = boolValue;
  }
}

typedef void LineHandler(Line line);

typedef void OptionsHandler(OptionSet options);

typedef void CommandHandler(Command command);

typedef void NodeCompleteHandler(String completedNodeName);

typedef void NodeStartHandler(String startedNodeName);

typedef void DialogueCompleteHandler();

typedef void PrepareForLinesHandler(Iterable<String> lineIDs);

class Dialogue implements IAttributeMarkerProcessor {

  IVariableStorage variableStorage;

  Logger logDebugMessage;

  Logger logErrorMessage;

  /// The node that execution will start from.
  final String DefaultStartNodeName = "Start";

  Program _program;

  /// Gets or sets the compiled Yarn program.
  Program get program => _program;

  set program(Program value) {
    _program = value;

    _vm.program = value;
    _vm.resetState();
  }


  bool get isActive => _vm.currentExecutionState != VirtualMachine.ExecutionState.stopped;

  LineHandler get lineHandler => _vm.lineHandler;

  set lineHandler(LineHandler value) => _vm.lineHandler = value;


  String languageCode = null;

  OptionsHandler get optionsHandler => _vm.optionsHandler;

  set optionsHandler(OptionsHandler value) => _vm.optionsHandler = value;


  CommandHandler get commandHandler => _vm.commandHandler;

  set commandHandler(CommandHandler value) => _vm.commandHandler = value;


  NodeStartHandler get nodeStartHandler => _vm.nodeStartHandler;

  set nodeStartHandler(NodeStartHandler value) => _vm.nodeStartHandler = value;


  NodeCompleteHandler get nodeCompleteHandler => _vm.nodeCompleteHandler;

  set nodeCompleteHandler(NodeCompleteHandler value) => _vm.nodeCompleteHandler = value;


  DialogueCompleteHandler get dialogueCompleteHandler => _vm.dialogueCompleteHandler;

  set dialogueCompleteHandler(DialogueCompleteHandler value) => _vm.dialogueCompleteHandler = value;


  PrepareForLinesHandler get prepareForLinesHandler => _vm.prepareForLinesHandler;

  set prepareForLinesHandler(PrepareForLinesHandler value) => _vm.prepareForLinesHandler = value;


  VirtualMachine _vm;

  Library library;

  Dialogue(IVariableStorage variableStorage) {
    this.variableStorage = variableStorage ?? throw ArgumentNullException(nameof(variableStorage));
    library = Library();

    _vm = VirtualMachine(this);

    library.importLibrary(StandardLibrary());

    _lineParser = LineParser();

    _lineParser.registerMarkerProcessor("select", this);
    _lineParser.registerMarkerProcessor("plural", this);
    _lineParser.registerMarkerProcessor("ordinal", this);
  }

  void setProgram(Program program) {
    this.program = program;
  }

  void addProgram(Program program) {
    if (this.program == null) {
      setProgram(program);
      return;
    }
    else {
      this.program = Program.combine(this.program, program);
    }
  }

  void loadProgram(String fileName) {
    var bytes = File.readAllBytes(fileName);

    program = Program.parser.parseFrom(bytes);
  }

  void setNode([String startNode = defaultStartNodeName]) {
    _vm.setNode(startNode);
  }

  void setSelectedOption(int selectedOptionID) {
    _vm.setSelectedOption(selectedOptionID);
  }

  void continue() {
    if (_vm.currentExecutionState == VirtualMachine.ExecutionState.running) {
      // Cannot 'continue' an already running VM.
      return;
    }


    _vm.continue();
  }

  void stop() {
    if (_vm != null) {
      _vm.stop();
    }

  }

  Iterable<String> get nodeNames {
    return program.nodes.Keys;
  }


  String get currentNode {
    if (_vm == null) {
      return null;
    }
    else {
      return _vm.currentNodeName;
    }
  }


  String getStringIDForNode(String nodeName) {
    if (program.nodes.Count == 0) {
      logErrorMessage?.emit("No nodes are loaded!");
      return null;
    }
    else if (program.nodes.containsKey(nodeName)) {
      return "line:" + nodeName;
    }
    else {
      logErrorMessage?.emit("No node named " + nodeName);
      return null;
    }
  }

  Iterable<String> getTagsForNode(String nodeName) {
    if (program.nodes.Count == 0) {
      logErrorMessage?.emit("No nodes are loaded!");
      return null;
    }
    else if (program.nodes.containsKey(nodeName)) {
      return program.getTagsForNode(nodeName);
    }
    else {
      logErrorMessage?.emit("No node named " + nodeName);
      return null;
    }
  }

  void unloadAll() {
    program = null;
  }

  String getByteCode() {
    return program.dumpCode(library);
  }

  bool nodeExists(String nodeName) {
    if (program == null) {
      logErrorMessage?.emit("Tried to call NodeExists, but no program has been loaded!");
      return false;
    }


    if (program.nodes == null || program.nodes.Count == 0) {
      // No nodes? Then this node doesn't exist.
      return false;
    }


    return program.nodes.containsKey(nodeName);
  }

  void analyse(Context context) {
    context.addProgramToAnalysis(program);
  }

  LineParser _lineParser;

  MarkupParseResult parseMarkup(String line) {
    return _lineParser.parseMarkup(line);
  }

  static String expandSubstitutions(String text, IList<String> substitutions) {
    for (int i = 0; i < substitutions.count; i++) {
      String substitution = substitutions[i];
      text = text.replace("{" + i + "}", substitution);
    }

    return text;
  }

  static final Regex _ValuePlaceholderRegex = Regex("(?<!\\)%");

  /// Returns the text that should be used to replace the
  @override
  String _yarn.Markup.IAttributeMarkerProcessor.ReplacementTextForMarker(MarkupAttributeMarker marker) {

    var valueProp = new MarkupValue();
    var valuePropRef = RefParam(valueProp);
    if (marker.tryGetProperty("value", valuePropRef) == false) {
      valueProp = valuePropRef.value;
      throw KeyNotFoundException("Expected a property \"value\"");
    }


    var value = valueProp.toString();

    // Apply the "select" marker
    if (marker.name == "select") {
      var replacementProp = new MarkupValue();
      var replacementPropRef = RefParam(replacementProp);
      if (!marker.tryGetProperty(value, replacementPropRef)) {
        replacementProp = replacementPropRef.value;
        throw KeyNotFoundException("error: no replacement for ${value}");
      }


      String replacement = replacementProp.toString();
      replacement = _valuePlaceholderRegex.replace(replacement, value);
      return replacement;
    }


    // If it's not "select", then it's "plural" or "ordinal"

    // First, ensure that we have a locale code set
    if (languageCode == null) {
      throw InvalidOperationException("Dialogue locale code is not set. 'plural' and 'ordinal' markers cannot be called unless one is set.");
    }


    // Attempt to parse the value as a double, so we can determine
    // its plural class
    var doubleValue = 0.0;
    var doubleValueRef = RefParam(doubleValue);
    if (double.tryParse(value, doubleValueRef) == false) {
      doubleValue = doubleValueRef.value;
      throw ArgumentError("Error while pluralising line: '${value}' is not a number");
    }


    PluralCase pluralCase = PluralCase.Few;

    switch (marker.Name) {
      case "plural": {
        pluralCase = CLDRPlurals.NumberPlurals.getCardinalPluralCase(languageCode, doubleValue);
      }
      case "ordinal": {
        pluralCase = CLDRPlurals.NumberPlurals.getOrdinalPluralCase(languageCode, doubleValue);
      }
      default: {
        throw InvalidOperationException("Invalid marker name ${marker.name}");
      }
    }

    String pluralCaseName = pluralCase.toString().toLowerInvariant();

    // Now that we know the plural case, we can select the
    // appropriate replacement text for it
    var replacementValue = new MarkupValue();
    var replacementValueRef = RefParam(replacementValue);
    if (!marker.tryGetProperty(pluralCaseName, replacementValueRef)) {
      replacementValue = replacementValueRef.value;
      throw KeyNotFoundException("error: no replacement for ${value}'s plural case of ${pluralCaseName}");
    }


    String input = replacementValue.toString();
    return _valuePlaceholderRegex.replace(input, value);
  }

  // The standard, built-in library of functions and operators.
}
class StandardLibrary extends Library {
  StandardLibrary() {

    // Register the in-built conversion functions
    registerFunction1<Object, String>("string", (Object v) {
      return Convert.toString(v);
     });

    registerFunction1<Object, double>("number", (Object v) {
      return Convert.toSingle(v);
     });

    registerFunction1<Object, bool>("bool", (Object v) {
      return Convert.toBoolean(v);
     });

    // Register the built-in types.
    registerMethods(BuiltinTypes.number);
    registerMethods(BuiltinTypes.String);
    registerMethods(BuiltinTypes.bool);
  }
}
