import 'package:yarn_spinner.compiler.framework/src/upgrader/upgrade_type.dart';
import 'package:yarn_spinner.compiler.framework/src/upgrader/upgraders/v1to_v2/language_upgrader_v1.dart';

class UpgradeJob {
  List<File> Files;

  UpgradeType UpgradeType = UpgradeType.Version1to2;

  UpgradeJob(UpgradeType upgradeType, Iterable<File> files) {
    this.files = List<File>(files);
    this.upgradeType = upgradeType;
  }
}

class UpgradeResult {
  List<OutputFile> Files;

  Iterable<Diagnostic> get diagnostics => files.selectMany((f) => f.Diagnostics);

  static UpgradeResult merge(UpgradeResult a, UpgradeResult b) {

    // TODO: Anonymous types are not supported
    /*
    new { FileA = first, FileB = second }
    */
    var filePairs = a.files.join(b.files, (first) => first.Path, (second) => second.Path, (first, second) => null);

    var onlyResultA = a.files.where((f1) => b.files.select((f2) => f2.Path).contains(f1.Path) == false);
    var onlyResultB = b.files.where((f1) => a.files.select((f2) => f2.Path).contains(f1.Path) == false);

    var mergedFiles = filePairs.select((pair) => OutputFile.merge(pair.FileA, pair.FileB));

    var allFiles = onlyResultA.concat(onlyResultB).concat(mergedFiles);

    var result = UpgradeResult();
    result.files = allFiles.toList();
    return result;
  }

  class OutputFile {
    String Path;
    Iterable<TextReplacement> Replacements;
    String OriginalSource;
    String UpgradedSource;
    Iterable<Diagnostic> Diagnostics;

    bool IsNewFile = false;

    OutputFile(String path, Iterable<TextReplacement> replacements, String originalSource, [Iterable<Diagnostic> diagnostics = null]) {
      this.path = path;
      this.replacements = replacements;
      this.originalSource = originalSource;
      upgradedSource = LanguageUpgrader.applyReplacements(originalSource, replacements);
      isNewFile = false;
      this.diagnostics = diagnostics ?? List<Diagnostic>();
    }

    OutputFile(String path, String newContent, [Iterable<Diagnostic> diagnostics = null]) {
      this.path = path;
      upgradedSource = newContent;
      originalSource = String.empty;
      replacements = List<TextReplacement>();
      isNewFile = true;
      this.diagnostics = diagnostics ?? List<Diagnostic>();
    }

    static OutputFile merge(OutputFile a, OutputFile b) {
      if (a.path != b.path) {
        throw ArgumentError("Cannot merge ${a.path} and ${b.path}: ${nameof(path)} fields differ");
      }


      if (a.originalSource != b.originalSource) {
        throw ArgumentError("Cannot merge ${a.path} and ${b.path}: ${nameof(originalSource)} fields differ");
      }


      if (a.isNewFile || b.isNewFile) {
        throw ArgumentError("Cannot merge ${a.path} and ${b.path}: one or both of them are new files");
      }


      // Combine and sort the list of replacements
      var mergedReplacements = a.replacements.concat(b.replacements).orderBy((r) => r.StartLine).thenBy((r) => r.Start);

      // Generate a new output file from the result
      return OutputFile(a.path, mergedReplacements, a.originalSource);
    }
  }
}

class TextReplacement {
  int Start = 0;

  int StartLine = 0;

  String OriginalText;

  String ReplacementText;

  String Comment;

  int get originalLength => originalText.length;

  int get replacementLength => replacementText.length;
}

class LanguageUpgrader {
  static UpgradeResult upgrade(UpgradeJob upgradeJob) {
    switch (upgradeJob.UpgradeType) {
      case UpgradeType.version1to2: {
        return LanguageUpgraderV1().upgrade(upgradeJob);
      }
      default: {
        throw ArgumentError("Upgrade type ${upgradeJob.upgradeType} is not supported.");
      }
    }
  }

  static String applyReplacements(String originalText, Iterable<TextReplacement> replacements) {
    // We need this in order of start position because replacements
    // are very likely to change the length the string, which
    // throws off our start points
    var sortedList = replacements.orderBy((r) => r.Start);

    // Use a string builder so that we can hopefully be a bit more
    // efficient about rearranging the string
    var text = StringBuilder(originalText);

    // As we perform replacements, differences between original
    // length and replacement length mean that the "start position"
    // for replacements after the first one will affect the
    // replacement point. This variable keeps track of how much the
    // preceding content has lengthened or shortened as we do our
    // replacements.
    int offset = 0;

    for (var replacement in sortedList) {
      // Ensure that the replacement is for a valid position in
      // the original
      if (replacement.Start > originalText.length) {
        throw ArgumentOutOfRangeException("Replacment's start position (${replacement.Start}) exceeds text length (${originalText.length})");
      }


      // Ensure that the replacement is replacing the text that
      // it expects to (taking into account any previous
      // replacements that may have been made previously by this
      // method)
      var existingSubstring = text.toString(replacement.Start + offset, replacement.OriginalText.Length);

      if (existingSubstring != replacement.OriginalText) {
        throw ArgumentOutOfRangeException("Replacement at position ${replacement.Start} expected to find text ""${replacement.OriginalText}"", but found ""${existingSubstring}"" instead");
      }


      // Perform the replacement!
      text.remove(replacement.Start + offset, replacement.OriginalLength);
      text.insert(replacement.Start + offset, replacement.ReplacementText);

      // This replacement has probably changed the length of the
      // string leading up to here, so update our offset
      var lengthDifference = replacement.ReplacementText.Length - replacement.OriginalText.Length;
      offset += lengthDifference;
    }

    return text.toString();
  }
}
