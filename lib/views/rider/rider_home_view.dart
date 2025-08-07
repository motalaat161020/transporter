import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/controllers/trip_controller.dart';
 
import 'package:transport_app/models/trip_model.dart';

class RiderHomeView extends StatelessWidget {
  final MapController mapController = Get.find();
  final TripController tripController = Get.find();
  final AuthController authController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الخريطة الرئيسية
          _buildMap(),
          
          // شريط البحث العلوي
          _buildTopSearchBar(context),
          
          // معلومات الرصيد
          _buildBalanceCard(),
          
          // أزرار التحكم الجانبية
          _buildSideControls(),
          
          // بطاقة طلب الرحلة السفلية
          _buildBottomTripCard(),
          
          // نتائج البحث
          Obx(() => mapController.searchResults.isNotEmpty 
              ? _buildSearchResults() 
              : const SizedBox.shrink()),
          
          // شاشة التحميل
          Obx(() => mapController.isLoading.value 
              ? _buildLoadingOverlay() 
              : const SizedBox.shrink()),
        ],
      ),
      drawer: _buildDrawer(),
    );
  }

  /// الخريطة الرئيسية
  Widget _buildMap() {
    return Obx(() => FlutterMap(
      mapController: mapController.mapController,
      options: MapOptions(
        initialCenter: mapController.mapCenter.value,
        initialZoom: mapController.mapZoom.value,
        minZoom: 5.0,
        maxZoom: 18.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: (tapPosition, point) => _onMapTap(point),
      ),
      children: [
        // طبقة الخريطة
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.transport_app',
          maxZoom: 19,
        ),
        
        // الدوائر
        CircleLayer(circles: mapController.circles),
        
        // الخطوط
        PolylineLayer(polylines: mapController.polylines),
        
        // العلامات
        MarkerLayer(markers: mapController.markers),
      ],
    ));
  }

  /// شريط البحث العلوي
  Widget _buildTopSearchBar(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // زر القائمة
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            
            // مربع البحث
            Expanded(
              child: TextField(
                controller: mapController.searchController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  hintText: 'ابحث عن موقع...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    mapController.searchLocation(value);
                  } else {
                    mapController.searchResults.clear();
                  }
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    mapController.searchLocation(value);
                  }
                },
              ),
            ),
            
            // زر البحث
            Obx(() => mapController.isSearching.value
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      String query = mapController.searchController.text;
                      if (query.isNotEmpty) {
                        mapController.searchLocation(query);
                      }
                    },
                  )),
          ],
        ),
      ),
    );
  }

  /// بطاقة الرصيد
  Widget _buildBalanceCard() {
    return Positioned(
      top: MediaQuery.of(Get.context!).padding.top + 80,
      right: 16,
      child: Obx(() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.RIDER_WALLET),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${authController.currentUser.value?.balance.toStringAsFixed(2) ?? '0.00'} ج.م',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  /// أزرار التحكم الجانبية
  Widget _buildSideControls() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(Get.context!).size.height / 2 - 100,
      child: Column(
        children: [
          // زر الموقع الحالي
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.my_location, color: Colors.blue),
              onPressed: () => mapController.refreshCurrentLocation(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // زر التكبير
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.zoom_in, color: Colors.grey),
              onPressed: () {
                double newZoom = mapController.mapZoom.value + 1;
                if (newZoom <= 18) {
                  mapController.mapController.move(
                    mapController.mapCenter.value, 
                    newZoom,
                  );
                  mapController.mapZoom.value = newZoom;
                }
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // زر التصغير
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.zoom_out, color: Colors.grey),
              onPressed: () {
                double newZoom = mapController.mapZoom.value - 1;
                if (newZoom >= 5) {
                  mapController.mapController.move(
                    mapController.mapCenter.value, 
                    newZoom,
                  );
                  mapController.mapZoom.value = newZoom;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة طلب الرحلة السفلية
  Widget _buildBottomTripCard() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Obx(() {
        if (tripController.hasActiveTrip.value) {
          return _buildActiveTripCard();
        } else {
          return _buildRequestTripCard();
        }
      }),
    );
  }

  /// بطاقة طلب رحلة جديدة
  Widget _buildRequestTripCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // الموقع الحالي
          Obx(() => _buildLocationItem(
            icon: Icons.my_location,
            color: Colors.green,
            title: 'من',
            address: mapController.currentAddress.value.isNotEmpty 
                ? mapController.currentAddress.value 
                : 'الموقع الحالي',
          )),
          
          const Divider(height: 32),
          
          // الوجهة
          Obx(() => _buildLocationItem(
            icon: Icons.location_on,
            color: Colors.red,
            title: 'إلى',
            address: mapController.selectedAddress.value.isNotEmpty 
                ? mapController.selectedAddress.value 
                : 'اختر الوجهة',
            onTap: () => _showDestinationBottomSheet(),
          )),
          
          const SizedBox(height: 20),
          
          // زر طلب الرحلة
          Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: mapController.selectedLocation.value != null 
                  ? _requestTrip 
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'طلب رحلة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          )),
        ],
      ),
    );
  }

  /// بطاقة الرحلة النشطة
  Widget _buildActiveTripCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Obx(() {
        final trip = tripController.activeTrip.value;
        if (trip == null) return const SizedBox.shrink();
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // حالة الرحلة
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _getTripStatusColor(trip.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trip.statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _getTripStatusColor(trip.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // معلومات الرحلة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTripInfo(
                  icon: Icons.access_time,
                  label: 'المدة',
                  value: '${trip.estimatedDuration} دقيقة',
                ),
                _buildTripInfo(
                  icon: Icons.straighten,
                  label: 'المسافة',
                  value: '${trip.distance.toStringAsFixed(1)} كم',
                ),
                _buildTripInfo(
                  icon: Icons.attach_money,
                  label: 'التكلفة',
                  value: '${trip.fare.toStringAsFixed(2)} ج.م',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // أزرار التحكم
            Row(
              children: [
                if (trip.status == TripStatus.pending) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => tripController.cancelTrip(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('إلغاء الرحلة'),
                    ),
                  ),
                ],
                
                if (trip.status != TripStatus.pending) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.toNamed(AppRoutes.RIDER_TRIP_TRACKING),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('تتبع الرحلة'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      }),
    );
  }

  /// عنصر الموقع
  Widget _buildLocationItem({
    required IconData icon,
    required Color color,
    required String title,
    required String address,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.edit, color: Colors.grey[400], size: 16),
        ],
      ),
    );
  }

  /// معلومات الرحلة
  Widget _buildTripInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// نتائج البحث
  Widget _buildSearchResults() {
    return Positioned(
      top: MediaQuery.of(Get.context!).padding.top + 80,
      left: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Obx(() => ListView.builder(
          shrinkWrap: true,
          itemCount: mapController.searchResults.length,
          itemBuilder: (context, index) {
            final result = mapController.searchResults[index];
            return ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: Text(
                result.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                result.address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => mapController.selectLocationFromSearch(result),
            );
          },
        )),
      ),
    );
  }

  /// شاشة التحميل
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// القائمة الجانبية
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: authController.currentUser.value?.profileImage != null
                      ? NetworkImage(authController.currentUser.value!.profileImage!)
                      : null,
                  child: authController.currentUser.value?.profileImage == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  authController.currentUser.value?.name ?? 'مستخدم',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  authController.currentUser.value?.phone ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            )),
          ),
          
          _buildDrawerItem(
            icon: Icons.account_balance_wallet,
            title: 'المحفظة',
            onTap: () => Get.toNamed(AppRoutes.RIDER_WALLET),
          ),
          
          _buildDrawerItem(
            icon: Icons.history,
            title: 'تاريخ الرحلات',
            onTap: () => Get.toNamed(AppRoutes.RIDER_TRIP_HISTORY),
          ),
          
          _buildDrawerItem(
            icon: Icons.person,
            title: 'الملف الشخصي',
            onTap: () => Get.toNamed(AppRoutes.RIDER_PROFILE),
          ),
          
          _buildDrawerItem(
            icon: Icons.notifications,
            title: 'الإشعارات',
            onTap: () => Get.toNamed(AppRoutes.RIDER_NOTIFICATIONS),
          ),
          
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'الإعدادات',
            onTap: () => Get.toNamed(AppRoutes.RIDER_SETTINGS),
          ),
          
          _buildDrawerItem(
            icon: Icons.info,
            title: 'عن التطبيق',
            onTap: () => Get.toNamed(AppRoutes.RIDER_ABOUT),
          ),
          
          const Divider(),
          
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            onTap: () => authController.signOut(),
          ),
        ],
      ),
    );
  }

  /// عنصر القائمة الجانبية
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Get.back();
        onTap();
      },
    );
  }

  /// معالج النقر على الخريطة
  void _onMapTap(LatLng point) {
    mapController.selectedLocation.value = point;
    mapController._addSelectedLocationMarker(point, 'الموقع المحدد');
    
    // الحصول على العنوان
    LocationService.to.getAddressFromLocation(point).then((address) {
      mapController.selectedAddress.value = address;
    });
  }

  /// عرض قائمة اختيار الوجهة
  void _showDestinationBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر الوجهة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              autofocus: true,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                hintText: 'ابحث عن الوجهة...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => mapController.searchLocation(value),
            ),
            const SizedBox(height: 16),
            Obx(() => Expanded(
              child: ListView.builder(
                itemCount: mapController.searchResults.length,
                itemBuilder: (context, index) {
                  final result = mapController.searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(result.name),
                    subtitle: Text(result.address),
                    onTap: () {
                      mapController.selectLocationFromSearch(result);
                      Get.back();
                    },
                  );
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// طلب رحلة جديدة
  void _requestTrip() {
    if (mapController.currentLocation.value == null ||
        mapController.selectedLocation.value == null) {
      Get.snackbar(
        'خطأ',
        'يرجى تحديد نقطة البداية والوجهة',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    tripController.requestTrip(
      pickup: LocationPoint(
        lat: mapController.currentLocation.value!.latitude,
        lng: mapController.currentLocation.value!.longitude,
        address: mapController.currentAddress.value,
      ),
      destination: LocationPoint(
        lat: mapController.selectedLocation.value!.latitude,
        lng: mapController.selectedLocation.value!.longitude,
        address: mapController.selectedAddress.value,
      ),
    );
  }

  /// الحصول على لون حالة الرحلة
  Color _getTripStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return Colors.orange;
      case TripStatus.accepted:
        return Colors.blue;
      case TripStatus.driverArrived:
        return Colors.green;
      case TripStatus.inProgress:
        return Colors.purple;
      case TripStatus.completed:
        return Colors.green;
      case TripStatus.cancelled:
        return Colors.red;
    }
  }
}