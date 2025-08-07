import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

enum TripStatus {
  pending,       // في انتظار قبول السائق
  accepted,      // تم قبول الرحلة
  driverArrived, // وصل السائق
  inProgress,    // جاري التوصيل
  completed,     // مكتملة
  cancelled,     // ملغاة
}

class LocationPoint {
  final double lat;
  final double lng;
  final String address;

  LocationPoint({
    required this.lat,
    required this.lng,
    required this.address,
  });

  LatLng get latLng => LatLng(lat, lng);

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      lat: map['lat']?.toDouble() ?? 0.0,
      lng: map['lng']?.toDouble() ?? 0.0,
      address: map['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'address': address,
    };
  }
}

class TripModel {
  final String id;
  final String riderId;
  final String? driverId;
  final LocationPoint pickupLocation;
  final LocationPoint destinationLocation;
  final TripStatus status;
  final double fare;
  final double distance; // بالكيلومتر
  final int estimatedDuration; // بالدقائق
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;
  final List<LatLng>? routePolyline;

  TripModel({
    required this.id,
    required this.riderId,
    this.driverId,
    required this.pickupLocation,
    required this.destinationLocation,
    this.status = TripStatus.pending,
    required this.fare,
    required this.distance,
    required this.estimatedDuration,
    required this.createdAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.notes,
    this.routePolyline,
  });

  factory TripModel.fromMap(Map<String, dynamic> map) {
    List<LatLng>? polyline;
    if (map['routePolyline'] != null) {
      polyline = (map['routePolyline'] as List)
          .map((point) => LatLng(
                point['lat']?.toDouble() ?? 0.0,
                point['lng']?.toDouble() ?? 0.0,
              ))
          .toList();
    }

    return TripModel(
      id: map['id'] ?? '',
      riderId: map['riderId'] ?? '',
      driverId: map['driverId'],
      pickupLocation: LocationPoint.fromMap(map['pickupLocation'] ?? {}),
      destinationLocation: LocationPoint.fromMap(map['destinationLocation'] ?? {}),
      status: TripStatus.values.firstWhere(
        (e) => e.toString() == 'TripStatus.${map['status']}',
        orElse: () => TripStatus.pending,
      ),
      fare: (map['fare'] ?? 0.0).toDouble(),
      distance: (map['distance'] ?? 0.0).toDouble(),
      estimatedDuration: map['estimatedDuration'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
      startedAt: (map['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      notes: map['notes'],
      routePolyline: polyline,
    );
  }

  Map<String, dynamic> toMap() {
    List<Map<String, double>>? polylineData;
    if (routePolyline != null) {
      polylineData = routePolyline!
          .map((point) => {
                'lat': point.latitude,
                'lng': point.longitude,
              })
          .toList();
    }

    return {
      'id': id,
      'riderId': riderId,
      'driverId': driverId,
      'pickupLocation': pickupLocation.toMap(),
      'destinationLocation': destinationLocation.toMap(),
      'status': status.name,
      'fare': fare,
      'distance': distance,
      'estimatedDuration': estimatedDuration,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'notes': notes,
      'routePolyline': polylineData,
    };
  }

  TripModel copyWith({
    String? id,
    String? riderId,
    String? driverId,
    LocationPoint? pickupLocation,
    LocationPoint? destinationLocation,
    TripStatus? status,
    double? fare,
    double? distance,
    int? estimatedDuration,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? notes,
    List<LatLng>? routePolyline,
  }) {
    return TripModel(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      driverId: driverId ?? this.driverId,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      status: status ?? this.status,
      fare: fare ?? this.fare,
      distance: distance ?? this.distance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      routePolyline: routePolyline ?? this.routePolyline,
    );
  }

  // Helper methods
  bool get isActive => [
        TripStatus.accepted,
        TripStatus.driverArrived,
        TripStatus.inProgress
      ].contains(status);

  bool get isCompleted => [
        TripStatus.completed,
        TripStatus.cancelled
      ].contains(status);

  String get statusText {
    switch (status) {
      case TripStatus.pending:
        return 'في انتظار السائق';
      case TripStatus.accepted:
        return 'تم قبول الرحلة';
      case TripStatus.driverArrived:
        return 'وصل السائق';
      case TripStatus.inProgress:
        return 'جاري التوصيل';
      case TripStatus.completed:
        return 'مكتملة';
      case TripStatus.cancelled:
        return 'ملغاة';
    }
  }
}