import 'package:flutter/material.dart';

import '../data/purchased_beats.dart';
import '../profile/producer_profile_store.dart';

class ProducerInsightsPage extends StatelessWidget {
  const ProducerInsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final producerId = ProducerProfileStore.profile.userId;
    final soldBeats = PurchasedBeatsStore.purchasedBeats
        .where((item) => item.beat.producerId == producerId)
        .toList()
      ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Insights"),
        centerTitle: true,
      ),
      body: soldBeats.isEmpty
          ? const Center(
              child: Text(
                "No sold beats yet",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: soldBeats.length,
              itemBuilder: (context, index) {
                final sale = soldBeats[index];
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
                        Text("Sold To: ${sale.buyerAccountName} (@${sale.buyerUsername})"),
                        Text("Buyer Account: ${sale.buyerEmail}"),
                        Text("License: ${sale.license}"),
                        Text("Sold Price: Rs ${sale.pricePaid.toStringAsFixed(0)}"),
                        Text("Transaction ID: ${sale.transactionId}"),
                        Text("Sold At: ${_formatDateTime(sale.purchasedAt)}"),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final date = "${dt.year}-${_two(dt.month)}-${_two(dt.day)}";
    final time = "${_two(dt.hour)}:${_two(dt.minute)}";
    return "$date $time";
  }

  String _two(int value) => value < 10 ? "0$value" : "$value";
}
