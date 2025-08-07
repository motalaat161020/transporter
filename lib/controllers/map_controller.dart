import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
 
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/services/location_service.dart';

class MapController extends GetxController {
  static MapController get to => Get.find();

  // Map controller
  final MapController mapController = MapController();
  
  // Map state
  final Rx<LatLng> mapCenter = LatLng(30.0444, 31.2357).obs; // Cairo default
  final RxDouble mapZoom = 15.0.obs;
  final RxBool isMapReady = false.obs;
  
  // Markers and overlays
  final RxList<Marker> markers = <Marker>[].obs;
  final RxList<Polyline> polylines = <Polyline>[].obs;
  final RxList<CircleMarker> circles = <CircleMarker>[].obs;
  
  // Current location
  final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  final RxString currentAddress = ''.obs;
  
  // Search and location selection
  final RxList<LocationSearchResult> searchResults = <LocationSearchResult>[].obs;
  final Rx<LatLng?> selectedLocation = Rx<LatLng?>(null);
  final RxString selectedAddress = ''.obs;
  final RxBool isSearching = false.obs;
  
  // Trip tracking
  final Rx<TripModel?> activeTrip = Rx<TripModel?>(null);
  final RxList<LatLng> tripRoute = <LatLng>[].obs;
  final Rx<LatLng?> driverLocation = Rx<LatLng?>(null);
  
  // UI state
  final RxBool isLoading = false.obs;
  final TextEditingController searchController = TextEditingController();
  
  // Services
  final LocationService _locationService = LocationService.to;
  
  @override
  void onInit() {
    super.onInit();
    _initializeMap();
    
    // Listen to location updates
    ever(currentLocation, (LatLng? location) {
      if (location != null) {
        _updateCurrentLocationMarker(location);
      }
    });
  }

  /// تهيئة الخريطة
  Future<void> _initializeMap() async {
    isLoading.value = true;
    
    try {
      // الحصول على الموقع الحالي
      LatLng? location = await _locationService.getCurrentLocation();
      
      if (location != null) {
        currentLocation.value = location;
        mapCenter.value = location;
        currentAddress.value = _locationService.currentAddress.value;
        
        // تحريك الخريطة إلى الموقع الحالي
        moveToLocation(location);
      }
      
      isMapReady.value = true;
    } catch (e) {
      print('خطأ في تهيئة الخريطة: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// تحريك الخريطة إلى موقع معين
  void moveToLocation(LatLng location, {double zoom = 16.0}) {
    if (!isMapReady.value) return;
    
    try {
      mapController.moveToLocation(location, zoom: zoom);
      mapCenter.value = location;
      mapZoom.value = zoom;
    } catch (e) {
      print('خطأ في تحريك الخريطة: $e');
    }
  }

  /// البحث عن موقع
  Future<void> searchLocation(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }
    
    isSearching.value = true;
    
    try {
      List<LocationSearchResult> results = 
          await _locationService.searchLocationAdvanced(query);
      
      searchResults.assignAll(results);
    } catch (e) {
      print('خطأ في البحث: $e');
      Get.snackbar(
        'خطأ في البحث',
        'تعذر البحث عن الموقع المطلوب',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSearching.value = false;
    }
  }

  /// تحديد موقع من نتائج البحث
  void selectLocationFromSearch(LocationSearchResult result) {
    selectedLocation.value = result.latLng;
    selectedAddress.value = result.address;
    
    // تحريك الخريطة إلى الموقع المحدد
    moveToLocation(result.latLng);
    
    // إضافة علامة على الموقع المحدد
    _addSelectedLocationMarker(result.latLng, result.name);
    
    // مسح نتائج البحث
    searchResults.clear();
    searchController.clear();
  }

  /// إضافة علامة الموقع الحالي
  void _updateCurrentLocationMarker(LatLng location) {
    // إزالة علامة الموقع الحالي السابقة
    markers.removeWhere((marker) => marker.key == const Key('current_location'));
    
    // إضافة علامة الموقع الحالي الجديدة
    markers.add(
      Marker(
        key: const Key('current_location'),
        point: location,
        width: 40.0,
        height: 40.0,
      //  builder: (ctx) => Container(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.my_location,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// إضافة علامة الموقع المحدد
  void _addSelectedLocationMarker(LatLng location, String title) {
    // إزالة علامة الموقع المحدد السابقة
    markers.removeWhere((marker) => marker.key == const Key('selected_location'));
    
    // إضافة علامة الموقع المحدد الجديدة
    markers.add(
      Marker(
        key: const Key('selected_location'),
        point: location,
        width: 50.0,
        height: 50.0,
        // builder: (ctx) => Column(
child:   Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// إضافة علامة السائق
  void addDriverMarker(LatLng location, DriverModel driver) {
    // إزالة علامة السائق السابقة
    markers.removeWhere((marker) => marker.key == Key('driver_${driver.id}'));
    
    markers.add(
      Marker(
        key: Key('driver_${driver.id}'),
        point: location,
        width: 60.0,
        height: 60.0,
       // builder: (ctx) => Container(
        child:  Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: driver.profileImage != null
              ? ClipOval(
                  child: Image.network(
                    driver.profileImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, color: Colors.white, size: 30);
                    },
                  ),
                )
              : const Icon(Icons.directions_car, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  /// رسم مسار الرحلة
  void drawTripRoute(List<LatLng> routePoints) {
    if (routePoints.isEmpty) return;
    
    // مسح المسارات السابقة
    // Remove previous trip route polyline by checking a custom condition (e.g., color and strokeWidth)
    polylines.removeWhere((polyline) =>
        polyline.color == Colors.blue && polyline.strokeWidth == 4.0);

    // إضافة المسار الجديد
    polylines.add(
      Polyline(
        points: routePoints,
        color: Colors.blue,
        strokeWidth: 4.0,
        // pattern: const StrokePattern.solid(),
      ),
    );
    
    // تعديل حدود الخريطة لتشمل كامل المسار
    _fitBoundsToRoute(routePoints);
  }

  /// تعديل حدود الخريطة لتشمل المسار
  void _fitBoundsToRoute(List<LatLng> points) {
    if (points.isEmpty) return;
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (LatLng point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    
    // إضافة هامش
    double latPadding = (maxLat - minLat) * 0.1;
    double lngPadding = (maxLng - minLng) * 0.1;
    
    LatLngBounds bounds = LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
    
    try {
      mapController._fitBoundsToRoute(points);
      // mapController.fitBounds(
      //   bounds,
      //   options: FitBoundsOptions(
      //     padding: EdgeInsets.all(20),
      //     maxZoom: 18.0,
      //     inside: true,
      //     forceIntegerZoomLevel: true,
      //   ),
      // );
      // mapCenter.value = bounds.center;

    } catch (e) {
      print('خطأ في تعديل حدود الخريطة: $e');
    }
  }

  /// بدء تتبع رحلة
  void startTripTracking(TripModel trip) {
    activeTrip.value = trip;
    
    // رسم مسار الرحلة
    if (trip.routePolyline != null) {
      drawTripRoute(trip.routePolyline!);
    }
    
    // إضافة علامات نقاط البداية والنهاية
    _addTripMarkers(trip);
  }

  /// إضافة علامات الرحلة
  void _addTripMarkers(TripModel trip) {
    // علامة نقطة البداية
    markers.add(
      Marker(
        key: const Key('pickup_location'),
        point: trip.pickupLocation.latLng,
        width: 40.0,
        height: 40.0,
                child:  Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.my_location, color: Colors.white, size: 20),
        ),
      ),
    );
    
    // علامة نقطة الوجهة
    markers.add(
      Marker(
        key: const Key('destination_location'),
        point: trip.destinationLocation.latLng,
        width: 40.0,
        height: 40.0,
                child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  /// تحديث موقع السائق
  void updateDriverLocation(LatLng location) {
    driverLocation.value = location;
    
    // تحديث علامة السائق إذا كانت موجودة
    if (activeTrip.value != null && activeTrip.value!.driverId != null) {
      // سيتم إضافة تفاصيل السائق لاحقاً
    }
  }

  /// مسح الخريطة
  void clearMap() {
    markers.clear();
    polylines.clear();
    circles.clear();
    selectedLocation.value = null;
    selectedAddress.value = '';
    activeTrip.value = null;
    driverLocation.value = null;
  }

  /// تحديث الموقع الحالي
  Future<void> refreshCurrentLocation() async {
    isLoading.value = true;
    
    try {
      LatLng? location = await _locationService.getCurrentLocation();
      
      if (location != null) {
        currentLocation.value = location;
        currentAddress.value = _locationService.currentAddress.value;
        moveToLocation(location);
      }
    } catch (e) {
      print('خطأ في تحديث الموقع: $e');
      Get.snackbar(
        'خطأ',
        'تعذر تحديث الموقع الحالي',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}