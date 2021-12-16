import 'package:yarn_spinner.framework/src/dialogue.dart';
import 'package:yarn_spinner.framework/src/dialogue_exception.dart';
import 'package:yarn_spinner.framework/src/program.dart';
import 'package:yarn_spinner.framework/src/types/builtin_types.dart';
import 'package:yarn_spinner.framework/src/types/i_type.dart';
import 'package:yarn_spinner.framework/src/value.dart';
import 'package:yarn_spinner.framework/src/yarn_spinner.dart';
class Operand {
  // Define some convenience constructors for the Operand type, so
  // that we don't need to have two separate steps for creating and
  // then preparing the Operand
  Operand(bool value) {
    boolValue = value;
  }

  Operand(String value) {
    stringValue = value;
  }

  Operand(double value) {
    floatValue = value;
  }
}


class Operator {
  final int value;
  final String name;
  const Operator._(this.value, this.name);

  /// A unary operator that returns its input.
  static const none = const Operator._(0, 'none');
  /// A binary operator that represents equality.
  static const equalTo = const Operator._(1, 'equalTo');
  /// A binary operator that represents a value being
  static const greaterThan = const Operator._(2, 'greaterThan');
  /// A binary operator that represents a value being
  static const greaterThanOrEqualTo = const Operator._(3, 'greaterThanOrEqualTo');
  /// A binary operator that represents a value being less
  static const lessThan = const Operator._(4, 'lessThan');
  /// A binary operator that represents a value being less
  static const lessThanOrEqualTo = const Operator._(5, 'lessThanOrEqualTo');
  /// A binary operator that represents
  static const notEqualTo = const Operator._(6, 'notEqualTo');
  /// A binary operator that represents a logical
  static const or = const Operator._(7, 'or');
  /// A binary operator that represents a logical
  static const and = const Operator._(8, 'and');
  /// A binary operator that represents a logical exclusive
  static const xor = const Operator._(9, 'xor');
  /// A binary operator that represents a logical
  static const not = const Operator._(10, 'not');
  /// A unary operator that represents negation.
  static const unaryMinus = const Operator._(11, 'unaryMinus');
  /// A binary operator that represents addition.
  static const add = const Operator._(12, 'add');
  /// A binary operator that represents
  static const minus = const Operator._(13, 'minus');
  /// A binary operator that represents
  static const multiply = const Operator._(14, 'multiply');
  /// A binary operator that represents division.
  static const divide = const Operator._(15, 'divide');
  /// A binary operator that represents the remainder
  static const modulo = const Operator._(16, 'modulo');

  static const List<Operator> values = [
    none,
    equalTo,
    greaterThan,
    greaterThanOrEqualTo,
    lessThan,
    lessThanOrEqualTo,
    notEqualTo,
    or,
    and,
    xor,
    not,
    unaryMinus,
    add,
    minus,
    multiply,
    divide,
    modulo,
  ];

  @override
  String toString() => 'Operator' + '.' + name;

}

class VirtualMachine {


  VirtualMachine(Dialogue d) {
    _dialogue = d;
    _state = State();
  }

  /// Reset the state of the VM
  void resetState() {
    _state = State();
  }

  LineHandler LineHandler;
  OptionsHandler OptionsHandler;
  CommandHandler CommandHandler;
  NodeStartHandler NodeStartHandler;
  NodeCompleteHandler NodeCompleteHandler;
  DialogueCompleteHandler DialogueCompleteHandler;
  PrepareForLinesHandler PrepareForLinesHandler;

  Dialogue _dialogue;

  Program program;

  State _state = State();

  String get currentNodeName {
    return _state.currentNodeName;
  }



  ExecutionState _executionState = ExecutionState.WaitingForContinue;
  ExecutionState get currentExecutionState {
    return _executionState;
  }

  set currentExecutionState(ExecutionState value) {
    _executionState = value;
    if (_executionState == ExecutionState.stopped) {
      resetState();
    }

  }


  Node _currentNode;

  bool setNode(String nodeName) {

    if (program == null || program.nodes.Count == 0) {
      throw DialogueException("Cannot load node ${nodeName}: No nodes have been loaded.");
    }


    if (program.nodes.containsKey(nodeName) == false) {
      currentExecutionState = ExecutionState.stopped;
      throw DialogueException("No node named ${nodeName} has been loaded.");
    }


    _dialogue.logDebugMessage?.emit("Running node " + nodeName);

    _currentNode = program.nodes[nodeName];
    resetState();
    _state.currentNodeName = nodeName;

    nodeStartHandler?.emit(nodeName);

    // Do we have a way to let the client know that certain lines
    // might be run?
    if (prepareForLinesHandler != null) {
      // If we have a prepare-for-lines handler, figure out what
      // lines we anticipate running

      // Create a list; we will never have more lines and options
      // than total instructions, so that's a decent capacity for
      // the list (TODO: maybe this list could be reused to save
      // on allocations?)
      var stringIDs = List<String>(_currentNode.instructions.Count);

      // Loop over every instruction and find the ones that run a
      // line or add an option; these are the two instructions
      // that will signal a line can appear to the player
      for (var instruction in _currentNode.instructions) {
        if (instruction.Opcode == OpCode.runLine || instruction.Opcode == OpCode.addOption) {
          // Both RunLine and AddOption have the string ID
          // they want to show as their first operand, so
          // store that
          stringIDs.add(instruction.Operands[0].StringValue);
        }

      }

      // Deliver the string IDs
      prepareForLinesHandler(stringIDs);
    }


    return true;
  }

  void stop() {
    currentExecutionState = ExecutionState.stopped;
  }

  void setSelectedOption(int selectedOptionID) {

    if (currentExecutionState != ExecutionState.waitingOnOptionSelection) {

      throw DialogueException("SetSelectedOption was called, but Dialogue wasn't waiting for a selection.
                This method should only be called after the Dialogue is waiting for the user to select an option.");
    }


    if (selectedOptionID < 0 || selectedOptionID >= _state.currentOptions.count) {
      throw ArgumentOutOfRangeException("${selectedOptionID} is not a valid option ID (expected a number between 0 and ${_state.currentOptions.count - 1}.");
    }


    // We now know what number option was selected; push the
    // corresponding node name to the stack
    var destinationNode = _state.currentOptions[selectedOptionID].destination;
    _state.pushValue1(destinationNode);

    // We no longer need the accumulated list of options; clear it
    // so that it's ready for the next one
    _state.currentOptions.clear();

    // We're no longer in the WaitingForOptions state; we are now waiting for our game to let us continue
    currentExecutionState = ExecutionState.waitingForContinue;
  }

  /// Resumes execution.
  void continue() {
    _checkCanContinue();

    if (currentExecutionState == ExecutionState.deliveringContent) {
      // We were delivering a line, option set, or command, and
      // the client has called Continue() on us. We're still
      // inside the stack frame of the client callback, so to
      // avoid recursion, we'll note that our state has changed
      // back to Running; when we've left the callback, we'll
      // continue executing instructions.
      currentExecutionState = ExecutionState.running;
      return;
    }


    currentExecutionState = ExecutionState.running;

    // Execute instructions until something forces us to stop
    while (currentExecutionState == ExecutionState.running) {
      Instruction currentInstruction = _currentNode.instructions[_state.programCounter];

      runInstruction(currentInstruction);

      _state.programCounter++;

      if (_state.programCounter >= _currentNode.instructions.Count) {
        nodeCompleteHandler(_currentNode.name);
        currentExecutionState = ExecutionState.stopped;
        dialogueCompleteHandler();
        _dialogue.logDebugMessage("Run complete.");
      }

    }
  }

  void _checkCanContinue() {
    if (_currentNode == null) {
      throw DialogueException("Cannot continue running dialogue. No node has been selected.");
    }


    if (currentExecutionState == ExecutionState.waitingOnOptionSelection) {
      throw DialogueException("Cannot continue running dialogue. Still waiting on option selection.");
    }


    if (lineHandler == null) {
      throw DialogueException("Cannot continue running dialogue. ${nameof(lineHandler)} has not been set.");
    }


    if (optionsHandler == null) {
      throw DialogueException("Cannot continue running dialogue. ${nameof(optionsHandler)} has not been set.");
    }


    if (commandHandler == null) {
      throw DialogueException("Cannot continue running dialogue. ${nameof(commandHandler)} has not been set.");
    }


    if (nodeCompleteHandler == null) {
      throw DialogueException("Cannot continue running dialogue. ${nameof(nodeCompleteHandler)} has not been set.");
    }

  }

  /// Looks up the instruction number for a named label in the current node.
  int findInstructionPointForLabel(String labelName) {

    if (_currentNode.labels.containsKey(labelName) == false) {
      // Couldn't find the node..
      throw IndexOutOfRangeException("Unknown label ${labelName} in node ${_state.currentNodeName}");
    }


    return _currentNode.labels[labelName];
  }

  void runInstruction(Instruction i) {
    switch (i.Opcode) {
      case OpCode.jumpTo: {
        /// - JumpTo
        /** Jumps to a named label
                         */
        _state.programCounter = findInstructionPointForLabel(i.operands[0].StringValue) - 1;

      }

      case OpCode.runLine: {
        /// - RunLine
        /** Looks up a string from the string table and
                         *  passes it to the client as a line
                         */
        String stringKey = i.operands[0].StringValue;

        Line line = Line(stringKey);

        // The second operand, if provided (compilers prior
        // to v1.1 don't include it), indicates the number
        // of expressions in the line. We need to pop these
        // values off the stack and deliver them to the
        // line handler.
        if (i.operands.Count > 1) {
          // TODO: we only have float operands, which is
          // unpleasant. we should make 'int' operands a
          // valid type, but doing that implies that the
          // language differentiates between floats and
          // ints itself. something to think about.
          var expressionCount = i.operands[1].FloatValue as int;

          var strings = List<String>();

          for (int expressionIndex = expressionCount - 1; expressionIndex >= 0; expressionIndex--) {
            strings[expressionIndex] = _state.popValue().convertTo<String>();
          }

          line.substitutions = strings;
        }


        // Suspend execution, because we're about to deliver content
        currentExecutionState = ExecutionState.deliveringContent;

        lineHandler(line);

        if (currentExecutionState == ExecutionState.deliveringContent) {
          // The client didn't call Continue, so we'll
          // wait here.
          currentExecutionState = ExecutionState.waitingForContinue;
        }


      }

      case OpCode.runCommand: {
        /// - RunCommand
        /** Passes a string to the client as a custom command
                         */

        String commandText = i.operands[0].StringValue;

        // The second operand, if provided (compilers prior
        // to v1.1 don't include it), indicates the number
        // of expressions in the command. We need to pop
        // these values off the stack and deliver them to
        // the line handler.
        if (i.operands.Count > 1) {
          // TODO: we only have float operands, which is
          // unpleasant. we should make 'int' operands a
          // valid type, but doing that implies that the
          // language differentiates between floats and
          // ints itself. something to think about.
          var expressionCount = i.operands[1].FloatValue as int;

          var strings = List<String>();

          // Get the values from the stack, and
          // substitute them into the command text
          for (int expressionIndex = expressionCount - 1; expressionIndex >= 0; expressionIndex--) {
            var substitution = _state.popValue().convertTo<String>();

            commandText = commandText.replace("{" + expressionIndex + "}", substitution);
          }
        }


        currentExecutionState = ExecutionState.deliveringContent;

        var command = Command(commandText);

        commandHandler(command);

        if (currentExecutionState == ExecutionState.deliveringContent) {
          // The client didn't call Continue, so we'll
          // wait here.
          currentExecutionState = ExecutionState.waitingForContinue;
        }


      }

      case OpCode.pushString: {
        /// - PushString
        /** Pushes a string value onto the stack. The operand is an index into
                         *  the string table, so that's looked up first.
                         */
        _state.pushValue(i.operands[0].StringValue);

      }

      case OpCode.pushFloat: {
        /// - PushFloat
        /** Pushes a floating point onto the stack.
                         */
        _state.pushValue(i.operands[0].FloatValue);

      }

      case OpCode.pushBool: {
        /// - PushBool
        /** Pushes a boolean value onto the stack.
                         */
        _state.pushValue(i.operands[0].BoolValue);

      }

      case OpCode.pushNull: {
        throw InvalidOperationException("PushNull is no longer valid op code, because null is no longer a valid value from Yarn Spinner 2.0 onwards. To fix this error, re-compile the original source code.");
      }

      case OpCode.jumpIfFalse: {
        /// - JumpIfFalse
        /** Jumps to a named label if the value on the top of the stack
                         *  evaluates to the boolean value 'false'.
                         */
        if (_state.peekValue().convertTo<bool>() == false) {
          _state.programCounter = findInstructionPointForLabel(i.operands[0].StringValue) - 1;
        }

      }

      case OpCode.jump: {
        /// - Jump
        /** Jumps to a label whose name is on the stack.
                         */
        var jumpDestination = _state.peekValue().convertTo<String>();
        _state.programCounter = findInstructionPointForLabel(jumpDestination) - 1;

      }

      case OpCode.pop: {
        /// - Pop
        /** Pops a value from the stack.
                         */
        _state.popValue();
      }

      case OpCode.callFunc: {

        /// - CallFunc
        /** Call a function, whose parameters are expected to
                         *  be on the stack. Pushes the function's return value,
                         *  if it returns one.
                         */
        var functionName = i.operands[0].StringValue;

        var function = _dialogue.library.getFunction(functionName);

        var parameterInfos = function.method.getParameters();

        var expectedParamCount = parameterInfos.length;

        // Expect the compiler to have placed the number of parameters
        // actually passed at the top of the stack.
        var actualParamCount = _state.popValue().convertTo<int>() as int;

        if (expectedParamCount != actualParamCount) {
          throw InvalidOperationException("Function ${functionName} expected ${expectedParamCount} parameters, but received ${actualParamCount}");
        }


        // Get the parameters, which were pushed in reverse
        List<Value> parameters = List<Value>();
        var parametersToUse = List<Object>();

        for (int param = actualParamCount - 1; param >= 0; param--) {
          var value = _state.popValue();
          var parameterType = parameterInfos[param].parameterType;
          // Perform type checking on this parameter
          parametersToUse[param] = value.convertTo1(parameterType);
        }


        // Invoke the function
        try {
          IConvertible returnValue = function.dynamicInvoke(parametersToUse) as IConvertible;
          // If the function returns a value, push it
          bool functionReturnsValue = function.method.returnType != void.runtimeType;

          if (functionReturnsValue) {
            var yarnType;
            var yarnTypeRef = RefParam(yarnType);
            if (BuiltinTypes.typeMappings.tryGetValue(returnValue.runtimeType, yarnTypeRef)) {
              yarnType = yarnTypeRef.value;
              Value yarnValue = Value(yarnType, returnValue);

              _state.pushValue(yarnValue);
            }

          }

        }
        on TargetInvocationException catch (ex) {
          // The function threw an exception. Re-throw the exception it threw.
          throw ex.innerException;
        }

      }

      case OpCode.pushVariable: {
        /// - PushVariable
        /** Get the contents of a variable, push that onto the stack.
                         */
        var variableName = i.operands[0].StringValue;

        Value loadedValue;

        var loadedObject;
        var loadedObjectRef = RefParam(loadedObject);
        var didLoadValue = _dialogue.variableStorage.tryGetValue<IConvertible>(variableName, loadedObjectRef);


        loadedObject = loadedObjectRef.value;
        if (didLoadValue) {
          Type loadedObjectType = loadedObject.runtimeType;

          var yarnType;
          var yarnTypeRef = RefParam(yarnType);
          var hasType = BuiltinTypes.typeMappings.tryGetValue(loadedObjectType, yarnTypeRef);

          yarnType = yarnTypeRef.value;
          if (hasType) {
            loadedValue = Value(yarnType, loadedObject);
          }
          else {
            throw InvalidOperationException("No Yarn type found for ${loadedObjectType}");
          }
        }
        else {
          // We don't have a value for this. The initial
          // value may be found in the program. (If it's
          // not, then the variable's value is undefined,
          // which isn't allowed.)
          var value;
          var valueRef = RefParam(value);
          if (program.initialValues.tryGetValue(variableName, valueRef)) {
            value = valueRef.value;
            switch (value.ValueCase) {
              case Operand.ValueOneofCase.stringValue: {
                loadedValue = Value(BuiltinTypes.String, value.StringValue);
              }
              case Operand.ValueOneofCase.boolValue: {
                loadedValue = Value(BuiltinTypes.bool, value.BoolValue);
              }
              case Operand.ValueOneofCase.floatValue: {
                loadedValue = Value(BuiltinTypes.number, value.FloatValue);
              }
              default: {
                throw ArgumentOutOfRangeException("Unknown initial value type ${value.ValueCase} for variable ${variableName}");
              }
            }
          }
          else {
            throw InvalidOperationException("Variable storage returned a null value for variable ${variableName}");
          }
        }

        _state.pushValue(loadedValue);

      }

      case OpCode.storeVariable: {
        /// - StoreVariable
        /** Store the top value on the stack in a variable.
                         */
        var topValue = _state.peekValue();
        var destinationVariableName = i.operands[0].StringValue;

        if (topValue.type == BuiltinTypes.number) {
          _dialogue.variableStorage.setValue(destinationVariableName, topValue.convertTo<double>());
        }
        else if (topValue.type == BuiltinTypes.String) {
          _dialogue.variableStorage.setValue(destinationVariableName, topValue.convertTo<String>());
        }
        else if (topValue.type == BuiltinTypes.bool) {
          _dialogue.variableStorage.setValue(destinationVariableName, topValue.convertTo<bool>());
        }
        else {
          throw ArgumentOutOfRangeException("Invalid Yarn value type ${topValue.type}");
        }

      }

      case OpCode.stop: {
        /// - Stop
        /** Immediately stop execution, and report that fact.
                         */
        nodeCompleteHandler(_currentNode.name);
        dialogueCompleteHandler();
        currentExecutionState = ExecutionState.stopped;

      }

      case OpCode.runNode: {
        /// - RunNode
        /** Run a node
                         */

        // Pop a string from the stack, and jump to a node
        // with that name.
        String nodeName = _state.popValue().convertTo<String>();

        nodeCompleteHandler(_currentNode.name);

        setNode(nodeName);

        // Decrement program counter here, because it will
        // be incremented when this function returns, and
        // would mean skipping the first instruction
        _state.programCounter -= 1;

      }

      case OpCode.addOption: {
        /// - AddOption
        /** Add an option to the current state.
                         */

        var line = Line(i.operands[0].StringValue);

        if (i.operands.Count > 2) {
          // TODO: we only have float operands, which is
          // unpleasant. we should make 'int' operands a
          // valid type, but doing that implies that the
          // language differentiates between floats and
          // ints itself. something to think about.

          // get the number of expressions that we're
          // working with out of the third operand
          var expressionCount = i.operands[2].FloatValue as int;

          var strings = List<String>();

          // pop the expression values off the stack in
          // reverse order, and store the list of substitutions
          for (int expressionIndex = expressionCount - 1; expressionIndex >= 0; expressionIndex--) {
            String substitution = _state.popValue().convertTo<String>();
            strings[expressionIndex] = substitution;
          }

          line.substitutions = strings;
        }


        // Indicates whether the VM believes that the
        // option should be shown to the user, based on any
        // conditions that were attached to the option.
        var lineConditionPassed = true;

        if (i.operands.Count > 3) {
          // The fourth operand is a bool that indicates
          // whether this option had a condition or not.
          // If it does, then a bool value will exist on
          // the stack indiciating whether the condition
          // passed or not. We pass that information to
          // the game.

          var hasLineCondition = i.operands[3].BoolValue;

          if (hasLineCondition) {
            // This option has a condition. Get it from
            // the stack.
            lineConditionPassed = _state.popValue().convertTo<bool>();
          }

        }



        // TODO: Install https://github.com/dart-lang/tuple
        _state.currentOptions.add(Tuple3.fromList([line, i.operands[1].StringValue, lineConditionPassed]));
        // whether the line condition passed

      }

      case OpCode.showOptions: {
        /// - ShowOptions
        /** If we have no options to show, immediately stop.
                         */
        if (_state.currentOptions.count == 0) {
          currentExecutionState = ExecutionState.stopped;
          dialogueCompleteHandler();
        }


        // Present the list of options to the user and let them pick
        var optionChoices = List<Option>();

        for (int optionIndex = 0; optionIndex < _state.currentOptions.count; optionIndex++) {
          var option = _state.currentOptions[optionIndex];
          optionChoices.add(Option(option.line, optionIndex, option.destination, option.enabled));
        }

        // We can't continue until our client tell us which
        // option to pick
        currentExecutionState = ExecutionState.waitingOnOptionSelection;

        // Pass the options set to the client, as well as a
        // delegate for them to call when the user has made
        // a selection
        optionsHandler(OptionSet(optionChoices.toArray()));

        if (currentExecutionState == ExecutionState.waitingForContinue) {
          // we are no longer waiting on an option
          // selection - the options handler must have
          // called SetSelectedOption! Continue running
          // immediately.
          currentExecutionState = ExecutionState.running;
        }


      }

      default: {
        /// - default
        /** Whoa, no idea what OpCode this is. Stop the program
                         * and throw an exception.
                        */
        currentExecutionState = ExecutionState.stopped;
        throw ArgumentOutOfRangeException("Unknown opcode ${i.opcode}");
      }
    }
  }
}
class State {

  /// The name of the node that we're currently
  String currentNodeName;

  /// The instruction number in the current
  int programCounter = 0;

  /// The current list of options that will be delivered
  List<ValueTuple<Line, String, bool>> currentOptions = List<ValueTuple<Line, String, bool>>();

  /// The value stack.
  Stack<Value> _stack = Stack<Value>();

  /// Pushes a [Value] object onto the
  void pushValue(Value v) {
    _stack.push(v);
  }

  void pushValue1(String s) {
    _stack.push(Value(BuiltinTypes.String, s));
  }

  void pushValue2(double f) {
    _stack.push(Value(BuiltinTypes.number, f));
  }

  void pushValue3(bool b) {
    _stack.push(Value(BuiltinTypes.bool, b));
  }

  /// Removes a value from the top of the stack, and
  Value popValue() {
    return _stack.pop();
  }

  /// Peeks at a value from the stack.
  Value peekValue() {
    return _stack.peek();
  }

  /// Clears the stack.
  void clearStack() {
    _stack.clear();
  }
}

class ExecutionState {
  final int value;
  final String name;
  const ExecutionState._(this.value, this.name);

  static const stopped = const ExecutionState._(0, 'stopped');
  static const waitingOnOptionSelection = const ExecutionState._(1, 'waitingOnOptionSelection');
  static const waitingForContinue = const ExecutionState._(2, 'waitingForContinue');
  static const deliveringContent = const ExecutionState._(3, 'deliveringContent');
  static const running = const ExecutionState._(4, 'running');

  static const List<ExecutionState> values = [
    stopped,
    waitingOnOptionSelection,
    waitingForContinue,
    deliveringContent,
    running,
  ];

  @override
  String toString() => 'ExecutionState' + '.' + name;

}
