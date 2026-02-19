import 'package:flutter/material.dart';

import '../data/purchased_beats.dart';
import '../utils/beat_download_helper.dart';

class PurchasedBeatLicenseDetailPage extends StatelessWidget {
  final PurchasedBeat purchase;

  const PurchasedBeatLicenseDetailPage({
    super.key,
    required this.purchase,
  });

  @override
  Widget build(BuildContext context) {
    final beat = purchase.beat;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Beat License Details"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      beat.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("Producer: ${beat.producer}"),
                    Text("Genre: ${beat.genre}"),
                    Text("BPM: ${beat.bpm}"),
                    Text("Basic Price: Rs ${beat.basicLicensePrice.toStringAsFixed(0)}"),
                    Text("Premium Price: Rs ${beat.premiumLicensePrice.toStringAsFixed(0)}"),
                    Text("Exclusive Price: Rs ${beat.exclusiveLicensePrice.toStringAsFixed(0)}"),
                    const SizedBox(height: 8),
                    Text(
                      "Your License: ${purchase.license} (Rs ${beat.priceForLicense(purchase.license).toStringAsFixed(0)})",
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Description",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(beat.description),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text("Download Beat"),
                        onPressed: () {
                          BeatDownloadHelper.downloadWithFeedback(
                            context: context,
                            beat: beat,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "License Rights",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _LicenseCard(
              title: "Basic License",
              priceNote: "Low cost - Limited usage",
              isCurrent: purchase.license == "Basic",
              allowed: const [
                "Use on YouTube",
                "Use on Instagram",
                "Non-monetized content",
              ],
              notAllowed: const [
                "Spotify or Apple Music",
                "Paid promotions",
                "Reselling the beat",
              ],
            ),
            _LicenseCard(
              title: "Premium License",
              priceNote: "Medium cost - Commercial usage",
              isCurrent: purchase.license == "Premium",
              allowed: const [
                "YouTube monetization",
                "Spotify & Apple Music",
                "Live performances",
              ],
              notAllowed: const [
                "Exclusive ownership",
                "Reselling the beat",
              ],
            ),
            _LicenseCard(
              title: "Exclusive License",
              priceNote: "High cost - Full ownership",
              isCurrent: purchase.license == "Exclusive",
              allowed: const [
                "Unlimited commercial use",
                "Streaming on all platforms",
                "Exclusive ownership",
              ],
              notAllowed: const [
                "Reselling license to others",
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LicenseCard extends StatelessWidget {
  final String title;
  final String priceNote;
  final bool isCurrent;
  final List<String> allowed;
  final List<String> notAllowed;

  const _LicenseCard({
    required this.title,
    required this.priceNote,
    required this.isCurrent,
    required this.allowed,
    required this.notAllowed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isCurrent ? Colors.deepPurple : Colors.transparent,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isCurrent)
                  const Chip(
                    label: Text("Purchased"),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              priceNote,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            const Text(
              "Allowed",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
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
            const SizedBox(height: 8),
            const Text(
              "Not Allowed",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
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
