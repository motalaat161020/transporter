import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transport_app/controllers/auth_controller.dart';
import 'dart:async';

class VerifyOtpView extends StatefulWidget {
  @override
  _VerifyOtpViewState createState() => _VerifyOtpViewState();
}

class _VerifyOtpViewState extends State<VerifyOtpView> {
  final AuthController authController = Get.find();
  List<TextEditingController> otpControllers = List.generate(6, (index) => TextEditingController());
  