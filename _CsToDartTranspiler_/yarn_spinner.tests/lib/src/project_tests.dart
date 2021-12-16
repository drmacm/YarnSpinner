import 'package:yarn_spinner.framework.tests/src/test_base.dart';


class ProjectTests extends TestBase {

  void testLoadingNodes() {
    var path = Path.combine(testDataPath, "Projects", "Basic", "Test.yarn");

    var result = Compiler.compile(CompilationJob.createFromFiles(path));

    Assert.empty(result.Diagnostics);

    dialogue.setProgram(result.Program);
    stringTable = result.StringTable;

    // high-level test: load the file, verify it has the nodes we want,
    // and run one

    assertEquals(3, dialogue.nodeNames.count());

    assertTrue(dialogue.nodeExists("TestNode"));
    assertTrue(dialogue.nodeExists("AnotherTestNode"));
    assertTrue(dialogue.nodeExists("ThirdNode"));
  }

  void testDeclarationFilesAreGenerated() {
    // Parsing a file that contains variable declarations should be
    // able to turned back into a string containing the same
    // information.

    var originalText = "title: Program
tags: one two
custom: yes
---
/// str desc
<<declare $str = ""str"">>

/// num desc
<<declare $num = 2>>

/// bool desc
<<declare $bool = true>>
===
";

    var job = CompilationJob.createFromString("input", originalText);

    var result = Compiler.compile(job);

    Assert.empty(result.Diagnostics);

    var headers = {"custom": "yes"};
    List<String> tags = ["one", "two"];

    var generatedOutput = Utility.generateYarnFileWithDeclarations(result.Declarations, "Program", tags, headers);

    generatedOutput = generatedOutput.replace("\r\n", "\n");

    assertEquals(originalText, generatedOutput);
  }

  void testLineTagsAreAdded() {
    // Arrange
    var originalText = "title: Program
---
// A comment. No line tag is added.
A single line, with no line tag.
A single line, with a line tag. #line:expected_abc123

-> An option, with no line tag.
-> An option, with a line tag. #line:expected_def456

A line with no tag, but a comment at the end. // a comment
A line with a tag, and a comment. #line:expected_ghi789 // a comment

// A comment with no text:
//
// A comment with a single space:
// 

===";

    // Act
    var output = Utility.addTagsToLines(originalText);

    var compilationJob = CompilationJob.createFromString("input", output);
    compilationJob.CompilationType = CompilationJob.Type.StringsOnly;

    var compilationResult = Compiler.compile(compilationJob);

    Assert.empty(compilationResult.Diagnostics);

    // Assert
    var lineTagRegex = Regex("#line:\w+");

    var lineTagAfterComment = Regex("\/\/.*#line:\w+");

    // Ensure that the right number of tags in total is present
    var expectedExistingTags = 3;
    var expectedNewTags = 3;
    var expectedTotalTags = expectedExistingTags + expectedNewTags;

    assertEquals(expectedTotalTags, lineTagRegex.matches(output).Count);

    // No tags were added after a comment
    for (var line in output.split('\n')) {
      assertFalse(lineTagAfterComment.isMatch(line), "'${line}' should not contain a tag after a comment");
    }


    var expectedResults = List<ValueTuple<String, String>>();

    for (var result in expectedResults) {
      if (result.tag != null) {
        assertEquals(compilationResult.StringTable[result.tag].text, result.line);
      }
      else {
        // a line exists that has this text
        var matchingEntries = compilationResult.StringTable.where((s) => s.Value.text == result.line);
        Assert.single(matchingEntries);

        // that line has a line tag
        var lineTag = matchingEntries.first().Key;
        Assert.startsWith("line:", lineTag);

        // that line is not a duplicate of any other line tag
        var allLineTags = compilationResult.StringTable.Keys;
        assertEquals(1, allLineTags.count((t) => t == lineTag));
      }
    }
  }
}
