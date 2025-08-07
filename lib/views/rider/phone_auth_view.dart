import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'package:transport_app/models/user_model.dart';

class PhoneAuthView extends StatelessWidget {
  final AuthController authController = Get.find();

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
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // زر الرجوع
                _buildBackButton(),
                
                const SizedBox(height: 40),
                
                // العنوان والوصف
                _buildHeader(),
                
                const SizedBox(height: 60),
                
                // نموذج إدخال رقم الهاتف
                _buildPhoneForm(),
                
                const SizedBox(height: 40),
                
                // زر الإرسال
                _buildSendButton(),
                
                const SizedBox(height: 30),
                
                // معلومات إضافية
                _buildFooterInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'أدخل رقم هاتفك',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 12),
        
        const Text(
          'سيتم إرسال رمز التحقق عبر الرسائل النصية',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getUserTypeColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getUserTypeColor(),
              width: 1,
            ),
          ),
          child: Text(
            authController.selectedUserType.value == UserType.rider 
                ? '📱 حساب راكب' 
                : '🚗 حساب سائق',
            style: TextStyle(
              fontSize: 14,
              color: _getUserTypeColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildPhoneForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'رقم الهاتف',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // حقل إدخال رقم الهاتف
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // رمز الدولة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🇪🇬',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '+20',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // مربع إدخال الرقم
                Expanded(
                  child: TextField(
                    controller: authController.phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                      _PhoneNumberFormatter(),
                    ],
                    decoration: const InputDecoration(
                      hintText: '1xx xxx xxxx',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                        letterSpacing: 1.2,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) {
                      // يمكن إضافة validation هنا
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // معلومة توضيحية
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'سيتم إرسال رمز التحقق المكون من 6 أرقام إلى هذا الرقم',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Obx(() => Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: authController.isLoading.value 
            ? null 
            : () => authController.sendOTP(),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getUserTypeColor(),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: _getUserTypeColor().withOpacity(0.4),
        ),
        child: authController.isLoading.value
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'إرسال رمز التحقق',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    ));
  }

  Widget _buildFooterInfo() {
    return Column(
      children: [
        Text(
          'بالمتابعة، أنت توافق على',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                // فتح شروط الاستخدام
              },
              child: Text(
                'شروط الاستخدام',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            Text(
              ' و ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            
            GestureDetector(
              onTap: () {
                // فتح سياسة الخصوصية
              },
              child: Text(
                'سياسة الخصوصية',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getUserTypeColor() {
    return authController.selectedUserType.value == UserType.rider
        ? Colors.green
        : Colors.orange;
  }
}

/// مُنسق رقم الهاتف
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(' ', '');
    
    if (text.length <= 3) {
      return newValue.copyWith(text: text);
    } else if (text.length <= 6) {
      return newValue.copyWith(
        text: '${text.substring(0, 3)} ${text.substring(3)}',
        selection: TextSelection.collapsed(
          offset: text.length + 1,
        ),
      );
    } else {
      return newValue.copyWith(
        text: '${text.substring(0, 3)} ${text.substring(3, 6)} ${text.substring(6)}',
        selection: TextSelection.collapsed(
          offset: text.length + 2,
        ),
      );
    }
  }
}