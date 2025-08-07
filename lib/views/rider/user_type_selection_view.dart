import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/models/user_model.dart';

class UserTypeSelectionView extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade600,
              Colors.blue.shade800,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo والعنوان
                _buildHeader(),
                
                const SizedBox(height: 60),
                
                // خيارات نوع المستخدم
                _buildUserTypeOptions(),
                
                const SizedBox(height: 40),
                
                // نص توضيحي
                _buildDescription(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.directions_car,
            size: 60,
            color: Colors.blue.shade600,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // عنوان التطبيق
        const Text(
          'تطبيق النقل',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 8),
        
        const Text(
          'اختر نوع حسابك للبدء',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildUserTypeOptions() {
    return Column(
      children: [
        // خيار الراكب
        _buildUserTypeCard(
          userType: UserType.rider,
          title: 'راكب',
          subtitle: 'احجز رحلتك بسهولة',
          icon: Icons.person,
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // خيار السائق
        _buildUserTypeCard(
          userType: UserType.driver,
          title: 'سائق',
          subtitle: 'ابدأ العمل واكسب المال',
          icon: Icons.drive_eta,
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.orange.shade600],
          ),
        ),
      ],
    );
  }

  Widget _buildUserTypeCard({
    required UserType userType,
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
  }) {
    return GestureDetector(
      onTap: () => authController.selectUserType(userType),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // أيقونة
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 30,
              ),
            ),
            
            const SizedBox(width: 20),
            
            // النص
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            // سهم
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'مميزات التطبيق:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem('حجز سريع وآمن'),
          _buildFeatureItem('تتبع مباشر للرحلة'),
          _buildFeatureItem('دفع إلكتروني آمن'),
          _buildFeatureItem('تقييم الخدمة'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade300,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}