enum CrowdLevel { low, moderate, high }

class CrowdData {
  final CrowdLevel level;
  final int index;
  final DateTime updatedAt;

  const CrowdData({
    required this.level,
    required this.index,
    required this.updatedAt,
  });

  String get badge {
    switch (level) {
      case CrowdLevel.low:      return '🟢 Quiet today';
      case CrowdLevel.moderate: return '🟡 Moderate';
      case CrowdLevel.high:     return '🔴 Busy today';
    }
  }

  static CrowdLevel classify(int index) {
    if (index >= 70) return CrowdLevel.high;
    if (index >= 40) return CrowdLevel.moderate;
    return CrowdLevel.low;
  }
}
