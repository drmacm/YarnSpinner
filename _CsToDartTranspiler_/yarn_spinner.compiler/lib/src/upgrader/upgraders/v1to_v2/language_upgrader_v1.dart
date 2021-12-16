import 'package:yarn_spinner.compiler.framework/src/upgrader/i_language_upgrader.dart';
import 'package:yarn_spinner.compiler.framework/src/upgrader/language_upgrader.dart';
import 'package:yarn_spinner.compiler.framework/src/upgrader/upgraders/v1to_v2/format_function_upgrader.dart';
import 'package:yarn_spinner.compiler.framework/src/upgrader/upgraders/v1to_v2/options_upgrader.dart';
import 'package:yarn_spinner.compiler.framework/src/upgrader/upgraders/v1to_v2/variable_declaration_upgrader.dart';
class LanguageUpgraderV1 implements ILanguageUpgrader {

  @override
  UpgradeResult upgrade(UpgradeJob upgradeJob) {
    var results = [FormatFunctionUpgrader().upgrade(upgradeJob), VariableDeclarationUpgrader().upgrade(upgradeJob), OptionsUpgrader().upgrade(upgradeJob)];

    return results.aggregate((result, next) => UpgradeResult.merge(result, next));
  }
}
