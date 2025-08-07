import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class LocationService extends GetxService {
  static LocationService get to => Get.find();

  // Current location
  final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  final RxString currentAddress = RxString('');
  
  // Location tracking
  StreamSubscription<Position>? _locationSubscription;
  final RxBool isTrackingLocation = false.obs;
  
  // Location permissions
  final RxBool hasLocationPermission = false.obs;

  Future<LocationService> init() async {
    await _requestLocationPermission();
    if (hasLocationPermission.value) {
      await getCurrentLocation();
    }
    return this;
  }

  /// طلب إذن الموقع
  Future<bool> _requestLocationPermission() async {
    try {
      // فحص حالة الإذن الحالية
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        // إذا كان الإذن مرفوض نهائياً، اطلب من المستخدم فتح الإعدادات
        Get.snackbar(
          'إذن الموقع مطلوب',
          'يرجى تفعيل إذن الموقع من الإعدادات',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
      
      hasLocationPermission.value = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      
      return hasLocationPermission.value;
    } catch (e) {
      print('خطأ في طلب إذن الموقع: $e');
      return false;
    }
  }

  /// الحصول على الموقع الحالي
  Future<LatLng?> getCurrentLocation() async {
    try {
      if (!hasLocationPermission.value) {
        await _requestLocationPermission();
      }
      
      if (!hasLocationPermission.value) return null;
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      LatLng location = LatLng(position.latitude, position.longitude);
      currentLocation.value = location;
      
      // الحصول على العنوان
      await _updateAddressFromLocation(location);
      
      return location;
    } catch (e) {
      print('خطأ في الحصول على الموقع: $e');
      Get.snackbar(
        'خطأ في الموقع',
        'تعذر الحصول على الموقع الحالي',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// تتبع الموقع المباشر (للسائقين)
  void startLocationTracking({
    Function(LatLng)? onLocationUpdate,
    int intervalSeconds = 5,
  }) {
    if (isTrackingLocation.value) return;
    
    isTrackingLocation.value = true;
    
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // تحديث كل 10 متر
        timeLimit: Duration(seconds: intervalSeconds),
      ),
    ).listen((Position position) {
      LatLng location = LatLng(position.latitude, position.longitude);
      currentLocation.value = location;
      
      if (onLocationUpdate != null) {
        onLocationUpdate(location);
      }
    });
  }

  /// إيقاف تتبع الموقع
  void stopLocationTracking() {
    _locationSubscription?.cancel();
    isTrackingLocation.value = false;
  }

  /// البحث عن موقع بالاسم
  Future<List<LocationSearchResult>> searchLocation(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      
      List<Location> locations = await locationFromAddress(
        query,
        localeIdentifier: 'ar_EG',
      );
      
      List<LocationSearchResult> results = [];
      
      for (Location location in locations) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
            localeIdentifier: 'ar_EG',
          );
          
          if (placemarks.isNotEmpty) {
            Placemark placemark = placemarks.first;
            String address = _formatAddress(placemark);
            
            results.add(LocationSearchResult(
              latLng: LatLng(location.latitude, location.longitude),
              address: address,
              name: placemark.name ?? query,
              locality: placemark.locality ?? '',
              country: placemark.country ?? 'مصر',
            ));
          }
        } catch (e) {
          print('خطأ في تحويل الإحداثيات: $e');
        }
      }
      
      return results;
    } catch (e) {
      print('خطأ في البحث عن الموقع: $e');
      return [];
    }
  }

  /// البحث المتقدم باستخدام Nominatim API
  Future<List<LocationSearchResult>> searchLocationAdvanced(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&addressdetails=1'
        '&limit=10'
        '&countrycodes=eg'
        '&accept-language=ar',
      );
      
      final response = await http.get(
        url,
        headers: {'User-Agent': 'TransportApp/1.0'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        return data.map((item) {
          return LocationSearchResult(
            latLng: LatLng(
              double.parse(item['lat']),
              double.parse(item['lon']),
            ),
            address: item['display_name'] ?? query,
            name: item['name'] ?? query,
            locality: item['address']?['city'] ?? item['address']?['town'] ?? '',
            country: item['address']?['country'] ?? 'مصر',
          );
        }).toList();
      }
      
      return [];
    } catch (e) {
      print('خطأ في البحث المتقدم: $e');
      return searchLocation(query); // Fallback to basic search
    }
  }

  /// الحصول على العنوان من الإحداثيات
  Future<String> getAddressFromLocation(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
        localeIdentifier: 'ar_EG',
      );
      
      if (placemarks.isNotEmpty) {
        return _formatAddress(placemarks.first);
      }
      
      return 'موقع غير محدد';
    } catch (e) {
      print('خطأ في الحصول على العنوان: $e');
      return 'موقع غير محدد';
    }
  }

  /// تحديث العنوان الحالي
  Future<void> _updateAddressFromLocation(LatLng location) async {
    String address = await getAddressFromLocation(location);
    currentAddress.value = address;
  }

  /// تنسيق العنوان
  String _formatAddress(Placemark placemark) {
    List<String> addressParts = [];
    
    if (placemark.name != null && placemark.name!.isNotEmpty) {
      addressParts.add(placemark.name!);
    }
    
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      addressParts.add(placemark.street!);
    }
    
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      addressParts.add(placemark.locality!);
    }
    
    if (placemark.administrativeArea != null && 
        placemark.administrativeArea!.isNotEmpty) {
      addressParts.add(placemark.administrativeArea!);
    }
    
    return addressParts.join('، ');
  }

  /// حساب المسافة بين نقطتين
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    ) / 1000; // Convert to kilometers
  }

  /// حساب المدة التقريبية (بناءً على المسافة)
  int estimateDuration(double distanceKm) {
    // افتراض متوسط سرعة 30 كم/ساعة في المدينة
    double hours = distanceKm / 30.0;
    return (hours * 60).round(); // Convert to minutes
  }

  /// الحصول على المسار بين نقطتين
  Future<List<LatLng>> getRoute(LatLng from, LatLng to) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;
          
          return coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
        }
      }
      
      // إذا فشل في الحصول على المسار، أرجع خط مستقيم
      return [from, to];
    } catch (e) {
      print('خطأ في الحصول على المسار: $e');
      return [from, to];
    }
  }

  /// فحص إذا كانت خدمات الموقع مفعلة
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// فتح إعدادات الموقع
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  @override
  void onClose() {
    stopLocationTracking();
    super.onClose();
  }
}

/// نتيجة البحث عن الموقع
class LocationSearchResult {
  final LatLng latLng;
  final String address;
  final String name;
  final String locality;
  final String country;

  LocationSearchResult({
    required this.latLng,
    required this.address,
    required this.name,
    required this.locality,
    required this.country,
  });

  @override
  String toString() => address;
}