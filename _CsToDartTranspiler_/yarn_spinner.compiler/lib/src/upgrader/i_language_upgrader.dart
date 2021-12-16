import 'package:yarn_spinner.compiler.framework/src/upgrader/language_upgrader.dart';
abstract class ILanguageUpgrader {
  UpgradeResult upgrade(UpgradeJob upgradeJob);
}
