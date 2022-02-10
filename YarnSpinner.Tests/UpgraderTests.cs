using Xunit;
using System;
using System.IO;
using Yarn.Compiler.Upgrader;
using Yarn.Compiler;
using System.Linq;

namespace YarnSpinner.Tests
{

    public class UpgraderTests : TestBase
    {

        // Test every file in Tests/TestCases
        [Theory]
        [MemberData(nameof(DirectorySources), "Upgrader/V1toV2")]
        public void TestUpgradingV1toV2(string directory)
        {

            Console.ForegroundColor = ConsoleColor.Blue;
            Console.WriteLine($"INFO: Loading file {directory}");

            storage.Clear();

            directory = Path.Combine(TestBase.TestDataPath, directory);

            var allInputYarnFiles = Directory.EnumerateFiles(directory)
                .Where(path => path.EndsWith(".yarn"))
                .Where(path => path.Contains(".upgraded.") == false);

            var expectedOutputFiles = Directory.EnumerateFiles(directory)
                .Where(path => path.Contains(".upgraded."));

            var testPlanPath = Directory.EnumerateFiles(directory)
                .Where(path => path.EndsWith(".testplan"))
                .FirstOrDefault();

            var upgradeJob = new UpgradeJob(
                UpgradeType.Version1to2,
                allInputYarnFiles.Select(path => new CompilationJob.File { 
                    FileName = path, 
                    Source = File.ReadAllText(path) 
                }));
            
            var upgradeResult = LanguageUpgrader.Upgrade(upgradeJob);

            // The upgrade result should produce as many files as there are
            // expected output files
            Assert.Equal(expectedOutputFiles.Count(), upgradeResult.Files.Count());
            
            // For each file produced by the upgrade job, its content
            // should match that of the corresponding expected output
            foreach (var outputFile in upgradeResult.Files) {
                string extension = Path.GetExtension(outputFile.Path);
                var expectedOutputFilePath = Path.ChangeExtension(outputFile.Path, ".upgraded" + extension);

                if (expectedOutputFiles.Contains(expectedOutputFilePath) == false) {
                    // This test case doesn't expect this output (perhaps
                    // it's a test case that isn't expected to succeed.) Ignore it.
                    continue;
                }

                Assert.True(File.Exists(expectedOutputFilePath), $"Expected file {expectedOutputFilePath} to exist");

                var expectedOutputFileContents = File.ReadAllText(expectedOutputFilePath);

                var upgradedContents = outputFile.UpgradedSource.Replace("\r\n", "\n");

                Assert.Equal(expectedOutputFileContents, upgradedContents);
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

            var result = Compiler.Compile(CompilationJob.CreateFromFiles(expectedOutputFiles) );

            Assert.Empty(result.Diagnostics);
            
            stringTable = result.StringTable;

            // Execute the program and verify thats output matches the test
            // plan
            dialogue.SetProgram(result.Program);

            // Load the test plan
            LoadTestPlan(testPlanPath);            

            // If this file contains a Start node, run the test case
            // (otherwise, we're just testing its parsability, which we did
            // in the last line)
            if (dialogue.NodeExists("Start"))
            {
                RunStandardTestcase();
            }
        }

        [Fact]
        public void TestTextReplacement()
        {
            var text = "Keep delete keep\nreplace keep";
            var expectedReplacement = "Keep keep\nnew keep add";

            var replacements = new[] {
                new TextReplacement() {
                    Start = 5,
                    OriginalText = "delete ",
                    ReplacementText = "",
                },
                new TextReplacement() {
                    Start = 17,
                    OriginalText = "replace",
                    ReplacementText = "new",
                },     
                new TextReplacement() {
                    Start = 29,
                    OriginalText = "",
                    ReplacementText = " add",
                }           
            };

            var replacedText = LanguageUpgrader.ApplyReplacements(text, replacements);

            Assert.Equal(expectedReplacement, replacedText);
        }

        [Fact]
        public void TestInvalidReplacementThrows()
        {
            var text = "Keep keep";
            
            var replacements = new[] {
                new TextReplacement() {
                    Start = 5,
                    OriginalText = "delete ", // the replacement expects to see  "delete " here, but it will see "keep" instead
                    ReplacementText = ""
                },                
            };

            Assert.Throws<ArgumentOutOfRangeException>(() => LanguageUpgrader.ApplyReplacements(text, replacements));
        }

        [Fact]
        public void TestOutOfRangeReplacementThrows()
        {
            var text = "Test";
            
            var replacements = new[] {
                new TextReplacement() {
                    Start = 8, // This replacement starts outside the text's length
                    OriginalText = "Test", 
                    ReplacementText = ""
                },                
            };

            Assert.Throws<ArgumentOutOfRangeException>(() => LanguageUpgrader.ApplyReplacements(text, replacements));
        }
    }
}
