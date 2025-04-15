import 'package:flutter/material.dart';

class InvoiceScreen extends StatelessWidget {
  final String paymentId;
  final String orderId;
  final String amount;

  const InvoiceScreen({
    super.key,
    required this.paymentId,
    required this.orderId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoice"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Payment Invoice",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Payment Details
            Text("Payment ID: $paymentId", style: const TextStyle(fontSize: 16)),
            Text("Order ID: $orderId", style: const TextStyle(fontSize: 16)),
            Text("Amount Paid: ₹$amount", style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 24),

            // Download Invoice Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // You can implement PDF download here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Downloading Invoice...")),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text("Download Invoice"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
