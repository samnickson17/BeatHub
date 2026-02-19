import 'package:flutter/material.dart';

import '../backend/local_backend.dart';

class RevenueCalculatorPage extends StatefulWidget {
  const RevenueCalculatorPage({super.key});

  @override
  State<RevenueCalculatorPage> createState() => _RevenueCalculatorPageState();
}

class _RevenueCalculatorPageState extends State<RevenueCalculatorPage> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _commissionController = TextEditingController(
    text: "20",
  );
  final TextEditingController _taxController = TextEditingController(text: "5");

  double? _producerEarnings;

  // Real revenue stats from Firestore
  double? _grossRevenue;
  int? _totalSales;
  double? _netRevenue; // after 20% commission + 5% tax
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final uid = AppBackend.auth.currentUser?.userId ?? '';
      final sales = await AppBackend.purchases.fetchPurchasesBySeller(uid);
      final gross = sales.fold<double>(0, (s, p) => s + p.pricePaid);
      const commission = 0.20;
      const tax = 0.05;
      final net = gross * (1 - commission - tax);
      if (mounted) {
        setState(() {
          _grossRevenue = gross;
          _totalSales = sales.length;
          _netRevenue = net;
          _statsLoading = false;
        });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _grossRevenue = 0;
          _totalSales = 0;
          _netRevenue = 0;
          _statsLoading = false;
        });
    }
  }

  void _calculateRevenue() {
    final price = double.tryParse(_priceController.text);
    final commission = double.tryParse(_commissionController.text);
    final tax = double.tryParse(_taxController.text);

    if (price == null || commission == null || tax == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter valid values")));
      return;
    }

    final commissionAmount = price * (commission / 100);
    final taxAmount = price * (tax / 100);

    setState(() {
      _producerEarnings = price - commissionAmount - taxAmount;
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
        title: const Text("Revenue"),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Real Earnings Card ──
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.deepPurple.shade900,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _statsLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Your Earnings",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _earningsTile(
                                label: "Gross Revenue",
                                value:
                                    "Rs ${_grossRevenue!.toStringAsFixed(0)}",
                              ),
                              _earningsTile(
                                label: "Net Payout",
                                value: "Rs ${_netRevenue!.toStringAsFixed(0)}",
                                highlight: true,
                              ),
                              _earningsTile(
                                label: "Beats Sold",
                                value: "${_totalSales!}",
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Net payout = Gross − 20% commission − 5% tax",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 30),

            // ── USP Banner ──
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.deepPurple.shade800,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "💰 Transparent Earnings",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Know your exact earnings before publishing your beat. "
                      "No hidden cuts or surprises.",
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Calculator ──
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Beat Price (₹)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _commissionController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Platform Commission (%)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _taxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Tax (%)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _calculateRevenue,
              child: const Text("Calculate Earnings"),
            ),

            const SizedBox(height: 20),

            if (_producerEarnings != null)
              Card(
                color: Colors.green.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "You will earn: ₹${_producerEarnings!.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _earningsTile({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: highlight ? Colors.greenAccent : Colors.white,
            fontSize: highlight ? 22 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
