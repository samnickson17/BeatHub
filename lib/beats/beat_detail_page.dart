import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../backend/backend_contracts.dart';
import '../backend/local_backend.dart';
import '../data/purchased_beats.dart';
import '../payment/stripe_payment_page.dart';
import '../profile/profile_store.dart';
import '../utils/beat_download_helper.dart';
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
  final AudioPlayer _player = AudioPlayer();
  bool _isPlayingPreview = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(BeatModel beat) async {
    if (_isPlayingPreview) {
      await _player.stop();
      if (mounted) {
        setState(() => _isPlayingPreview = false);
      }
      return;
    }

    if (beat.audioPath.startsWith('assets/')) {
      await _player.play(
        AssetSource(beat.audioPath.replaceFirst('assets/', '')),
      );
    } else {
      await _player.play(DeviceFileSource(beat.audioPath));
    }

    if (mounted) {
      setState(() => _isPlayingPreview = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final beat = widget.beat;
    final isArtistUser =
        AppBackend.auth.currentUser?.role == AppUserRole.buyer;
    final selectedPrice = beat.priceForLicense(_selectedLicense);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Beat Details"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
              "Basic Price: Rs ${beat.basicLicensePrice.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text("Premium Price: Rs ${beat.premiumLicensePrice.toStringAsFixed(0)}"),
            Text("Exclusive Price: Rs ${beat.exclusiveLicensePrice.toStringAsFixed(0)}"),
            const SizedBox(height: 20),
            const Text(
              "Description",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(beat.description),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(_isPlayingPreview ? Icons.stop : Icons.play_arrow),
                label: Text(_isPlayingPreview ? "Stop Preview" : "Play Beat"),
                onPressed: () => _togglePreview(beat),
              ),
            ),
            if (isArtistUser) ...[
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.mic),
                  label: const Text("Try Rap Preview"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RapRecordPage(selectedBeat: beat),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Select License",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              RadioListTile(
                title: const Text("Basic License"),
                subtitle: Text(
                  "Non-exclusive - Limited usage - Rs ${beat.basicLicensePrice.toStringAsFixed(0)}",
                ),
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
                subtitle: Text(
                  "High quality - Extended usage - Rs ${beat.premiumLicensePrice.toStringAsFixed(0)}",
                ),
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
                subtitle: Text(
                  "One buyer only - Full rights - Rs ${beat.exclusiveLicensePrice.toStringAsFixed(0)}",
                ),
                value: "Exclusive",
                groupValue: _selectedLicense,
                onChanged: (value) {
                  setState(() {
                    _selectedLicense = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart),
                  label: Text(
                    "Buy $_selectedLicense License (Rs ${selectedPrice.toStringAsFixed(0)})",
                  ),
                  onPressed: () async {
                    final paid = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StripePaymentPage(
                          beat: beat,
                          license: _selectedLicense,
                        ),
                      ),
                    );

                    if (paid != true || !context.mounted) return;

                    final currentUser = AppBackend.auth.currentUser;
                    final buyerProfile =
                        ProfileStore.getProfile(ProfileStore.currentUserId);
                    final buyerName = buyerProfile?.name ??
                        currentUser?.email.split('@').first ??
                        "Buyer";
                    final buyerUsername =
                        buyerProfile?.username ?? buyerName.toLowerCase();
                    final now = DateTime.now();

                    PurchasedBeatsStore.purchasedBeats.add(
                      PurchasedBeat(
                        beat: beat,
                        license: _selectedLicense,
                        buyerUserId: currentUser?.userId ?? "buyer_unknown",
                        buyerAccountName: buyerName,
                        buyerUsername: buyerUsername,
                        buyerEmail: currentUser?.email ?? "unknown@local",
                        pricePaid: selectedPrice,
                        transactionId: "TXN${now.microsecondsSinceEpoch}",
                        purchasedAt: now,
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Purchased ${beat.title} with $_selectedLicense license",
                        ),
                        action: SnackBarAction(
                          label: "Download",
                          onPressed: () {
                            BeatDownloadHelper.downloadWithFeedback(
                              context: context,
                              beat: beat,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const SizedBox(height: 24),
              const Text(
                "Rap Preview and Purchase are available only for Artist users.",
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}
