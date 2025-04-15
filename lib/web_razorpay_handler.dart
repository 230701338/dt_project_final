// Only for web builds
// dart:js is ONLY supported on the web platform

// web_razorpay_handler.dart

import 'dart:js' as js;

void openRazorpayWeb(int amount) {
  js.context.callMethod('openRazorpayWeb', [amount]);
}
