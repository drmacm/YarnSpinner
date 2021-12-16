import 'package:yarn_spinner.framework.tests/src/test_base.dart';

class UpgraderTests extends TestBase {

  // Test every file in Tests/TestCases
  void testUpgradingV1toV2(String directory) {

    Console.foregroundColor = ConsoleColor.blue;
    print("INFO: Loading file ${directory}");

    storage.clear();

    directory = Path.combine(TestBase.testDataPath, directory);

    var allInputYarnFiles = Directory.enumerateFiles(directory).where((path) => path.endsWith(".yarn")).where((path) => path.contains(".upgraded.") == false);

    var expectedOutputFiles = Directory.enumerateFiles(directory).where((path) => path.contains(".upgraded."));

    var testPlanPath = Directory.enumerateFiles(directory).where((path) => path.endsWith(".testplan")).firstOrDefault();

    var upgradeJob = UpgradeJob(UpgradeType.Version1to2, allInputYarnFiles.select((path) => File;
    upgradeJob.FileName = path;
    upgradeJob.Source = File.readAllText(path)));

    var upgradeResult = LanguageUpgrader.upgrade(upgradeJob);

    // The upgrade result should produce as many files as there are
    // expected output files
    assertEquals(expectedOutputFiles.count(), upgradeResult.Files.count());

    // For each file produced by the upgrade job, its content
    // should match that of the corresponding expected output
    for (var outputFile in upgradeResult.Files) {
      String extension = Path.getExtension(outputFile.Path);
      var expectedOutputFilePath = Path.changeExtension(outputFile.Path, ".upgraded" + extension);

      if (expectedOutputFiles.contains(expectedOutputFilePath) == false) {
        // This test case doesn't expect this output (perhaps
        // it's a test case that isn't expected to succeed.) Ignore it.
        continue
      }


      assertTrue(File.exists(expectedOutputFilePath), "Expected file ${expectedOutputFilePath} to exist");

      var expectedOutputFileContents = File.readAllText(expectedOutputFilePath);

      var upgradedContents = outputFile.UpgradedSource.replace("\r\n", "\n");

      assertEquals(expectedOutputFileContents, upgradedContents);
    }

    // If the test case doesn't contain a test plan file, it's not
    // expected to compile successfully, so don't do it. Instead,
    // we'll rely on the fact that the upgraded contents are what
    // we expected.
    if (testPlanPath == null) {
      // Don't compile; just succeed here.
      return;
    }


    // While we're here, correctness-check the upgraded source. (To
    // be strictly correct, we're using the files on disk, not the
    // generated source, but we just demonstrated that they're
    // identical, so that's fine! Saves us having to write them to
    // a temporary location.)

    var result = Compiler.compile(CompilationJob.createFromFiles(expectedOutputFiles));

    Assert.empty(result.Diagnostics);

    stringTable = result.StringTable;

    // Execute the program and verify thats output matches the test
    // plan
    dialogue.setProgram(result.Program);

    // Load the test plan
    loadTestPlan(testPlanPath);

    // If this file contains a Start node, run the test case
    // (otherwise, we're just testing its parsability, which we did
    // in the last line)
    if (dialogue.nodeExists("Start")) {
      runStandardTestcase();
    }

  }

  void testTextReplacement() {
    var text = "Keep delete keep\nreplace keep";
    var expectedReplacement = "Keep keep\nnew keep add";

    var item = TextReplacement();
    item.Start = 5;
    item.OriginalText = "delete ";
    item.ReplacementText = "";
    var item1 = TextReplacement();
    item1.Start = 17;
    item1.OriginalText = "replace";
    item1.ReplacementText = "new";
    var item2 = TextReplacement();
    item2.Start = 29;
    item2.OriginalText = "";
    item2.ReplacementText = " add";
    var replacements = [item, item1, item2];

    var replacedText = LanguageUpgrader.applyReplacements(text, replacements);

    assertEquals(expectedReplacement, replacedText);
  }

  void testInvalidReplacementThrows() {
    var text = "Keep keep";

    var item = TextReplacement();
    item.Start = 5;
    item.OriginalText = "delete ";
    item.ReplacementText = "";
    var replacements = [item];

    Assert.Throws<ArgumentOutOfRangeException>(() => LanguageUpgrader.applyReplacements(text, replacements));
  }

  void testOutOfRangeReplacementThrows() {
    var text = "Test";

    var item = TextReplacement();
    item.Start = 8;
    item.OriginalText = "Test";
    item.ReplacementText = "";
    var replacements = [item];

    Assert.Throws<ArgumentOutOfRangeException>(() => LanguageUpgrader.applyReplacements(text, replacements));
  }
}
