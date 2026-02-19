import 'package:flutter/material.dart';

import '../beats/beat_model.dart';

class StripePaymentPage extends StatefulWidget {
  final BeatModel beat;
  final String license;

  const StripePaymentPage({
    super.key,
    required this.beat,
    required this.license,
  });

  @override
  State<StripePaymentPage> createState() => _StripePaymentPageState();
}

class _StripePaymentPageState extends State<StripePaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  String _selectedMethod = "card";
  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _completePayment() async {
    if (_selectedMethod == "card" && !_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isProcessing = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.beat.priceForLicense(widget.license).toStringAsFixed(2);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stripe Payment"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.beat.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text("License: ${widget.license}"),
              const SizedBox(height: 4),
              Text(
                "Amount: Rs $amount",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Payment Method",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: "card",
                    icon: Icon(Icons.credit_card),
                    label: Text("Card"),
                  ),
                  ButtonSegment<String>(
                    value: "qr",
                    icon: Icon(Icons.qr_code),
                    label: Text("QR Scan"),
                  ),
                ],
                selected: {_selectedMethod},
                onSelectionChanged: (selection) {
                  setState(() => _selectedMethod = selection.first);
                },
              ),
              const SizedBox(height: 10),
              if (_selectedMethod == "card") ...[
                const Text(
                  "Card Details",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Card Number",
                    hintText: "4242 4242 4242 4242",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final digits = value?.replaceAll(RegExp(r'\s+'), '') ?? '';
                    if (digits.length < 16) return "Enter a valid card number";
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Expiry (MM/YY)",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final raw = value ?? '';
                          if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(raw)) {
                            return "Invalid expiry";
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "CVV",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (!(value != null &&
                              RegExp(r'^\d{3,4}$').hasMatch(value))) {
                            return "Invalid CVV";
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Text(
                  "Scan and Pay",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.qr_code_2, size: 140),
                      SizedBox(height: 10),
                      Text(
                        "Scan this QR with any UPI app to pay",
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6),
                      Text(
                        "UPI ID: beathub@upi",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _completePayment,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.payment),
                  label: Text(_isProcessing
                      ? "Processing..."
                      : _selectedMethod == "card"
                          ? "Pay with Stripe"
                          : "I've Paid via QR"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
