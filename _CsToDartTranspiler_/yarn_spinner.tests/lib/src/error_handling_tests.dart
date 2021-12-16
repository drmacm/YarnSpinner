import 'package:yarn_spinner.framework.tests/src/test_base.dart';


class ErrorHandlingTests extends TestBase {
  void testMalformedIfStatement() {
    var source = createTestNode("<<if true>> // error: no endif");

    var result = Compiler.compile(CompilationJob.createFromString("<input>", source));

    Assert.collection(result.Diagnostics, (d) => assertTrue (d.Message.contains("Expected an <<endif>> to match the <<if>> statement on line 3")));
  }

  void testExtraneousElse() {
    var source = createTestNode("
            <<if true>>
            One
            <<else>>
            Two
            <<else>>
            Three
            <<endif>>");

    var result = Compiler.compile(CompilationJob.createFromString("<input>", source));

    Assert.collection(result.Diagnostics, (d) => assertTrue (d.Message.contains("More than one <<else>> statement in an <<if>> statement isn't allowed")), (d) => assertTrue (d.Message.contains("Unexpected \"endif\" while reading a statement")));
  }

  void testEmptyCommand() {
    var source = createTestNode("
            <<>>
            ");

    var result = Compiler.compile(CompilationJob.createFromString("<input>", source));

    Assert.collection(result.Diagnostics, (d) => assertTrue (d.Message.contains("Command text expected")));
  }

  void testInvalidVariableNameInSetOrDeclare() {
    var source1 = createTestNode("
            <<set test = 1>>
            ");

    var source2 = createTestNode("
            <<declare test = 1>>
            ");

    for (var source in [source1, source2]) {

      var result = Compiler.compile(CompilationJob.createFromString("input", source));

      Assert.collection(result.Diagnostics, (d) {
        assertTrue (d.Message.contains("Variable names need to start with a $"));
        assertEquals(4, d.Line);
       });
    }
  }

  void testInvalidFunctionCall() {
    var source = createTestNode("<<if someFunction(>><<endif>>");

    var result = Compiler.compile(CompilationJob.createFromString("<input>", source));

    Assert.collection(result.Diagnostics, (d) => assertTrue (d.Message.contains("Unexpected "">>"" while reading a function call")));
  }
}
