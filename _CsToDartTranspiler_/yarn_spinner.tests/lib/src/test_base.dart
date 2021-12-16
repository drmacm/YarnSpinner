import 'package:yarn_spinner.framework.tests/src/test_plan.dart';
import 'package:yarn_spinner.framework/yarn_spinner.framework.dart';

class TestBase {
  IVariableStorage storage = MemoryVariableStore();
  Dialogue dialogue;
  Map<String, StringInfo> stringTable;
  Iterable<Declaration> declarations;

  String locale = "en";

  bool runtimeErrorsCauseFailures = true;

  // Returns the path that contains the test case files.

  static String get projectRootPath {
    var path = Assembly.getCallingAssembly().location.split(Path.directorySeparatorChar).toList();

    var index = path.findIndex((x) => x == "YarnSpinner.Tests");

    if (index == -1) {
      throw DirectoryNotFoundException("Cannot find test data directory");
    }


    var testDataDirectory = path.take(index).toList();

    var pathToTestData = String.join(Path.directorySeparatorChar.toString(CultureInfo.invariantCulture), testDataDirectory.toArray());

    return pathToTestData;
  }



  static String get testDataPath {
    return Path.combine(projectRootPath, "Tests");
  }


  static String get spaceDemoScriptsPath {
    return Path.combine(projectRootPath, "Tests/Projects/Space");
  }


  TestPlan testPlan;

  String getComposedTextForLine(Line line) {

    var substitutedText = Dialogue.expandSubstitutions(stringTable[line.iD].text, line.substitutions);

    return dialogue.parseMarkup(substitutedText).text;
  }

  TestBase() {

    dialogue = Dialogue(storage);

    dialogue.languageCode = "en";

    dialogue.Logger = (String message) {
      Console.resetColor();
      print(message);
     };

    dialogue.Logger = (String message) {
      Console.foregroundColor = ConsoleColor.red;
      print("ERROR: " + message);
      Console.resetColor();

      if (runtimeErrorsCauseFailures == true) {
        assertNotNull(message);
      }

     };

    dialogue.LineHandler = (Line line) {
      var id = line.iD;

      assertTrue (stringTable.keys.contains(id));

      var lineNumber = stringTable[id].lineNumber;

      var text = getComposedTextForLine(line);

      print("Line: " + text);

      if (testPlan != null) {
        testPlan.next();

        if (testPlan.nextExpectedType == TestPlan.Step.Type.line) {
          assertEquals("Line ${lineNumber}: ${testPlan.nextExpectedValue}", "Line ${lineNumber}: ${text}");
        }
        else {
          throw XunitException("Received line ${text}, but was expecting a ${testPlan.nextExpectedType.toString()}");
        }
      }

     };

    dialogue.OptionsHandler = (OptionSet optionSet) {
      var optionCount = optionSet.options.length;

      print("Options:");
      for (var option in optionSet.options) {
        var optionText = getComposedTextForLine(option.line);
        print(" - " + optionText);
      }

      if (testPlan != null) {
        testPlan.next();

        if (testPlan.nextExpectedType != TestPlan.Step.Type.select) {
          throw XunitException("Received ${optionCount} options, but wasn't expecting them (was expecting ${testPlan.nextExpectedType.toString()})");
        }


        // Assert that the list of options we were given is
        // identical to the list of options we expect
        var actualOptionList = optionSet.options.select((o) => Tuple2.fromList([getComposedTextForLine(o.Line), o.IsAvailable])).toList();
        assertEquals(testPlan.nextExpectedOptions, actualOptionList);

        var expectedOptionCount = testPlan.nextExpectedOptions.count();

        assertEquals(expectedOptionCount, optionCount);

        if (testPlan.nextOptionToSelect != -1) {
          dialogue.setSelectedOption(testPlan.nextOptionToSelect - 1);
        }
        else {
          dialogue.setSelectedOption(0);
        }
      }

     };

    dialogue.CommandHandler = (Command command) {
      print("Command: " + command.text);

      if (testPlan != null) {
        testPlan.next();
        if (testPlan.nextExpectedType != TestPlan.Step.Type.command) {
          throw XunitException("Received command ${command.text}, but wasn't expecting to select one (was expecting ${testPlan.nextExpectedType.toString()})");
        }
        else {
          // We don't need to get the composed string for a
          // command because it's been done for us in the
          // virtual machine. The VM can do this because
          // commands are not localised, so we don't need to
          // refer to the string table to get the text.
          assertEquals(testPlan.nextExpectedValue, command.text);
        }
      }

     };

    dialogue.library.registerFunction1<TResult>("assert", (Value value) {
      if (value.convertTo<bool>() == false) {
        assertNotNull("Assertion failed");
      }

      return true;
     });


    // When a node is complete, do nothing
    dialogue.NodeCompleteHandler = (String nodeName) {
     };

    // When dialogue is complete, check that we expected a stop
    dialogue.DialogueCompleteHandler = () {
      if (testPlan != null) {
        testPlan.next();

        if (testPlan.nextExpectedType != TestPlan.Step.Type.stop) {
          throw XunitException("Stopped dialogue, but wasn't expecting to select it (was expecting ${testPlan.nextExpectedType.toString()})");
        }

      }

     };

    // The Space test scripts call a function called "visited",
    // which is defined in the Unity runtime and returns true if a
    // node with the given name has been run before. For type
    // correctness, we stub it out here with an implementation that
    // just returns false
    dialogue.library.registerFunction1<TResult>("visited", (String nodeName) => false);
  }

  void runStandardTestcase([String nodeName = "Start"]) {

    if (testPlan == null) {
      throw XunitException("Cannot run test: no test plan provided.");
    }


    dialogue.setNode(nodeName);

    do  {
      dialogue.continue();
    }
    while (dialogue.isActive);
  }

  String createTestNode(String source, [String name = "Start"]) {
    return "title: ${name}\n---\n${source}\n===";
  }

  void loadTestPlan(String path) {
    testPlan = TestPlan(path);
  }

  // Returns the list of .node and.yarn files in the
  // Tests/<directory> directory.
  static Iterable<List<Object>> fileSources(String directoryComponents) {

    var allowedExtensions = [".node", ".yarn"];

    var directory = Path.combine(directoryComponents.split('/'));

    var path = Path.combine(testDataPath, directory);

    var files = _getFilesInDirectory(path);

    return files.where((p) => allowedExtensions.contains(Path.getExtension(p))).where((p) => p.endsWith(".upgraded.yarn") == false)    // don't include ".upgraded.yarn" (used in UpgraderTests)
.select((p) => [Path.combine(directory, Path.getFileName(p))]);
  }

  static Iterable<List<Object>> directorySources(String directoryComponents) {
    var directory = Path.combine(directoryComponents.split('/'));

    var path = Path.combine(testDataPath, directory);

    try {
      return Directory.getDirectories(path).select((d) => d.replace(testDataPath + Path.directorySeparatorChar, "")).select((d) => [d]);
    }
    on DirectoryNotFoundException catch () {
      return List<String>().select((d) => [d]);
    }
  }

  // Returns the list of files in a directory. If that directory doesn't
  // exist, returns an empty list.
  static Iterable<String> _getFilesInDirectory(String path) {
    try {
      return Directory.enumerateFiles(path);
    }
    on DirectoryNotFoundException catch () {
      return List<String>();
    }
  }
}
