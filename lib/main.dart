
import 'dart:convert';

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
  late final Razorpay _razorpay;

  // IMPORTANT: Replace this with your app's URL
  final String _initialUrl = 'https://upi-grocery-billing--studio-1348838345-ee88b.us-central1.hosted.app/';

  @override
  void initState() {
    super.initState();
    
    // --- Initialize Razorpay ---
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // --- Initialize WebView Controller ---
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'FlutterRazorpay', // Matches the name in the web app
        onMessageReceived: _handleRazorpayChannel,
      )
      ..addJavaScriptChannel(
        'FlutterLocation', 
        onMessageReceived: _handleLocationChannel,
      )
      ..loadRequest(Uri.parse(_initialUrl));
  }

    // --- Location Channel Handler ---
  void _handleLocationChannel(JavaScriptMessage message) async {
    // Request location permission
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
        // Send location back to the webview
        _controller.runJavaScript(
            'window.handleLocation(${jsonEncode(locationData)})');
      } catch (e) {
        // Handle location errors
        _controller.runJavaScript('window.handleLocationError("Error getting location: $e")');
      }
    } else {
      // Handle permission denied
      _controller.runJavaScript('window.handleLocationError("Location permission denied")');
    }
  }


  // Handle payment requests from the web app
  void _handleRazorpayChannel(JavaScriptMessage message) {
    try {
      final paymentOptions = jsonDecode(message.message) as Map<String, dynamic>;
      _razorpay.open(paymentOptions);
    } catch (e) {
      debugPrint('Error parsing Razorpay options: $e');
    }
  }

  // --- Razorpay Event Handlers ---
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
    debugPrint("EXTERNAL_WALLET: ${response.walletName!}");
  }

  @override
  void dispose() {
    _razorpay.clear(); // Remove listeners
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
