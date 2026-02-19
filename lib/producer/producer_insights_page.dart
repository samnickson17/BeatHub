import 'package:flutter/material.dart';

import '../backend/local_backend.dart';
import '../data/purchased_beats.dart';

class ProducerInsightsPage extends StatefulWidget {
  const ProducerInsightsPage({super.key});

  @override
  State<ProducerInsightsPage> createState() => _ProducerInsightsPageState();
}

class _ProducerInsightsPageState extends State<ProducerInsightsPage> {
  List<PurchasedBeat>? _sales;
  double _totalRevenue = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final uid = AppBackend.auth.currentUser?.userId ?? '';
      final sales = await AppBackend.purchases.fetchPurchasesBySeller(uid);
      final total = sales.fold<double>(0, (s, p) => s + p.pricePaid);
      if (mounted) {
        setState(() {
          _sales = sales;
          _totalRevenue = total;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sales = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales & Insights"),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Revenue summary card ──
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Colors.deepPurple.shade900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Total Revenue",
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Rs ${_totalRevenue.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Beats Sold",
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${_sales?.length ?? 0}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Sales list ──
                Expanded(
                  child: (_sales == null || _sales!.isEmpty)
                      ? const Center(
                          child: Text(
                            "No sales yet",
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: _sales!.length,
                          itemBuilder: (context, index) {
                            final sale = _sales![index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sale.beat.title,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Sold To: ${sale.buyerAccountName} (@${sale.buyerUsername})",
                                    ),
                                    Text("Email: ${sale.buyerEmail}"),
                                    Text("License: ${sale.license}"),
                                    Text(
                                      "Amount: Rs ${sale.pricePaid.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Transaction ID: ${sale.transactionId}",
                                    ),
                                    Text(
                                      "Date: ${_formatDateTime(sale.purchasedAt)}",
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final date = "${dt.year}-${_two(dt.month)}-${_two(dt.day)}";
    final time = "${_two(dt.hour)}:${_two(dt.minute)}";
    return "$date $time";
  }

  String _two(int v) => v < 10 ? "0$v" : "$v";
}
