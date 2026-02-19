
import 'dart:convert';
import 'dart:developer' as developer; // Import the developer logger

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() async { // Make main async
  // Ensure that plugin services are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  late Razorpay _razorpay;

  final String _initialUrl = 'https://upi-grocery-billing--studio-1348838345-ee88b.us-central1.hosted.app/';

  @override
  void initState() {
    super.initState();
    
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'FlutterRazorpay',
        onMessageReceived: _handleRazorpayChannel,
      )
      ..addJavaScriptChannel(
        'FlutterLocation', 
        onMessageReceived: _handleLocationChannel,
      )
      ..loadRequest(Uri.parse(_initialUrl));
  }

  void _handleLocationChannel(JavaScriptMessage message) async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final locationData = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
        _controller.runJavaScript(
            'window.handleLocation(${jsonEncode(locationData)})');
      } catch (e) {
        _controller.runJavaScript('window.handleLocationError("Error getting location: $e")');
      }
    } else {
      _controller.runJavaScript('window.handleLocationError("Location permission denied")');
    }
  }

  void _handleRazorpayChannel(JavaScriptMessage message) {
    try {
      final paymentOptions = jsonDecode(message.message) as Map<String, dynamic>;

      paymentOptions['callback_url'] = 'mandimart://';
      paymentOptions['redirect'] = true;

      if (paymentOptions['prefill'] is Map) {
          paymentOptions['prefill']['app_name'] = 'Mandi Mart';
      } else {
          paymentOptions['prefill'] = {'app_name': 'Mandi Mart'};
      }

      // --- ADDED DETAILED LOGGING ---
      developer.log(
        'Opening Razorpay with options:',
        name: 'Razorpay',
        error: jsonEncode(paymentOptions),
      );
      // --------------------------------

      _razorpay.open(paymentOptions);
    } catch (e, s) {
        developer.log(
        'Error parsing Razorpay options:',
        name: 'Razorpay',
        error: e,
        stackTrace: s,
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final result = {
      'status': 'success',
      'paymentId': response.paymentId,
    };
    _controller.runJavaScript(
        'window.handleRazorpayResponse(${jsonEncode(result)})');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final result = {
      'status': 'error',
      'error': response.message,
    };
    _controller.runJavaScript(
        'window.handleRazorpayResponse(${jsonEncode(result)})');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    developer.log("External Wallet: ${response.walletName!}", name: 'Razorpay');
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
