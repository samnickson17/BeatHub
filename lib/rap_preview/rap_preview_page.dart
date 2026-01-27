import 'package:flutter/material.dart';
import 'select_beat_page.dart';

class RapPreviewPage extends StatelessWidget {
  const RapPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rap Preview"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mic,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),

            const Text(
              "Try Before You Buy",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Select a beat and record your rap using the microphone. "
              "This preview is temporary and cannot be downloaded.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              icon: const Icon(Icons.library_music),
              label: const Text("Select Beat"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SelectBeatPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
