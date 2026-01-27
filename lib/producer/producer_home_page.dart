import 'package:flutter/material.dart';

// Producer pages
import 'upload_beat_page.dart';
import 'revenue_calculator.dart';

class ProducerHomePage extends StatelessWidget {
  const ProducerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ➕ Upload Beat
        leading: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UploadBeatPage(),
              ),
            );
          },
        ),

        title: const Text(
          "BeatHub",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,

        // 💰 Revenue
        actions: [
          IconButton(
            icon: const Icon(Icons.currency_rupee),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RevenueCalculatorPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 PRODUCER USP BANNER
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "🎹 Producer Dashboard",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Upload beats instantly and track your earnings with full transparency.",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Your Activity",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: Icon(Icons.library_music),
                title: Text("Uploaded Beats"),
                subtitle: Text("Manage and edit your beats"),
              ),
            ),

            Card(
              child: ListTile(
                leading: Icon(Icons.bar_chart),
                title: Text("Earnings Overview"),
                subtitle: Text("View sales and revenue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
