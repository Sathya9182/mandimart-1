# Project Blueprint

## Overview

This Flutter application serves as a mobile frontend for the UPI Grocery Billing web application. It uses a WebView to display the web app and provides native functionalities like location access, payments via Razorpay, and camera/gallery access for image handling.

## Features

### 1. WebView Integration
- The core of the app is a `WebViewWidget` that loads the specified URL (`https://upi-grocery-billing-test.web.app`).
- JavaScript is enabled in the WebView to allow for communication between the web app and the Flutter app.

### 2. JavaScript Channels
JavaScript channels are used to bridge the web app with native Flutter capabilities:

- **`Location` Channel:**
    - Handles requests from the web app to get the device's current GPS location.
    - It requests location permission from the user.
    - If permission is granted, it retrieves the latitude and longitude using the `geolocator` package and sends it back to the web app.
    - If permission is denied or an error occurs, it sends an error message back.
    - It supports both the legacy `handleLocationResult` and the new `handleUniversalLocationResult` JavaScript functions.

- **`FlutterRazorpay` Channel:**
    - Triggers native Razorpay payments.
    - The web app sends payment options as a JSON string.
    - The Flutter app parses these options and initiates the Razorpay payment flow.
    - The payment success or failure is communicated back to the web app.

- **`Camera` Channel:**
    - Handles requests to use the device's camera.
    - It can be used for:
        - **`scanBarcode`:** (Simulated) In a real app, this would open a barcode scanner. Here, it's simulated using the image picker.
        - **`takePicture`:** Opens the camera to take a photo.
    - The captured image (as a base64 data URL) is sent back to the web app.

- **`ImagePicker` Channel:**
    - Handles requests to pick an image from the device's gallery.
    - The selected image (as a base64 data URL) is sent back to the web app.

### 3. Native Integrations

- **Razorpay:** The `razorpay_flutter` package is integrated to handle payments. Event listeners are set up to manage success, error, and external wallet responses.
- **Location:** The `geolocator` and `permission_handler` packages are used to get the device's location securely.
- **Image/Camera:** The `image_picker` package provides the functionality to capture images from the camera and select images from the gallery.

## Style & Design

- The application has a minimal native UI. The entire screen is occupied by the `WebViewWidget`.
- The `SafeArea` widget is used to ensure the web content is not obscured by system UI elements like the status bar.
- The app directly boots into the `WebViewScreen`, providing an immersive web app experience.
