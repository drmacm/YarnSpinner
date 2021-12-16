
class UpgradeType {
  final int value;
  final String name;
  const UpgradeType._(this.value, this.name);

  static const version1to2 = const UpgradeType._(0, 'version1to2');

  static const List<UpgradeType> values = [
    version1to2,
  ];

  @override
  String toString() => 'UpgradeType' + '.' + name;

}
