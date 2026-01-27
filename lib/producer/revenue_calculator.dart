import 'package:flutter/material.dart';

class RevenueCalculatorPage extends StatefulWidget {
  const RevenueCalculatorPage({super.key});

  @override
  State<RevenueCalculatorPage> createState() =>
      _RevenueCalculatorPageState();
}

class _RevenueCalculatorPageState extends State<RevenueCalculatorPage> {
  final TextEditingController _priceController =
      TextEditingController();
  final TextEditingController _commissionController =
      TextEditingController(text: "20");
  final TextEditingController _taxController =
      TextEditingController(text: "5");

  double? _producerEarnings;

  void _calculateRevenue() {
    final price = double.tryParse(_priceController.text);
    final commission =
        double.tryParse(_commissionController.text);
    final tax = double.tryParse(_taxController.text);

    if (price == null || commission == null || tax == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid values")),
      );
      return;
    }

    final commissionAmount = price * (commission / 100);
    final taxAmount = price * (tax / 100);

    setState(() {
      _producerEarnings =
          price - commissionAmount - taxAmount;
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _commissionController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Revenue Calculator"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔥 USP BANNER
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "💰 Transparent Earnings",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Know your exact earnings before publishing your beat. "
                      "No hidden cuts or surprises.",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Beat Price (₹)",
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _commissionController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Platform Commission (%)",
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _taxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Tax (%)",
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _calculateRevenue,
              child: const Text("Calculate Earnings"),
            ),

            const SizedBox(height: 20),

            if (_producerEarnings != null)
              Text(
                "You will earn: ₹${_producerEarnings!.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
