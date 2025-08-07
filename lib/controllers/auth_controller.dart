import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transport_app/models/user_model.dart';
import 'package:transport_app/routes/app_routes.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User state
  final Rx<User?> _firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;

  // Auth data
  final RxString phoneNumber = ''.obs;
  final RxString verificationId = ''.obs;
  final Rx<UserType?> selectedUserType = Rx<UserType?>(null);

  // Controllers
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    _firebaseUser.bindStream(_auth.authStateChanges());
    ever(_firebaseUser, _setInitialScreen);
  }

  /// تحديد الشاشة الأولى بناءً على حالة المستخدم
  void _setInitialScreen(User? user) async {
    if (user == null) {
      // المستخدم غير مسجل
      isLoggedIn.value = false;
      Get.offAllNamed(AppRoutes.USER_TYPE_SELECTION);
    } else {
      // المستخدم مسجل - التحقق من اكتمال البيانات
      await _loadUserData(user.uid);
      
      if (currentUser.value == null) {
        // المستخدم موجود لكن البيانات غير مكتملة
        Get.offAllNamed(AppRoutes.COMPLETE_PROFILE);
      } else {
        // المستخدم مسجل وبياناته مكتملة
        isLoggedIn.value = true;
        _navigateToHome();
      }
    }
  }

  /// تحميل بيانات المستخدم من Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        currentUser.value = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('خطأ في تحميل بيانات المستخدم: $e');
    }
  }

  /// التنقل إلى الصفحة الرئيسية حسب نوع المستخدم
  void _navigateToHome() {
    if (currentUser.value?.userType == UserType.rider) {
      Get.offAllNamed(AppRoutes.RIDER_HOME);
    } else if (currentUser.value?.userType == UserType.driver) {
      Get.offAllNamed(AppRoutes.DRIVER_HOME);
    }
  }

  /// تحديد نوع المستخدم
  void selectUserType(UserType type) {
    selectedUserType.value = type;
    Get.toNamed(AppRoutes.PHONE_AUTH);
  }

  /// إرسال رمز التحقق
  Future<void> sendOTP() async {
    if (phoneController.text.trim().isEmpty) {
      Get.snackbar(
        'خطأ',
        'يرجى إدخال رقم الهاتف',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    String phone = _formatPhoneNumber(phoneController.text.trim());
    phoneNumber.value = phone;

    try {
      isLoading.value = true;

      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // التحقق التلقائي (Android only)
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          isLoading.value = false;
          String message;
          
          switch (e.code) {
            case 'invalid-phone-number':
              message = 'رقم الهاتف غير صحيح';
              break;
            case 'too-many-requests':
              message = 'تم تجاوز عدد المحاولات المسموح';
              break;
            default:
              message = 'فشل في إرسال رمز التحقق';
          }
          
          Get.snackbar(
            'خطأ',
            message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          isLoading.value = false;
          this.verificationId.value = verificationId;
          
          Get.toNamed(AppRoutes.VERIFY_OTP);
          
          Get.snackbar(
            'تم الإرسال',
            'تم إرسال رمز التحقق إلى $phone',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId.value = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      isLoading.value = false;
      print('خطأ في إرسال OTP: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ غير متوقع',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// التحقق من رمز OTP
  Future<void> verifyOTP() async {
    if (otpController.text.trim().isEmpty) {
      Get.snackbar(
        'خطأ',
        'يرجى إدخال رمز التحقق',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (verificationId.value.isEmpty) {
      Get.snackbar(
        'خطأ',
        'يرجى طلب رمز التحقق أولاً',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: otpController.text.trim(),
      );

      await _signInWithCredential(credential);
    } catch (e) {
      isLoading.value = false;
      print('خطأ في التحقق من OTP: $e');
      
      String message;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
            message = 'رمز التحقق غير صحيح';
            break;
          case 'invalid-verification-id':
            message = 'انتهت صلاحية رمز التحقق';
            break;
          default:
            message = 'فشل في التحقق من الرمز';
        }
      } else {
        message = 'حدث خطأ غير متوقع';
      }
      
      Get.snackbar(
        'خطأ',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// تسجيل الدخول باستخدام Credential
  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      UserCredential result = await _auth.signInWithCredential(credential);
      
      if (result.user != null) {
        // التحقق من وجود المستخدم في قاعدة البيانات
        await _loadUserData(result.user!.uid);
        
        if (currentUser.value == null) {
          // مستخدم جديد - الانتقال لإكمال البيانات
          Get.offAllNamed(AppRoutes.COMPLETE_PROFILE);
        } else {
          // مستخدم موجود - الانتقال للصفحة الرئيسية
          isLoggedIn.value = true;
          _navigateToHome();
        }
      }
    } catch (e) {
      print('خطأ في تسجيل الدخول: $e');
      throw e;
    } finally {
      isLoading.value = false;
    }
  }

  /// إكمال الملف الشخصي
  Future<void> completeProfile({
    required String name,
    required String email,
    String? profileImage,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_auth.currentUser == null) {
      Get.snackbar(
        'خطأ',
        'يرجى تسجيل الدخول أولاً',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedUserType.value == null) {
      Get.snackbar(
        'خطأ',
        'يرجى اختيار نوع المستخدم',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;

      UserModel user = UserModel(
        id: _auth.currentUser!.uid,
        name: name,
        phone: phoneNumber.value,
        email: email,
        profileImage: profileImage,
        userType: selectedUserType.value!,
        createdAt: DateTime.now(),
        additionalData: additionalData,
      );

      // حفظ البيانات في Firestore
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toMap());

      currentUser.value = user;
      isLoggedIn.value = true;

      Get.snackbar(
        'تم بنجاح',
        'تم إنشاء الحساب بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      _navigateToHome();
    } catch (e) {
      print('خطأ في حفظ البيانات: $e');
      Get.snackbar(
        'خطأ',
        'فشل في حفظ البيانات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// تحديث بيانات المستخدم
  Future<void> updateUser(UserModel updatedUser) async {
    try {
      await _firestore
          .collection('users')
          .doc(updatedUser.id)
          .update(updatedUser.toMap());

      currentUser.value = updatedUser;

      Get.snackbar(
        'تم بنجاح',
        'تم تحديث البيانات بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('خطأ في تحديث البيانات: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تحديث البيانات',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// تحديث الرصيد
  Future<void> updateBalance(double amount) async {
    if (currentUser.value == null) return;

    try {
      UserModel updatedUser = currentUser.value!.copyWith(
        balance: currentUser.value!.balance + amount,
      );

      await updateUser(updatedUser);
    } catch (e) {
      print('خطأ في تحديث الرصيد: $e');
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      currentUser.value = null;
      isLoggedIn.value = false;
      
      // مسح البيانات المحلية
      _clearControllers();
      
      Get.offAllNamed(AppRoutes.USER_TYPE_SELECTION);
    } catch (e) {
      print('خطأ في تسجيل الخروج: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تسجيل الخروج',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// إعادة إرسال رمز التحقق
  Future<void> resendOTP() async {
    if (phoneNumber.value.isEmpty) {
      Get.snackbar(
        'خطأ',
        'يرجى إدخال رقم الهاتف أولاً',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await sendOTP();
  }

  /// تنسيق رقم الهاتف
  String _formatPhoneNumber(String phone) {
    // إزالة أي مسافات أو رموز
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // إضافة رمز الدولة إذا لم يكن موجود
    if (!phone.startsWith('+20')) {
      if (phone.startsWith('20')) {
        phone = '+$phone';
      } else if (phone.startsWith('0')) {
        phone = '+2$phone';
      } else {
        phone = '+20$phone';
      }
    }
    
    return phone;
  }

  /// مسح المتحكمات
  void _clearControllers() {
    phoneController.clear();
    otpController.clear();
    nameController.clear();
    emailController.clear();
    phoneNumber.value = '';
    verificationId.value = '';
    selectedUserType.value = null;
  }

  @override
  void onClose() {
    phoneController.dispose();
    otpController.dispose();
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }
}