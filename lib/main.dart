
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
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
    
    // Request location permission on startup
    _requestLocationPermission();

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
        'Location', // Matches the name in the web app
        onMessageReceived: _handleLocationChannel,
      )
      ..addJavaScriptChannel(
        'FlutterRazorpay', // Matches the name in the web app
        onMessageReceived: _handleRazorpayChannel,
      )
      ..addJavaScriptChannel(
        'Camera', // Matches 'Camera' channel for barcode/image capture
        onMessageReceived: _handleCameraChannel,
      )
      ..addJavaScriptChannel(
        'ImagePicker', // Matches 'ImagePicker' for gallery
        onMessageReceived: _handleImagePickerChannel,
      )
      ..loadRequest(Uri.parse(_initialUrl));
  }

  // --- Permission Handling ---
  void _requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      debugPrint("Location permission granted.");
    } else if (status.isDenied) {
      debugPrint("Location permission denied.");
    } else if (status.isPermanentlyDenied) {
      debugPrint("Location permission permanently denied. Opening app settings.");
      openAppSettings();
    }
  }

  // --- Channel Handlers ---

  // Handle location requests from the web app
  void _handleLocationChannel(JavaScriptMessage message) async {
    if (message.message == 'getUniversalLocation') {
      // Check and request location permission
      var status = await Permission.location.request();
      if (status.isGranted) {
        try {
          Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
          // Success: Send location back to web app
          _controller.runJavaScript(
              'window.handleUniversalLocationResult(${jsonEncode({
                'latitude': position.latitude,
                'longitude': position.longitude
              })})');
        } catch (e) {
          // Error: Send error back to web app
          _controller.runJavaScript(
              'window.handleUniversalLocationResult(${jsonEncode({
                'error': e.toString()
              })})');
        }
      } else {
        // Permission Denied: Send error back to web app
        _controller.runJavaScript(
            'window.handleUniversalLocationResult(${jsonEncode({
              'error': 'Location permission denied.'
            })})');
      }
    } else {
      _handleLegacyLocationChannel(message);
    }
  }

  // Handle legacy location requests from the web app
  void _handleLegacyLocationChannel(JavaScriptMessage message) async {
    // Check and request location permission
    var status = await Permission.location.request();
    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        // Success: Send location back to web app
        _controller.runJavaScript(
            'window.handleLocationResult(${jsonEncode({
              'latitude': position.latitude,
              'longitude': position.longitude
            })})');
      } catch (e) {
        // Error: Send error back to web app
        _controller.runJavaScript(
            'window.handleLocationResult(${jsonEncode({
              'error': e.toString()
            })})');
      }
    } else {
      // Permission Denied: Send error back to web app
      _controller.runJavaScript(
          'window.handleLocationResult(${jsonEncode({
            'error': 'Location permission denied.'
          })})');
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

  // Handle camera requests (for barcode scanning or taking a picture)
  void _handleCameraChannel(JavaScriptMessage message) {
    if (message.message == 'scanBarcode') {
      // Here, you would navigate to a dedicated barcode scanning screen.
      // For this example, we'll simulate it by using the image picker.
      // In a real app, replace this with a package like `mobile_scanner`.
      debugPrint("Barcode scan requested. Implement with a scanner package.");
      // For now, let's just use the image picker as a placeholder.
      _pickImage(ImageSource.camera, isBarcode: true);
    } else if (message.message == 'takePicture') {
      _pickImage(ImageSource.camera);
    }
  }

  // Handle gallery image requests
  void _handleImagePickerChannel(JavaScriptMessage message) {
    if (message.message == 'pickImage') {
      _pickImage(ImageSource.gallery);
    }
  }

  Future<void> _pickImage(ImageSource source, {bool isBarcode = false}) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        final imageBytes = await image.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        final dataUrl = 'data:image/jpeg;base64,$base64Image';

        if (isBarcode) {
          // If you were really scanning a barcode, you would extract the
          // barcode value from the image here before sending it back.
          // For now, we just show a toast.
          debugPrint("Barcode scan simulation complete.");
          // In a real implementation, you'd call:
          // _controller.runJavaScript('window.handleBarcodeResult("$barcodeValue")');
        } else {
          _controller.runJavaScript('window.handleImageResult("$dataUrl")');
        }
      }
    } catch (e) {
      debugPrint("Image picking failed: $e");
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
