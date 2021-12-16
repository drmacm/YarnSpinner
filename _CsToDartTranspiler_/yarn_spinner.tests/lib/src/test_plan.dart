class TestPlan {

  Type type = Type.Option;

  String stringValue;
  int intValue = 0;

  bool expectOptionEnabled = true;

  Step(String s) {
    intValue = -1;
    stringValue = null;

    var reader = _Reader(s);

    try {
      type = reader.readNext<Type>();

      if (type == Type.stop) {
        return;
      }


      var delimiter = reader.read() as String;
      if (delimiter != ':') {
        throw ArgumentError("Expected ':' after step type");
      }


      switch (type) {
        // for lines, options and commands: we expect to
        // see the rest of this line
        case Type.line, Type.option, Type.command: {
          stringValue = reader.readToEnd().trim();
          if (stringValue == "*") {
            // '*' represents "we want to see an option
            // but don't care what its text is" -
            // represent this as the null value
            stringValue = null;
          }


          // Options whose text ends with " [disabled]"
          // are expected to be present, but have their
          // 'allowed' flag set to false
          if (type == Type.option && stringValue.endsWith(" [disabled]")) {
            expectOptionEnabled = false;
            stringValue = stringValue.replace(" [disabled]", "");
          }

        }

        case Type.select: {
          intValue = reader.readNext<int>();

          if (intValue < 1) {
            throw ArgumentOutOfRangeException("Cannot select option ${intValue} - must be >= 1");
          }


        }
      }
    }
    on Exception catch (e) {
      // there was a syntax or semantic error
      throw ArgumentError("Failed to parse step line: '${s}' (reason: ${e.message})");
    }
  }

  Step(Type type, String stringValue) {
    this.type = type;
    this.stringValue = stringValue;
  }

  Step(Type type, int intValue) {
    this.type = type;
    this.intValue = intValue;
  }

  Step(Type type) {
  }

}

  List<Step> Steps = List<Step>();

  int _currentTestPlanStep = 0;

  Type nextExpectedType = Type.Option;
  List<ValueTuple<String, bool>> nextExpectedOptions = List<ValueTuple<String, bool>>();
  int nextOptionToSelect = -1;
  String nextExpectedValue = null;

  TestPlan() {
  }

  TestPlan(String path) {
    steps = File.readAllLines(path).where((line) => line.trimStart().startsWith("#") == false)    // skip commented lines
.where((line) => line.trim() != "")    // skip empty or blank lines
.select((line) => Step(line))    // convert remaining lines to steps
.toList();
  }

  void next() {
    // step through the test plan until we hit an expectation to
    // see a line, option, or command. specifically, we're waiting
    // to see if we got a Line, Select, Command or Assert step
    // type.

    if (nextExpectedType == Step.Type.select) {
      // our previously-notified task was to select an option.
      // we've now moved past that, so clear the list of expected
      // options.
      nextExpectedOptions.clear();
      nextOptionToSelect = 0;
    }


    while (_currentTestPlanStep < steps.count) {

      Step currentStep = steps[_currentTestPlanStep];

      _currentTestPlanStep += 1;

      switch (currentStep.type) {
        case Step.Type.line, Step.Type.command, Step.Type.stop: {
          nextExpectedType = currentStep.type;
          nextExpectedValue = currentStep.stringValue;
_done        }
        case Step.Type.select: {
          nextExpectedType = currentStep.type;
          nextOptionToSelect = currentStep.intValue;
_done        }
        case Step.Type.option: {
          nextExpectedOptions.add(Tuple2.fromList([currentStep.stringValue, currentStep.expectOptionEnabled]));
          continue
        }
      }
    }

    // We've fallen off the end of the test plan step list. We
    // expect a stop here.
    nextExpectedType = Step.Type.stop;

    return;
  }
}
class Step {

class Type {
  final int value;
  final String name;
  const Type._(this.value, this.name);

  // expecting to see this specific line
  static const line = const Type._(0, 'line');
  // expecting to see this specific option (if '*' is given,
  // means 'see an option, don't care about text')
  static const option = const Type._(1, 'option');
  // expecting options to have been presented; value = the
  // index to select
  static const select = const Type._(2, 'select');
  // expecting to see this specific command
  static const command = const Type._(3, 'command');
  // expecting to stop the test here (this is optional - a
  // 'stop' at the end of a test plan is assumed)
  static const stop = const Type._(4, 'stop');

  static const List<Type> values = [
    line,
    option,
    select,
    command,
    stop,
  ];

  @override
  String toString() => 'Type' + '.' + name;

}
class _Reader extends StringReader {
  // hat tip to user Dennis from Stackoverflow:
  // https://stackoverflow.com/a/26669930/2153213
  _Reader(String s) {
  }

  // Parse the next T from this string, ignoring leading
  // whitespace
  T readNext<T>() {
    var sb = StringBuilder();

    do  {
      var current = read();
      if (current < 0) {
        break
      }


      // eat leading whitespace
      if (String.isWhiteSpace(current as String)) {
        continue
      }


      sb.append(current as String);

      var next = peek() as String;
      if (String.isLetterOrDigit(next) == false) {
        break
      }

    }
    while (true);

    var value = sb.toString();

    var type = T.runtimeType;
    if (type.isEnum) {
      return Enum.parse(type, value, true) as T;
    }


    return (value as IConvertible).toType(T.runtimeType, System.Globalization.CultureInfo.invariantCulture) as T;
  }
}

class TestPlanBuilder {

  TestPlan _testPlan;

  TestPlanBuilder() {
    _testPlan = TestPlan();
  }

  TestPlan getPlan() {
    return _testPlan;
  }

  TestPlanBuilder addLine(String line) {
    _testPlan.steps.add(Step(TestPlan.Step.Type.line, line));
    return this;
  }

  TestPlanBuilder addOption([String text = null]) {
    _testPlan.steps.add(Step(TestPlan.Step.Type.option, text));
    return this;
  }

  TestPlanBuilder addSelect(int value) {
    _testPlan.steps.add(Step(TestPlan.Step.Type.select, value));
    return this;
  }

  TestPlanBuilder addCommand(String command) {
    _testPlan.steps.add(Step(TestPlan.Step.Type.command, command));
    return this;
  }

  TestPlanBuilder addStop() {
    _testPlan.steps.add(Step(TestPlan.Step.Type.stop));
    return this;
  }
}
