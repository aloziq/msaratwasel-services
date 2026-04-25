class TripHistoryModel {
  final int id;
  final String type;
  final String typeLabel;
  final String status;
  final String tripDate;
  final int totalStudents;
  final String? departureTime;
  final String? arrivalTime;
  final RouteModel? route;

  TripHistoryModel({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.status,
    required this.tripDate,
    required this.totalStudents,
    this.departureTime,
    this.arrivalTime,
    this.route,
  });

  factory TripHistoryModel.fromJson(Map<String, dynamic> json) =>
      TripHistoryModel(
        id: json['id'] as int,
        type: json['type'] as String,
        typeLabel: json['type_label'] as String,
        status: json['status'] as String,
        tripDate: json['trip_date'] as String,
        totalStudents: json['total_students'] as int,
        departureTime: json['departure_time'] as String?,
        arrivalTime: json['arrival_time'] as String?,
        route: json['route'] == null
            ? null
            : RouteModel.fromJson(json['route'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'type_label': typeLabel,
    'status': status,
    'trip_date': tripDate,
    'total_students': totalStudents,
    'departure_time': departureTime,
    'arrival_time': arrivalTime,
    'route': route?.toJson(),
  };
}

class RouteModel {
  final int id;
  final String name;

  RouteModel({required this.id, required this.name});

  factory RouteModel.fromJson(Map<String, dynamic> json) =>
      RouteModel(id: json['id'] as int, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class TripHistoryResponse {
  final List<TripHistoryModel> trips;
  final PaginationModel pagination;
  final FiltersModel filters;

  TripHistoryResponse({
    required this.trips,
    required this.pagination,
    required this.filters,
  });

  factory TripHistoryResponse.fromJson(Map<String, dynamic> json) =>
      TripHistoryResponse(
        trips: (json['trips'] as List<dynamic>)
            .map((e) => TripHistoryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        pagination: PaginationModel.fromJson(
          json['pagination'] as Map<String, dynamic>,
        ),
        filters: FiltersModel.fromJson(json['filters'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
    'trips': trips.map((e) => e.toJson()).toList(),
    'pagination': pagination.toJson(),
    'filters': filters.toJson(),
  };
}

class PaginationModel {
  final int currentPage;
  final int lastPage;
  final int total;

  PaginationModel({
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) =>
      PaginationModel(
        currentPage: json['current_page'] as int,
        lastPage: json['last_page'] as int,
        total: json['total'] as int,
      );

  Map<String, dynamic> toJson() => {
    'current_page': currentPage,
    'last_page': lastPage,
    'total': total,
  };
}

class FiltersModel {
  final String startDate;
  final String endDate;
  final String? status;

  FiltersModel({required this.startDate, required this.endDate, this.status});

  factory FiltersModel.fromJson(Map<String, dynamic> json) => FiltersModel(
    startDate: json['start_date'] as String,
    endDate: json['end_date'] as String,
    status: json['status'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'start_date': startDate,
    'end_date': endDate,
    'status': status,
  };
}
