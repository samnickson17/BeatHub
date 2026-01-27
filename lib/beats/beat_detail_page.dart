import 'package:flutter/material.dart';
import '../data/purchased_beats.dart';
import 'beat_model.dart';
import '../rap_preview/rap_record_page.dart';

class BeatDetailPage extends StatefulWidget {
  final BeatModel beat;

  const BeatDetailPage({super.key, required this.beat});

  @override
  State<BeatDetailPage> createState() => _BeatDetailPageState();
}

class _BeatDetailPageState extends State<BeatDetailPage> {
  String _selectedLicense = "Basic";

  @override
  Widget build(BuildContext context) {
    final beat = widget.beat;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Beat Details"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              beat.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text("Producer: ${beat.producer}"),
            Text("Genre: ${beat.genre}"),
            Text("BPM: ${beat.bpm}"),

            const SizedBox(height: 10),

            Text(
              "Base Price: ₹${beat.price}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Description",
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(beat.description),

            const SizedBox(height: 25),

            // 🎤 RAP PREVIEW
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.mic),
                label: const Text("Try Rap Preview"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RapRecordPage(selectedBeat: beat),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // 📜 LICENSE SELECTION
            const Text(
              "Select License",
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            RadioListTile(
              title: const Text("Basic License"),
              subtitle: const Text(
                  "Non-exclusive • Limited usage"),
              value: "Basic",
              groupValue: _selectedLicense,
              onChanged: (value) {
                setState(() {
                  _selectedLicense = value!;
                });
              },
            ),

            RadioListTile(
              title: const Text("Premium License"),
              subtitle: const Text(
                  "High quality • Extended usage"),
              value: "Premium",
              groupValue: _selectedLicense,
              onChanged: (value) {
                setState(() {
                  _selectedLicense = value!;
                });
              },
            ),

            RadioListTile(
              title: const Text("Exclusive License"),
              subtitle: const Text(
                  "One buyer only • Full rights"),
              value: "Exclusive",
              groupValue: _selectedLicense,
              onChanged: (value) {
                setState(() {
                  _selectedLicense = value!;
                });
              },
            ),

            const Spacer(),

            // 🛒 BUY BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart),
                label:
                    Text("Buy ($_selectedLicense License)"),
                onPressed: () {
                  PurchasedBeatsStore.purchasedBeats.add(
                   PurchasedBeat(
                    beat: beat,
                    license: _selectedLicense,
                  ),
                );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Purchased ${beat.title} with $_selectedLicense license",
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
