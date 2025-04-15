// Only for web
import 'dart:js' as js;
import 'razorpay_web_interface.dart';

class RazorpayWebImpl implements RazorpayWebInterface {
  @override
  void openRazorpay(num amount) {
    js.context.callMethod('openRazorpayWeb', [amount]);
  }
}
