import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/models/trip_model.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/services/location_service.dart';

class TripController extends GetxController {
  static TripController get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Current trip state
  final Rx<TripModel?> activeTrip = Rx<TripModel?>(null);
  final RxBool hasActiveTrip = false.obs;
  final RxBool isRequestingTrip = false.obs;
  
  // Trip history
  final RxList<TripModel> tripHistory = <TripModel>[].obs;
  final RxBool isLoadingHistory = false.obs;
  
  // Available drivers
  final RxList<DriverModel> availableDrivers = <DriverModel>[].obs;
  
  // Real-time updates
  StreamSubscription<DocumentSnapshot>? _tripStreamSubscription;
  StreamSubscription<QuerySnapshot>? _driversStreamSubscription;
  
  // Controllers
  final AuthController authController = AuthController.to;
  final LocationService locationService = LocationService.to;
  
  @override
  void onInit() {
    super.onInit();
    _initializeTripController();
  }

  /// تهيئة متحكم الرحلات
  void _initializeTripController() {
    // تحقق من وجود رحلة نشطة عند فتح التطبيق
    _checkActiveTrip();
    
    // الاستماع للسائقين المتاحين
    _listenToAvailableDrivers();
    
    // تحديث حالة الرحلة النشطة
    ever(activeTrip, (TripModel? trip) {
      hasActiveTrip.value = trip != null && trip.isActive;
      
      if (trip != null && trip.isActive) {
        _startTripTracking(trip);
      }
    });
  }

  /// طلب رحلة جديدة
  Future<void> requestTrip({
    required LocationPoint pickup,
    required LocationPoint destination,
  }) async {
    if (isRequestingTrip.value) return;
    
    try {
      isRequestingTrip.value = true;
      
      // التحقق من الرصيد
      final user = authController.currentUser.value;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }
      
      // حساب المسافة والتكلفة
      double distance = locationService.calculateDistance(
        pickup.latLng, 
        destination.latLng,
      );
      
      int estimatedDuration = locationService.estimateDuration(distance);
      double fare = _calculateFare(distance);
      
      // التحقق من كفاية الرصيد
      if (user.balance < fare) {
        Get.snackbar(
          'رصيد غير كافي',
          'يرجى شحن المحفظة أولاً',
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.toNamed(AppRoutes.RIDER_ADD_BALANCE);
        return;
      }
      
      // الحصول على مسار الرحلة
      List<LatLng> routePoints = await locationService.getRoute(
        pickup.latLng, 
        destination.latLng,
      );
      
      // إنشاء الرحلة
      String tripId = _firestore.collection('trips').doc().id;
      
      TripModel newTrip = TripModel(
        id: tripId,
        riderId: user.id,
        pickupLocation: pickup,
        destinationLocation: destination,
        fare: fare,
        distance: distance,
        estimatedDuration: estimatedDuration,
        createdAt: DateTime.now(),
        routePolyline: routePoints,
      );
      
      // حفظ الرحلة في قاعدة البيانات
      await _firestore
          .collection('trips')
          .doc(tripId)
          .set(newTrip.toMap());
      
      // تحديث الحالة المحلية
      activeTrip.value = newTrip;
      
      // بدء الاستماع لتحديثات الرحلة
      _listenToTripUpdates(tripId);
      
      // إشعار السائقين المتاحين
      await _notifyAvailableDrivers(newTrip);
      
      // إظهار رسالة نجاح
      Get.snackbar(
        'تم طلب الرحلة',
        'يتم البحث عن سائق متاح...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      // بدء عداد زمني لإلغاء الرحلة تلقائياً إذا لم يتم قبولها
      _startTripTimeoutTimer(newTrip);
      
    } catch (e) {
      print('خطأ في طلب الرحلة: $e');
      Get.snackbar(
        'خطأ',
        'تعذر طلب الرحلة، يرجى المحاولة مرة أخرى',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isRequestingTrip.value = false;
    }
  }

  /// إلغاء الرحلة
  Future<void> cancelTrip() async {
    final trip = activeTrip.value;
    if (trip == null) return;
    
    try {
      // يمكن إلغاء الرحلة فقط إذا كانت في حالة الانتظار
      if (trip.status != TripStatus.pending) {
        Get.snackbar(
          'لا يمكن الإلغاء',
          'لا يمكن إلغاء الرحلة في هذه المرحلة',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      
      // تحديث حالة الرحلة إلى ملغاة
      await _firestore
          .collection('trips')
          .doc(trip.id)
          .update({
        'status': TripStatus.cancelled.name,
        'completedAt': Timestamp.now(),
      });
      
      // مسح الحالة المحلية
      _clearActiveTrip();
      
      Get.snackbar(
        'تم الإلغاء',
        'تم إلغاء الرحلة بنجاح',
          snackPosition: SnackPosition.BOTTOM,
      ), 
    } catch (e) {
      print('خطأ في إلغاء الرحلة: $e');
      Get.snackbar(
        'خطأ',
        'تعذر إلغاء الرحلة، يرجى المحاولة مرة أخرى', 
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  } 



}