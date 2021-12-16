import 'package:yarn_spinner.framework/src/program.dart';
import 'package:yarn_spinner.framework/src/yarn_spinner.dart';


class Diagnosis {

  String message;
  String nodeName;
  int lineNumber = 0;
  int columnNumber = 0;

  Severity severity = Severity.Error;

  Diagnosis(String message, Severity severity, [String nodeName = null, int lineNumber = -1, int columnNumber = -1]) {
    this.message = message;
    this.nodeName = nodeName;
    this.lineNumber = lineNumber;
    this.columnNumber = columnNumber;
    this.severity = severity;
  }

  String toString() {
    return toString1(showSeverity: false);
  }

  String toString1({bool showSeverity}) {

    String contextLabel = "";

    if (showSeverity) {
      switch (severity) {
        case Severity.error: {
          contextLabel = "ERROR: ";
        }
        case Severity.warning: {
          contextLabel = "WARNING: ";
        }
        case Severity.note: {
          contextLabel = "Note: ";
        }
        default: {
          throw ArgumentOutOfRangeException();
        }
      }
    }


    if (nodeName != null) {

      contextLabel += nodeName;
      if (lineNumber != -1) {
        contextLabel.addListener(this, String.format(CultureInfo.currentCulture, ": {0}", lineNumber));

        if (columnNumber != -1) {
          contextLabel.addListener(this, String.format(CultureInfo.currentCulture, ":{0}", columnNumber));
        }

      }

    }


    String message;

    if (String.isNullOrEmpty(contextLabel)) {
      message = this.message;
    }
    else {
      message = String.format(CultureInfo.currentCulture, "{0}: {1}", contextLabel, this.message);
    }

    return message;
  }
}

class Severity {
  final int value;
  final String name;
  const Severity._(this.value, this.name);

  static const error = const Severity._(0, 'error');
  static const warning = const Severity._(1, 'warning');
  static const note = const Severity._(2, 'note');

  static const List<Severity> values = [
    error,
    warning,
    note,
  ];

  @override
  String toString() => 'Severity' + '.' + name;

}

class Context {

  Iterable<Type> _defaultAnalyserClasses;
  Iterable<Type> get defaultAnalyserClasses {
    var classes = List<Type>();

    if (_defaultAnalyserClasses == null) {
      classes = List<Type>();

      var assembly = this.runtimeType.assembly;

      for (var type in assembly.getTypes()) {
        if (type.isSubclassOf(CompiledProgramAnalyser.runtimeType) && type.isAbstract == false) {

          classes.add(type);
        }

      }
      _defaultAnalyserClasses = classes;
    }


    return _defaultAnalyserClasses;
  }


  List<CompiledProgramAnalyser> _analysers;

  Context() {
    _analysers = List<CompiledProgramAnalyser>();

    for (var analyserType in defaultAnalyserClasses) {
      _analysers.add(Activator.createInstance(analyserType) as CompiledProgramAnalyser);
    }
  }

  Context(List<Type> types) {
    _analysers = List<CompiledProgramAnalyser>();

    for (var analyserType in types) {
      _analysers.add(Activator.createInstance(analyserType) as CompiledProgramAnalyser);
    }
  }

  void addProgramToAnalysis(Program program) {
    for (var analyser in _analysers) {
      analyser.diagnose(program);
    }
  }

  Iterable<Diagnosis> finishAnalysis() {
    List<Diagnosis> diagnoses = List<Diagnosis>();

    for (var analyser in _analysers) {
      diagnoses.addRange(analyser.gatherDiagnoses());
    }

    return diagnoses;
  }
}

abstract class CompiledProgramAnalyser {
  void diagnose(Program program);
  Iterable<Diagnosis> gatherDiagnoses();
}

class VariableLister implements CompiledProgramAnalyser {
  HashSet<String> _variables = HashSet<String>();

  void diagnose(Program program) {
    // In each node, find all reads and writes to variables
    for (var nodeInfo in program.nodes) {

      var nodeName = nodeInfo.Key;
      var theNode = nodeInfo.Value;

      for (var instruction in theNode.Instructions) {

        switch (instruction.Opcode) {
          case OpCode.pushVariable, OpCode.storeVariable: {
            _variables.add(instruction.Operands[0].StringValue);
          }
        }
      }
    }
  }

  Iterable<Diagnosis> gatherDiagnoses() {
    var diagnoses = List<Diagnosis>();

    for (var variable in _variables) {
      var d = Diagnosis("Script uses variable " + variable, Diagnosis.Severity.note);
      diagnoses.add(d);
    }

    return diagnoses;
  }
}

class UnusedVariableChecker implements CompiledProgramAnalyser {

  HashSet<String> _readVariables = HashSet<String>();
  HashSet<String> _writtenVariables = HashSet<String>();

  void diagnose(Program program) {

    // In each node, find all reads and writes to variables
    for (var nodeInfo in program.nodes) {

      var nodeName = nodeInfo.Key;
      var theNode = nodeInfo.Value;

      for (var instruction in theNode.Instructions) {

        switch (instruction.Opcode) {
          case OpCode.pushVariable: {
            _readVariables.add(instruction.Operands[0].StringValue);
          }
          case OpCode.storeVariable: {
            _writtenVariables.add(instruction.Operands[0].StringValue);
          }
        }
      }
    }
  }

  Iterable<Diagnosis> gatherDiagnoses() {

    // Exclude read variables that are also written
    var readOnlyVariables = HashSet<String>(_readVariables);
    readOnlyVariables.exceptWith(_writtenVariables);

    // Exclude written variables that are also read
    var writeOnlyVariables = HashSet<String>(_writtenVariables);
    writeOnlyVariables.exceptWith(_readVariables);

    // Generate diagnoses
    var diagnoses = List<Diagnosis>();

    for (var writeOnlyVariable in writeOnlyVariables) {
      var message = String.format(CultureInfo.currentCulture, "Variable {0} is assigned, but never read from", writeOnlyVariable);
      diagnoses.add(Diagnosis(message, Diagnosis.Severity.warning));
    }

    return diagnoses;
  }
}
