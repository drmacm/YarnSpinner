import 'package:yarn_spinner.framework.tests/src/test_base.dart';
import 'package:yarn_spinner.framework/yarn_spinner.framework.dart';
class LanguageTests extends TestBase {
  LanguageTests() {

    // Register some additional functions
    dialogue.library.registerFunction1<TResult>("add_three_operands", (int a, int b, int c) {
      return a + b + c;
     });
  }

  void testExampleScript() {

    runtimeErrorsCauseFailures = false;
    var path = Path.combine(testDataPath, "Example.yarn");
    var testPath = Path.changeExtension(path, ".testplan");

    var result = Compiler.compile(CompilationJob.createFromFiles(path));

    Assert.empty(result.Diagnostics);

    dialogue.setProgram(result.Program);
    stringTable = result.StringTable;

    loadTestPlan(testPath);

    runStandardTestcase();
  }

  void testMergingNodes() {
    var sallyPath = Path.combine(spaceDemoScriptsPath, "Sally.yarn");
    var shipPath = Path.combine(spaceDemoScriptsPath, "Ship.yarn");

    CompilationJob compilationJobSally = CompilationJob.createFromFiles(sallyPath);
    CompilationJob compilationJobSallyAndShip = CompilationJob.createFromFiles(sallyPath, shipPath);

    compilationJobSally.Library = dialogue.library;
    compilationJobSallyAndShip.Library = dialogue.library;

    var resultSally = Compiler.compile(compilationJobSally);
    var resultSallyAndShip = Compiler.compile(compilationJobSallyAndShip);


    Assert.empty(resultSally.Diagnostics);
    Assert.empty(resultSallyAndShip.Diagnostics);

    // Loading code with the same contents should throw
    Assert.Throws<InvalidOperationException>(() {
      var combinedNotWorking = Program.combine(resultSally.Program, resultSallyAndShip.Program);
     });
  }



  void testEndOfNotesWithOptionsNotAdded() {
    var path = Path.combine(testDataPath, "SkippedOptions.yarn");

    var result = Compiler.compile(CompilationJob.createFromFiles(path));

    Assert.empty(result.Diagnostics);

    dialogue.setProgram(result.Program);
    stringTable = result.StringTable;

    dialogue.OptionsHandler = (OptionSet optionSets) {
      assertFalse(true, "Options should not be shown to the user in this test.");
     };

    dialogue.setNode();
    dialogue.continue();
  }

  void testNodeHeaders() {
    var path = Path.combine(testDataPath, "Headers.yarn");
    var result = Compiler.compile(CompilationJob.createFromFiles(path));

    Assert.empty(result.Diagnostics);

    assertEquals(4, result.Program.Nodes.Count);

    for (var tag in ["one", "two", "three"]) {
      assertTrue (result.Program.Nodes["Tags"].Tags.contains(tag));
    }

    // Assert.Contains("version:2", result.FileTags);
    assertTrue (result.FileTags.Keys.contains(path));
    Assert.single(result.FileTags);
    Assert.single(result.FileTags[path]);
    assertTrue (result.FileTags[path].contains("file_header"));
  }

  void testInvalidCharactersInNodeTitle() {
    var path = Path.combine(testDataPath, "InvalidNodeTitle.yarn");

    var result = Compiler.compile(CompilationJob.createFromFiles(path));

    Assert.notEmpty(result.Diagnostics);
  }

  void testNumberPlurals() {

    List<ValueTuple<String, double, PluralCase>> cardinalTests = [
    // English
Tuple3.fromList(["en", 1.0, PluralCase.one]), Tuple3.fromList(["en", 2.0, PluralCase.other]), Tuple3.fromList(["en", 1.1, PluralCase.other]), 
    // Arabic
Tuple3.fromList(["ar", 0.0, PluralCase.zero]), Tuple3.fromList(["ar", 1.0, PluralCase.one]), Tuple3.fromList(["ar", 2.0, PluralCase.two]), Tuple3.fromList(["ar", 3.0, PluralCase.few]), Tuple3.fromList(["ar", 11.0, PluralCase.many]), Tuple3.fromList(["ar", 100.0, PluralCase.other]), Tuple3.fromList(["ar", 0.1, PluralCase.other]), 
    // Polish
Tuple3.fromList(["pl", 1.0, PluralCase.one]), Tuple3.fromList(["pl", 2.0, PluralCase.few]), Tuple3.fromList(["pl", 3.0, PluralCase.few]), Tuple3.fromList(["pl", 4.0, PluralCase.few]), Tuple3.fromList(["pl", 5.0, PluralCase.many]), Tuple3.fromList(["pl", 1.1, PluralCase.other]), 
    // Icelandic
Tuple3.fromList(["is", 1.0, PluralCase.one]), Tuple3.fromList(["is", 21.0, PluralCase.one]), Tuple3.fromList(["is", 31.0, PluralCase.one]), Tuple3.fromList(["is", 41.0, PluralCase.one]), Tuple3.fromList(["is", 51.0, PluralCase.one]), Tuple3.fromList(["is", 0.0, PluralCase.other]), Tuple3.fromList(["is", 4.0, PluralCase.other]), Tuple3.fromList(["is", 100.0, PluralCase.other]), Tuple3.fromList(["is", 3.0, PluralCase.other]), Tuple3.fromList(["is", 4.0, PluralCase.other]), Tuple3.fromList(["is", 5.0, PluralCase.other]), 
    // Russian
Tuple3.fromList(["ru", 1.0, PluralCase.one]), Tuple3.fromList(["ru", 2.0, PluralCase.few]), Tuple3.fromList(["ru", 3.0, PluralCase.few]), Tuple3.fromList(["ru", 5.0, PluralCase.many]), Tuple3.fromList(["ru", 0.0, PluralCase.many]), Tuple3.fromList(["ru", 0.1, PluralCase.other])];

    List<ValueTuple<String, int, PluralCase>> ordinalTests = [    // English
Tuple3.fromList(["en", 1, PluralCase.one]), Tuple3.fromList(["en", 2, PluralCase.two]), Tuple3.fromList(["en", 3, PluralCase.few]), Tuple3.fromList(["en", 4, PluralCase.other]), Tuple3.fromList(["en", 11, PluralCase.other]), Tuple3.fromList(["en", 21, PluralCase.one]), 
    // Welsh
Tuple3.fromList(["cy", 0, PluralCase.zero]), Tuple3.fromList(["cy", 7, PluralCase.zero]), Tuple3.fromList(["cy", 1, PluralCase.one]), Tuple3.fromList(["cy", 2, PluralCase.two]), Tuple3.fromList(["cy", 3, PluralCase.few]), Tuple3.fromList(["cy", 4, PluralCase.few]), Tuple3.fromList(["cy", 5, PluralCase.many]), Tuple3.fromList(["cy", 10, PluralCase.other])];

    for (var test in cardinalTests) {
      assertEquals(test.item3, CLDRPlurals.NumberPlurals.getCardinalPluralCase(test.item1, test.item2));
    }

    for (var test in ordinalTests) {
      assertEquals(test.item3, CLDRPlurals.NumberPlurals.getOrdinalPluralCase(test.item1, test.item2));
    }
  }

  // Test every file in Tests/TestCases
  void testSources(String file) {

    Console.foregroundColor = ConsoleColor.blue;
    print("INFO: Loading file ${file}");

    storage.clear();

    var scriptFilePath = Path.combine(testDataPath, file);

    CompilationJob compilationJob = CompilationJob.createFromFiles(scriptFilePath);
    compilationJob.Library = dialogue.library;

    var testPlanFilePath = Path.changeExtension(scriptFilePath, ".testplan");

    bool testPlanExists = File.exists(testPlanFilePath);

    if (testPlanExists == false) {
      // No test plan for this file exists, which indicates that
      // the file is not expected to compile. We'll actually make
      // it a test failure if it _does_ compile.

      var result = Compiler.compile(compilationJob);
      Assert.notEmpty(result.Diagnostics);
    }
    else {
      // Compile the job, and expect it to succeed.
      var result = Compiler.compile(compilationJob);

      Assert.empty(result.Diagnostics);

      assertNotNull(result.Program);

      loadTestPlan(testPlanFilePath);

      dialogue.setProgram(result.Program);
      stringTable = result.StringTable;

      // If this file contains a Start node, run the test case
      // (otherwise, we're just testing its parsability, which
      // we did in the last line)
      if (dialogue.nodeExists("Start")) {
        runStandardTestcase();
      }

    }
  }
}
