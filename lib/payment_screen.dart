import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Conditional import for web-specific JS call
import 'web_razorpay_handler_stub.dart'
    if (dart.library.js) 'web_razorpay_handler.dart';

class PaymentScreen extends StatefulWidget {
  final int amount;

  const PaymentScreen({Key? key, required this.amount}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Razorpay? _razorpay;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  void _startPayment() {
    if (kIsWeb) {
      // Web version
      openRazorpayWeb(widget.amount * 100);
    } else {
      // Mobile version
      var options = {
        'key': 'YOUR_RAZORPAY_KEY',
        'amount': widget.amount * 100,
        'name': 'Test Corp',
        'description': 'Payment',
        'prefill': {
          'contact': '9999999999',
          'email': 'test@example.com',
        }
      };

      try {
        _razorpay?.open(options);
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Successful: ${response.paymentId}")),
    );

    // Reset count field in all product documents
    final productsCollection = FirebaseFirestore.instance.collection('products');

    try {
      final querySnapshot = await productsCollection.get();
      for (var doc in querySnapshot.docs) {
        await doc.reference.update({'count': 0});  // Reset the count to 0
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cart cleared successfully")),
      );

      // Optional: Navigate back or to a success screen
      Navigator.of(context).pop(); // Or push a confirmation screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error resetting cart: $e")),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet: ${response.walletName}")),
    );
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _razorpay?.clear();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Payment")),
      body: Center(
        child: ElevatedButton(
          onPressed: _startPayment,
          child: Text("Pay ₹${widget.amount}"),
        ),
      ),
    );
  }
}
