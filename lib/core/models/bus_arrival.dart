class BusArrival {
  final String routeNo;
  final String destination;
  final int arrivalMinutes;
  final int remainingStops;
  final bool isLongWait;

  const BusArrival({
    required this.routeNo,
    required this.destination,
    required this.arrivalMinutes,
    required this.remainingStops,
    required this.isLongWait,
  });

  factory BusArrival.fromApi(Map<String, dynamic> item) {
    final seconds = int.tryParse(item['arrtime']?.toString() ?? '') ?? 0;
    final mins = (seconds / 60).round();
    return BusArrival(
      routeNo: item['routeno']?.toString() ?? '-',
      destination: item['nodenm']?.toString() ?? '-',
      arrivalMinutes: mins,
      remainingStops:
          int.tryParse(item['arrprevstationcnt']?.toString() ?? '') ?? 0,
      isLongWait: mins > 30,
    );
  }
}

class RouteInfo {
  final String routeId;
  final String routeNo;
  final String startStop;
  final String endStop;

  const RouteInfo({
    required this.routeId,
    required this.routeNo,
    required this.startStop,
    required this.endStop,
  });

  String get direction => '$startStop -> $endStop';
}
