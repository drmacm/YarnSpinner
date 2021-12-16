import 'package:yarn_spinner.framework.tests/src/test_base.dart';
import 'package:yarn_spinner.framework.tests/src/test_plan.dart';
import 'package:yarn_spinner.framework/yarn_spinner.framework.dart';


class TypeTests extends TestBase {
  TypeTests() {
  }

  void _testVariableDeclarationsParsed() {
    var source = createTestNode("
            <<declare $int = 5>>            
            <<declare $str = ""yes"">>
            
            // These value changes are allowed, 
            // because they match the declared type
            <<set $int = 6>>
            <<set $str = ""no"">>
            <<set $bool = false>>

            // Declarations are allowed anywhere in the program
            <<declare $bool = true>>
            ");

    var result = Compiler.compile(CompilationJob.createFromString("input", source));

    Assert.empty(result.Diagnostics);

    var item = Declaration;
    item.Name = "$int";
    item.Type = BuiltinTypes.number;
    item.DefaultValue = 5.0;
    item.SourceNodeLine = 1;
    item.SourceNodeName = "Start";
    item.SourceFileName = "input";
    var item1 = Declaration;
    item1.Name = "$str";
    item1.Type = BuiltinTypes.String;
    item1.DefaultValue = "yes";
    item1.SourceNodeLine = 2;
    item1.SourceNodeName = "Start";
    item1.SourceFileName = "input";
    var item2 = Declaration;
    item2.Name = "$bool";
    item2.Type = BuiltinTypes.bool;
    item2.DefaultValue = true;
    item2.SourceNodeLine = 11;
    item2.SourceNodeName = "Start";
    item2.SourceFileName = "input";
    var expectedDeclarations = [item, item1, item2];

    var actualDeclarations = List<Declaration>(result.Declarations);

    for (int i = 0; i < expectedDeclarations.count; i++) {
      Declaration expected = expectedDeclarations[i];
      Declaration actual = actualDeclarations[i];

      assertEquals(expected.Name, actual.Name);
      assertEquals(expected.Type, actual.Type);
      assertEquals(expected.DefaultValue, actual.DefaultValue);
      assertEquals(expected.SourceNodeLine, actual.SourceNodeLine);
      assertEquals(expected.SourceNodeName, actual.SourceNodeName);
      assertEquals(expected.SourceFileName, actual.SourceFileName);
    }
  }

  void testDeclarationsCanAppearInOtherFiles() {
    // Create two separately-compiled compilation units that each
    // declare a variable that's modified by the other
    var sourceA = createTestNode("
            <<declare $varB = 1>>
            <<set $varA = 2>>
            ", "NodeA");

    var sourceB = createTestNode("
            <<declare $varA = 1>>
            <<set $varB = 2>>
            ", "NodeB");

    var item = File;
    item.FileName = "sourceA";
    item.Source = sourceA;
    var item1 = File;
    item1.FileName = "sourceB";
    item1.Source = sourceB;
    var compilationJob = CompilationJob;
    compilationJob.Files = [item, item1];

    var result = Compiler.compile(compilationJob);

    Assert.empty(result.Diagnostics);
  }

  void testImportingVariableDeclarations() {
    var source = createTestNode("
            <<set $int = 6>> // no error; declaration is imported            
            ");

    var item = Declaration;
    item.Name = "$int";
    item.Type = BuiltinTypes.number;
    item.DefaultValue = 0;
    var declarations = [item];

    CompilationJob compilationJob = CompilationJob.createFromString("input", source);

    // Provide the declarations
    compilationJob.VariableDeclarations = declarations;

    // Should compile with no errors because $int was declared
    var result = Compiler.compile(compilationJob);

    Assert.empty(result.Diagnostics);

    // No variables are declared in the source code, so we should
    // expect an empty collection of variable declarations
    Assert.empty(result.Declarations);
  }

  void _testVariableDeclarationsDisallowDuplicates() {
    var source = createTestNode("
            <<declare $int = 5>>
            <<declare $int = 6>> // error! redeclaration of $int        
            ");

    var result = Compiler.compile(CompilationJob.createFromString("input", source));

    Assert.collection(result.Diagnostics, (p) => assertTrue (p.Message.contains("$int has already been declared")));
  }

  void testExpressionsDisallowMismatchedTypes() {
    var source = createTestNode("
            <<declare $int = 5>>
            <<set $int = ""5"">> // error, can't assign string to a variable declared int
            ");

    var result = Compiler.compile(CompilationJob.createFromString("input", source));

    Assert.collection(result.Diagnostics, (p) => assertTrue (p.Message.contains("$int (Number) cannot be assigned a String")));
  }

  void testExpressionsAllowsUsingUndeclaredVariables(String testSource) {
    var source = createTestNode("
            ${testSource}
            ");

    var result = Compiler.compile(CompilationJob.createFromString("input", source));

    Assert.empty(result.Diagnostics);
  }

  void testExpressionsRequireCompatibleTypes(bool declare) {
    var source = createTestNode("
            ${(declare ? "<<declare $int = 0>>" : "")}
            ${(declare ? "<<declare $bool = false>>" : "")}
            ${(declare ? "<<declare $str = \"\">>" : "")}

            <<set $int = 1>>
            <<set $int = 1 + 1>>
            <<set $int = 1 - 1>>
            <<set $int = 1 * 2>>
            <<set $int = 1 / 2>>
            <<set $int = 1 % 2>>
            <<set $int += 1>>
            <<set $int -= 1>>
            <<set $int *= 1>>
            <<set $int /= 1>>
            <<set $int %= 1>>

            <<set $str = ""hello"">>
            <<set $str = ""hel"" + ""lo"">>

            <<set $bool = true>>
            <<set $bool = 1 > 1>>
            <<set $bool = 1 < 1>>
            <<set $bool = 1 <= 1>>
            <<set $bool = 1 >= 1>>

            <<set $bool = ""hello"" == ""hello"">>
            <<set $bool = ""hello"" != ""goodbye"">>
            <<set $bool = 1 == 1>>
            <<set $bool = 1 != 2>>
            <<set $bool = true == true>>
            <<set $bool = true != false>>

            <<set $bool = (1 + 1) > 2>>
            ");

    // Should compile with no exceptions
    var result = Compiler.compile(CompilationJob.createFromString("input", source));

    Assert.empty(result.Diagnostics);
  }

  void testNullNotAllowed() {
    var source = createTestNode("
            <<declare $err = null>> // error, null not allowed
            ");

    var result = Compiler.compile(CompilationJob.createFromString("input", source));

    Assert.collection(result.Diagnostics, (p) => assertTrue (p.Message.contains("Null is not a permitted type")));
  }

  void testFunctionSignatures(String source) {
    dialogue.library.registerFunction1<TResult>("func_void_bool", () => true);
    dialogue.library.registerFunction1<TResult>("func_int_bool", (int i) => true);
    dialogue.library.registerFunction1<TResult>("func_int_int_bool", (int i, int j) => true);
    dialogue.library.registerFunction1<TResult>("func_string_string_bool", (String i, String j) => true);

    var correctSource = createTestNode(source);

    // Should compile with no exceptions
    var result = Compiler.compile(CompilationJob.createFromString("input", correctSource, dialogue.library));

    Assert.empty(result.Diagnostics);

    // The variable '$bool' should have an implicit declaration.
    var variableDeclarations = result.Declarations.where((d) => d.Name == "$bool");

    Assert.single(variableDeclarations);

    var variableDeclaration = variableDeclarations.first();

    // The type of the variable should be Boolean, because that's
    // the return type of all of the functions we declared.
    assertSame(BuiltinTypes.bool, variableDeclaration.Type);
  }

  void testOperatorsAreTypeChecked(String operation, bool declared) {

    String source = createTestNode("
                ${(declared ? "<<declare $var = 0>>" : "")}
                <<set $var ${operation}>>
            ");

    var result = Compiler.compile(CompilationJob.createFromString("input", source, dialogue.library));

    Assert.empty(result.Diagnostics);
  }

  void testFailingFunctionDeclarationReturnType() {

    dialogue.library.registerFunction1<TResult>("func_invalid_return", () => [1, 2, 3]);

    var source = createTestNode("Hello");

    var result = Compiler.compile(CompilationJob.createFromString("input", source, dialogue.library));

    Assert.collection(result.Diagnostics, (p) => assertTrue (p.Message.contains("not a valid return type")));
  }

  void testFailingFunctionDeclarationParameterType() {
    dialogue.library.registerFunction1<TResult>("func_invalid_param", (List<int> listOfInts) => true);

    var source = createTestNode("Hello");

    var result = Compiler.compile(CompilationJob.createFromString("input", source, dialogue.library));

    Assert.collection(result.Diagnostics, (p) => assertTrue (p.Message.contains("parameter listOfInts's type (System.Collections.Generic.List`1[System.Int32]) cannot be used in Yarn functions")));
  }

  void testFailingFunctionSignatures(String source, String expectedExceptionMessage) {
    dialogue.library.registerFunction1<TResult>("func_void_bool", () => true);
    dialogue.library.registerFunction1<TResult>("func_int_bool", (int i) => true);
    dialogue.library.registerFunction1<TResult>("func_int_int_bool", (int i, int j) => true);
    dialogue.library.registerFunction1<TResult>("func_string_string_bool", (String i, String j) => true);

    var failingSource = createTestNode("
                <<declare $bool = false>>
                <<declare $int = 1>>
                ${source}
            ");

    var result = Compiler.compile(CompilationJob.createFromString("input", failingSource, dialogue.library));

    Assert.collection(result.Diagnostics, (p) => Assert.matches(expectedExceptionMessage, p.Message));
  }

  void testInitialValues() {
    var source = createTestNode("
            <<declare $int = 42>>
            <<declare $str = ""Hello"">>
            <<declare $bool = true>>
            // internal decls
            {$int}
            {$str}
            {$bool}
            // external decls
            {$external_int}
            {$external_str}
            {$external_bool}
            ");

    testPlan = TestPlanBuilder().addLine("42").addLine("Hello").addLine("True").addLine("42").addLine("Hello").addLine("True").getPlan();

    CompilationJob compilationJob = CompilationJob.createFromString("input", source, dialogue.library);

    var item = Declaration;
    item.Name = "$external_str";
    item.Type = BuiltinTypes.String;
    item.DefaultValue = "Hello";
    var item1 = Declaration;
    item1.Name = "$external_int";
    item1.Type = BuiltinTypes.bool;
    item1.DefaultValue = true;
    var item2 = Declaration;
    item2.Name = "$external_bool";
    item2.Type = BuiltinTypes.number;
    item2.DefaultValue = 42;
    compilationJob.VariableDeclarations = [item, item1, item2];

    var result = Compiler.compile(compilationJob);

    Assert.empty(result.Diagnostics);

    storage.setValue("$external_str", "Hello");
    storage.setValue("$external_int", 42);
    storage.setValue("$external_bool", true);

    dialogue.setProgram(result.Program);
    stringTable = result.StringTable;

    runStandardTestcase();
  }

  void testExplicitTypes() {
    var source = createTestNode("
            <<declare $str = ""hello"" as string>>
            <<declare $int = 1 as number>>
            <<declare $bool = false as bool>>
            ");

    var result = Compiler.compile(CompilationJob.createFromString("input", source, dialogue.library));

    Assert.empty(result.Diagnostics);

    Assert.collection(result.Declarations.where((d) => d.Name.startsWith("$")), (d) {
      assertEquals(d.Name, "$str");
      assertEquals(d.Type.Name, "String");
     }, (d) {
      assertEquals(d.Name, "$int");
      assertEquals(d.Type.Name, "Number");
     }, (d) {
      assertEquals(d.Name, "$bool");
      assertEquals(d.Type.Name, "Bool");
     });
  }




  void testExplicitTypesMustMatchValue(String test) {
    var source = createTestNode(test);

    var result = Compiler.compile(CompilationJob.createFromString("input", source, dialogue.library));

    Assert.collection(result.Diagnostics, (p) => Assert.matches("Type \w+ does not match", p.Message));
  }

  void testVariableDeclarationAnnotations() {
    var source = createTestNode("
            /// prefix: a number
            <<declare $prefix_int = 42>>

            /// prefix: a string
            <<declare $prefix_str = ""Hello"">>

            /// prefix: a bool
            <<declare $prefix_bool = true>>

            <<declare $suffix_int = 42>> /// suffix: a number

            <<declare $suffix_str = ""Hello"">> /// suffix: a string

            <<declare $suffix_bool = true>> /// suffix: a bool
            
            // No declaration before
            <<declare $none_int = 42>> // No declaration after

            /// Multi-line
            /// doc comment
            <<declare $multiline = 42>>

            ");

    var result = Compiler.compile(CompilationJob.createFromString("input", source, dialogue.library));

    Assert.empty(result.Diagnostics);

    var item = Declaration;
    item.Name = "$prefix_int";
    item.Type = BuiltinTypes.number;
    item.DefaultValue = 42.0;
    item.Description = "prefix: a number";
    var item1 = Declaration;
    item1.Name = "$prefix_str";
    item1.Type = BuiltinTypes.String;
    item1.DefaultValue = "Hello";
    item1.Description = "prefix: a string";
    var item2 = Declaration;
    item2.Name = "$prefix_bool";
    item2.Type = BuiltinTypes.bool;
    item2.DefaultValue = true;
    item2.Description = "prefix: a bool";
    var item3 = Declaration;
    item3.Name = "$suffix_int";
    item3.Type = BuiltinTypes.number;
    item3.DefaultValue = 42.0;
    item3.Description = "suffix: a number";
    var item4 = Declaration;
    item4.Name = "$suffix_str";
    item4.Type = BuiltinTypes.String;
    item4.DefaultValue = "Hello";
    item4.Description = "suffix: a string";
    var item5 = Declaration;
    item5.Name = "$suffix_bool";
    item5.Type = BuiltinTypes.bool;
    item5.DefaultValue = true;
    item5.Description = "suffix: a bool";
    var item6 = Declaration;
    item6.Name = "$none_int";
    item6.Type = BuiltinTypes.number;
    item6.DefaultValue = 42.0;
    item6.Description = null;
    var item7 = Declaration;
    item7.Name = "$multiline";
    item7.Type = BuiltinTypes.number;
    item7.DefaultValue = 42.0;
    item7.Description = "Multi-line doc comment";
    var expectedDeclarations = [item, item1, item2, item3, item4, item5, item6, item7];

    var actualDeclarations = List<Declaration>(result.Declarations);

    assertEquals(expectedDeclarations.count(), actualDeclarations.count());

    for (int i = 0; i < expectedDeclarations.count; i++) {
      Declaration expected = expectedDeclarations[i];
      Declaration actual = actualDeclarations[i];

      assertEquals(expected.Name, actual.Name);
      assertEquals(expected.Type, actual.Type);
      assertEquals(expected.DefaultValue, actual.DefaultValue);
      assertEquals(expected.Description, actual.Description);
    }
  }

  void testTypeConversion() {
    var source = createTestNode("
            string + string(number): {""1"" + string(1)}
            string + string(bool): {""1"" + string(true)}

            number + number(string): {1 + number(""1"")}
            number + number(bool): {1 + number(true)}

            bool and bool(string): {true and bool(""true"")}
            bool and bool(number): {true and bool(1)}
            ");

    testPlan = TestPlanBuilder().addLine("string + string(number): 11").addLine("string + string(bool): 1True").addLine("number + number(string): 2").addLine("number + number(bool): 2").addLine("bool and bool(string): True").addLine("bool and bool(number): True").getPlan();

    var result = Compiler.compile(CompilationJob.createFromString("input", source, dialogue.library));

    Assert.empty(result.Diagnostics);

    dialogue.setProgram(result.Program);
    stringTable = result.StringTable;
    runStandardTestcase();
  }

  void testTypeConversionFailure(String test) {
    var source = createTestNode(test);
    testPlan = TestPlanBuilder().addLine("test failure if seen").getPlan();

    Assert.Throws<FormatException>(() {
      var compilationJob = CompilationJob.createFromString("input", source, dialogue.library);
      var result = Compiler.compile(compilationJob);

      Assert.empty(result.Diagnostics);

      dialogue.setProgram(result.Program);
      stringTable = result.StringTable;

      runStandardTestcase();
     });
  }

  void testImplicitFunctionDeclarations() {
    var source = createTestNode("
            {func_void_bool()}
            {func_void_bool() and bool(func_void_bool())}
            { 1 + func_void_int() }
            { ""he"" + func_void_str() }

            {func_int_bool(1)}
            {true and func_int_bool(1)}

            {func_bool_bool(false)}
            {true and func_bool_bool(false)}

            {func_str_bool(""hello"")}
            {true and func_str_bool(""hello"")}
            ");

    dialogue.library.registerFunction1<TResult>("func_void_bool", () => true);
    dialogue.library.registerFunction1<TResult>("func_void_int", () => 1);
    dialogue.library.registerFunction1<TResult>("func_void_str", () => "llo");

    dialogue.library.registerFunction1<TResult>("func_int_bool", (int i) => true);
    dialogue.library.registerFunction1<TResult>("func_bool_bool", (bool b) => true);
    dialogue.library.registerFunction1<TResult>("func_str_bool", (String s) => true);

    testPlan = TestPlanBuilder().addLine("True").addLine("True").addLine("2").addLine("hello").addLine("True").addLine("True").addLine("True").addLine("True").addLine("True").addLine("True").getPlan();

    // the library is NOT attached to this compilation job; all
    // functions will be implicitly declared
    var compilationJob = CompilationJob.createFromString("input", source);
    var result = Compiler.compile(compilationJob);

    Assert.empty(result.Diagnostics);

    dialogue.setProgram(result.Program);
    stringTable = result.StringTable;

    runStandardTestcase();
  }

  void testImplicitVariableDeclarations(String value, String typeName) {
    var source = createTestNode("
            <<set $v = ${value}>>
            ");

    var result = Compiler.compile(CompilationJob.createFromString("input", source));

    Assert.empty(result.Diagnostics);

    var declarations = result.Declarations.where((d) => d.Name == "$v");

    Assert.collection(declarations, (d) => assertEquals(d.Type.Name, typeName));
  }

  void testNestedImplicitFunctionDeclarations() {
    var source = createTestNode("
            {func_bool_bool(bool(func_int_bool(1)))}
            ");

    dialogue.library.registerFunction1<TResult>("func_int_bool", (int i) => i == 1);
    dialogue.library.registerFunction1<TResult>("func_bool_bool", (bool b) => b);

    testPlan = TestPlanBuilder().addLine("True").getPlan();

    // the library is NOT attached to this compilation job; all
    // functions will be implicitly declared
    var compilationJob = CompilationJob.createFromString("input", source);
    var result = Compiler.compile(compilationJob);

    Assert.empty(result.Diagnostics);

    assertEquals(2, result.Declarations.count());

    // Both declarations that resulted from the compile should be functions found on line 1
    for (var decl in result.Declarations) {
      assertEquals(1, decl.SourceNodeLine);
      assertTrue (decl.Type is FunctionType);
    }

    dialogue.setProgram(result.Program);
    stringTable = result.StringTable;

    runStandardTestcase();
  }

  void testMultipleImplicitRedeclarationsOfFunctionParameterCountFail() {
    var source = createTestNode("
            {func(1)}
            {func(2, 2)} // wrong number of parameters (previous decl had 1)
            ");

    var result = Compiler.compile(CompilationJob.createFromString("input", source));

    Assert.collection(result.Diagnostics, (p) => assertTrue (p.Message.contains("expects 1 parameter, but received 2")));
  }

  void testMultipleImplicitRedeclarationsOfFunctionParameterTypeFail() {
    var source = createTestNode("
            {func(1)}
            {func(true)} // wrong type of parameter (previous decl had number)
            ");

    var result = Compiler.compile(CompilationJob.createFromString("input", source));

    Assert.collection(result.Diagnostics, (p) => assertTrue (p.Message.contains("expects a Number, not a Bool")));
  }

  void testIfStatementExpressionsMustBeBoolean() {
    var source = createTestNode("
            <<declare $str = ""hello"" as string>>
            <<declare $bool = true>>

            <<if $bool>> // ok
            Hello
            <<endif>>

            <<if $str>> // error, must be a bool
            Hello
            <<endif>>
            ");

    var result = Compiler.compile(CompilationJob.createFromString("input", source));

    Assert.collection(result.Diagnostics, (p) => assertTrue (p.Message.contains("Terms of 'if statement' must be Bool, not String")));
  }

  void testBuiltinTypesAreEnumerated() {
    var allBuiltinTypes = BuiltinTypes.Iterable<>;

    Assert.notEmpty(allBuiltinTypes);
  }
}
