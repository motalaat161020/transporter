import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:transport_app/routes/app_pages.dart';
import 'package:transport_app/routes/app_routes.dart';
import 'package:transport_app/services/location_service.dart';
 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Firebase
  await Firebase.initializeApp();
  
  // تهيئة الخدمات
  await initServices();
  
  runApp(MyApp());
}

Future<void> initServices() async {
  // تهيئة الخدمات الأساسية
  await Get.putAsync(() => NotificationService().init());
  await Get.putAsync(() => LocationService().init());
  Get.put(AppController());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'تطبيق النقل',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Cairo',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      locale: const Locale('ar', 'EG'),
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: AppRoutes.SPLASH,
      getPages: AppPages.routes,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}
 