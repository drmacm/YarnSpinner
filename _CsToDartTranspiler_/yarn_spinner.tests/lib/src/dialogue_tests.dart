import 'package:yarn_spinner.framework.tests/src/test_base.dart';
import 'package:yarn_spinner.framework.tests/src/test_plan.dart';
import 'package:yarn_spinner.framework/yarn_spinner.framework.dart';


class DialogueTests extends TestBase {
  void testNodeExists() {
    var path = Path.combine(spaceDemoScriptsPath, "Sally.yarn");

    CompilationJob compilationJob = CompilationJob.createFromFiles(path);
    compilationJob.Library = dialogue.library;

    var result = Compiler.compile(compilationJob);

    Assert.empty(result.Diagnostics);

    dialogue.setProgram(result.Program);

    assertTrue(dialogue.nodeExists("Sally"));

    // Test clearing everything
    dialogue.unloadAll();

    assertFalse(dialogue.nodeExists("Sally"));
  }

  void testAnalysis() {

    ICollection<Diagnosis> diagnoses;
    Context context;

    // this script has the following variables:
    // $foo is read from and written to
    // $bar is written to but never read
    // this means that there should be one diagnosis result
    context = Context(UnusedVariableChecker.runtimeType);

    var path = Path.combine(testDataPath, "AnalysisTest.yarn");

    CompilationJob compilationJob = CompilationJob.createFromFiles(path);
    compilationJob.Library = dialogue.library;

    var result = Compiler.compile(compilationJob);

    Assert.empty(result.Diagnostics);

    stringTable = result.StringTable;

    dialogue.setProgram(result.Program);
    dialogue.analyse(context);
    diagnoses = List<Diagnosis>(context.finishAnalysis());

    assertEquals(1, diagnoses.count);
    assertTrue (diagnoses.first().message.contains("Variable $bar is assigned, but never read from"));

    dialogue.unloadAll();

    context = Context(UnusedVariableChecker.runtimeType);

    result = Compiler.compile(CompilationJob.createFromFiles([Path.combine(spaceDemoScriptsPath, "Ship.yarn"), Path.combine(spaceDemoScriptsPath, "Sally.yarn")], dialogue.library));

    Assert.empty(result.Diagnostics);

    dialogue.setProgram(result.Program);

    dialogue.analyse(context);
    diagnoses = List<Diagnosis>(context.finishAnalysis());

    // This script should contain no unused variables
    Assert.empty(diagnoses);
  }

  void testDumpingCode() {

    var path = Path.combine(testDataPath, "Example.yarn");
    var result = Compiler.compile(CompilationJob.createFromFiles(path));

    Assert.empty(result.Diagnostics);

    dialogue.setProgram(result.Program);

    var byteCode = dialogue.getByteCode();
    assertNotNull(byteCode);
  }

  void testMissingNode() {
    var path = Path.combine(testDataPath, "TestCases", "Smileys.yarn");

    var result = Compiler.compile(CompilationJob.createFromFiles(path));

    Assert.empty(result.Diagnostics);

    dialogue.setProgram(result.Program);

    runtimeErrorsCauseFailures = false;

    Assert.Throws<DialogueException>(() => dialogue.setNode("THIS NODE DOES NOT EXIST"));
  }

  void testGettingCurrentNodeName() {

    String path = Path.combine(spaceDemoScriptsPath, "Sally.yarn");

    CompilationJob compilationJob = CompilationJob.createFromFiles(path);
    compilationJob.Library = dialogue.library;

    var result = Compiler.compile(compilationJob);

    Assert.empty(result.Diagnostics);

    dialogue.setProgram(result.Program);

    // dialogue should not be running yet
    assertNull(dialogue.currentNode);

    dialogue.setNode("Sally");
    assertEquals("Sally", dialogue.currentNode);

    dialogue.stop();
    // Current node should now be null
    assertNull(dialogue.currentNode);
  }

  void testGettingRawSource() {

    var path = Path.combine(testDataPath, "Example.yarn");

    var result = Compiler.compile(CompilationJob.createFromFiles(path));

    Assert.empty(result.Diagnostics);

    dialogue.setProgram(result.Program);

    stringTable = result.StringTable;

    var sourceID = dialogue.getStringIDForNode("LearnMore");
    var source = stringTable[sourceID].text;

    assertNotNull(source);

    assertEquals("A: HAHAHA\n", source);
  }
  void testGettingTags() {

    var path = Path.combine(testDataPath, "Example.yarn");

    var result = Compiler.compile(CompilationJob.createFromFiles(path));

    Assert.empty(result.Diagnostics);

    dialogue.setProgram(result.Program);

    var source = dialogue.getTagsForNode("LearnMore");

    assertNotNull(source);

    Assert.notEmpty(source);

    assertEquals("rawText", source.first());
  }

  void testPrepareForLine() {
    var path = Path.combine(testDataPath, "TaggedLines.yarn");

    var result = Compiler.compile(CompilationJob.createFromFiles(path));

    Assert.empty(result.Diagnostics);

    stringTable = result.StringTable;

    bool prepareForLinesWasCalled = false;

    dialogue.PrepareForLinesHandler = (lines) {
      // When the Dialogue realises it's about to run the Start
      // node, it will tell us that it's about to run these two
      // line IDs
      assertEquals(2, lines.count());
      assertTrue (lines.contains("line:test1"));
      assertTrue (lines.contains("line:test2"));

      // Ensure that these asserts were actually called
      prepareForLinesWasCalled = true;
     };

    dialogue.setProgram(result.Program);
    dialogue.setNode("Start");

    assertTrue(prepareForLinesWasCalled);
  }


  void testFunctionArgumentTypeInference() {

    // Register some functions
    dialogue.library.registerFunction1<TResult>("ConcatString", (String a, String b) => a + b);
    dialogue.library.registerFunction1<TResult>("AddInt", (int a, int b) => a + b);
    dialogue.library.registerFunction1<TResult>("AddFloat", (double a, double b) => a + b);
    dialogue.library.registerFunction1<TResult>("NegateBool", (bool a) => !a);

    // Run some code to exercise these functions
    var source = createTestNode("
            <<declare $str = """">>
            <<declare $int = 0>>
            <<declare $float = 0.0>>
            <<declare $bool = false>>

            <<set $str = ConcatString(""a"", ""b"")>>
            <<set $int = AddInt(1,2)>>
            <<set $float = AddFloat(1,2)>>
            <<set $bool = NegateBool(true)>>
            ");

    var result = Compiler.compile(CompilationJob.createFromString("input", source, dialogue.library));

    Assert.empty(result.Diagnostics);

    stringTable = result.StringTable;

    dialogue.setProgram(result.Program);
    dialogue.setNode("Start");

    do  {
      dialogue.continue();
    }
    while (dialogue.isActive);

    // The values should be of the right type and value

    var strValue = null;
    var strValueRef = RefParam(strValue);
    storage.tryGetValue<String>("$str", strValueRef);
    strValue = strValueRef.value;
    assertEquals("ab", strValue);

    var intValue = 0.0;
    var intValueRef = RefParam(intValue);
    storage.tryGetValue<double>("$int", intValueRef);
    intValue = intValueRef.value;
    assertEquals(3, intValue);

    var floatValue = 0.0;
    var floatValueRef = RefParam(floatValue);
    storage.tryGetValue<double>("$float", floatValueRef);
    floatValue = floatValueRef.value;
    assertEquals(3, floatValue);

    var boolValue = false;
    var boolValueRef = RefParam(boolValue);
    storage.tryGetValue<bool>("$bool", boolValueRef);
    boolValue = boolValueRef.value;
    assertFalse(boolValue);
  }

  void testSelectingOptionFromInsideOptionCallback() {
    var testCase = TestPlanBuilder().addOption("option 1").addOption("option 2").addSelect(0).addLine("final line").getPlan();

    dialogue.LineHandler = (line) {
      var lineText = stringTable[line.ID];
      var parsedText = dialogue.parseMarkup(lineText.text).text;
      testCase.next();

      assertEquals(TestPlan.Step.Type.line, testCase.nextExpectedType);
      assertEquals(testCase.nextExpectedValue, parsedText);

      dialogue.continue();
     };

    dialogue.OptionsHandler = (optionSet) {
      testCase.next();

      int optionCount = optionSet.Options.count();

      assertEquals(TestPlan.Step.Type.select, testCase.nextExpectedType);

      // Assert that the list of options we were given is
      // identical to the list of options we expect
      var actualOptionList = optionSet.Options.select((o) => Tuple2.fromList([getComposedTextForLine(o.Line), o.IsAvailable])).toList();
      assertEquals(testCase.nextExpectedOptions, actualOptionList);

      var expectedOptionCount = testCase.nextExpectedOptions.count();

      assertEquals(expectedOptionCount, optionCount);

      dialogue.setSelectedOption(0);
     };

    dialogue.CommandHandler = (command) {
      testCase.next();
      assertEquals(TestPlan.Step.Type.command, testCase.nextExpectedType);
      dialogue.continue();
     };

    dialogue.DialogueCompleteHandler = () {
      testCase.next();
      assertEquals(TestPlan.Step.Type.stop, testCase.nextExpectedType);
      dialogue.continue();
     };

    var code = createTestNode("-> option 1\n->option 2\nfinal line\n");

    var job = CompilationJob.createFromString("input", code);

    var result = Compiler.compile(job);

    Assert.empty(result.Diagnostics);

    stringTable = result.StringTable;

    dialogue.setProgram(result.Program);
    dialogue.setNode("Start");

    dialogue.continue();
  }
}
