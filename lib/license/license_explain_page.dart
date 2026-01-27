import 'package:flutter/material.dart';

class LicenseExplainPage extends StatelessWidget {
  const LicenseExplainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("License Details"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Understanding Beat Licenses",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 20),

            // BASIC LICENSE
            _LicenseCard(
              title: "Basic License",
              priceNote: "Low cost – Limited usage",
              allowed: [
                "Use on YouTube",
                "Use on Instagram",
                "Non-monetized content",
              ],
              notAllowed: [
                "Spotify or Apple Music",
                "Paid promotions",
                "Reselling the beat",
              ],
            ),

            // PREMIUM LICENSE
            _LicenseCard(
              title: "Premium License",
              priceNote: "Medium cost – Commercial usage",
              allowed: [
                "YouTube monetization",
                "Spotify & Apple Music",
                "Live performances",
              ],
              notAllowed: [
                "Exclusive ownership",
                "Reselling the beat",
              ],
            ),

            // EXCLUSIVE LICENSE
            _LicenseCard(
              title: "Exclusive License",
              priceNote: "High cost – Full ownership",
              allowed: [
                "Unlimited commercial use",
                "Streaming on all platforms",
                "Exclusive ownership",
              ],
              notAllowed: [
                "Reselling license to others",
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------
// Reusable License Card
// ------------------------
class _LicenseCard extends StatelessWidget {
  final String title;
  final String priceNote;
  final List<String> allowed;
  final List<String> notAllowed;

  const _LicenseCard({
    required this.title,
    required this.priceNote,
    required this.allowed,
    required this.notAllowed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              priceNote,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Allowed",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 6),

            ...allowed.map(
              (item) => Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item)),
                ],
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Not Allowed",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 6),

            ...notAllowed.map(
              (item) => Row(
                children: [
                  const Icon(Icons.close, color: Colors.red, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
