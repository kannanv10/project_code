class Greenhouse {
  final String userId;
  final List<GreenhouseDetail> greenhouseDetails;

  Greenhouse({
    required this.userId,
    required this.greenhouseDetails,
  });

  factory Greenhouse.fromJson(Map<String, dynamic> json) {
    return Greenhouse(
      userId: json['userId'],
      greenhouseDetails: (json['greenhouseDetails'] as List)
          .map((detail) => GreenhouseDetail.fromJson(detail))
          .toList(),
    );
  }
}

class GreenhouseDetail {
  final String sensorId;
  final String pan;

  GreenhouseDetail({
    required this.sensorId,
    required this.pan,
  });

  factory GreenhouseDetail.fromJson(Map<String, dynamic> json) {
    return GreenhouseDetail(
      sensorId: json['sensorId'],
      pan: json['PAN'],
    );
  }
}
