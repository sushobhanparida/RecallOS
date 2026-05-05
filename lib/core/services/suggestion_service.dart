import '../models/screenshot_model.dart';

/// A proposed stack derived from clustering similar screenshots.
class StackSuggestion {
  final String name;
  final List<Screenshot> screenshots;
  final String dismissKey;

  const StackSuggestion({
    required this.name,
    required this.screenshots,
    required this.dismissKey,
  });
}

/// Entity-anchored clustering for high-signal screenshot types only.
/// Allowed clusters: Receipts (money), Travel (flight), Emails, Portraits,
/// Payment QRs, Wi-Fi QRs, QR Codes.
class SuggestionService {
  static const int _minClusterSize = 2;

  Future<List<StackSuggestion>> suggest(
    List<Screenshot> screenshots,
    Set<String> dismissedKeys,
  ) async {
    final docs = screenshots
        .where((s) => s.id != null && s.entities.isNotEmpty)
        .toList();
    if (docs.length < _minClusterSize) return [];

    final out = <StackSuggestion>[];
    final claimed = <int>{};

    // Pass 1: exact flight number matches (most specific signal for travel).
    _emit(_sorted(_flightClusters(docs)), claimed, dismissedKeys, out);
    // Pass 2: entity type clusters for the allowed set.
    _emit(_sorted(_typeClusters(docs)), claimed, dismissedKeys, out);

    out.sort((a, b) => b.screenshots.length.compareTo(a.screenshots.length));
    return out;
  }

  // ── Pass implementations ─────────────────────────────────────────────────

  List<_RawCluster> _flightClusters(List<Screenshot> docs) {
    final byFlight = <String, List<Screenshot>>{};
    for (final s in docs) {
      final keys = <String>{};
      for (final e in s.entities.where((e) => e.type == 'flight')) {
        final airline = (e.value?['airline'] as String?)?.trim() ?? '';
        final number = (e.value?['number'] as String?)?.trim() ?? '';
        final k = (airline + number).toUpperCase();
        if (k.length >= 3) keys.add(k);
      }
      for (final k in keys) {
        byFlight.putIfAbsent(k, () => []).add(s);
      }
    }
    return [
      for (final entry in byFlight.entries)
        if (entry.value.length >= _minClusterSize)
          _RawCluster(name: 'Flight ${entry.key}', screenshots: entry.value),
    ];
  }

  List<_RawCluster> _typeClusters(List<Screenshot> docs) {
    final byType = <String, List<Screenshot>>{};
    for (final s in docs) {
      for (final t in s.entities.map((e) => e.type).toSet()) {
        if (_clusterLabel(t) != null) {
          byType.putIfAbsent(t, () => []).add(s);
        }
      }
    }
    return [
      for (final entry in byType.entries)
        if (entry.value.length >= _minClusterSize)
          _RawCluster(
            name: _clusterLabel(entry.key)!,
            screenshots: entry.value,
          ),
    ];
  }

  // ── Emission + dismissal ─────────────────────────────────────────────────

  void _emit(
    Iterable<_RawCluster> raw,
    Set<int> claimed,
    Set<String> dismissedKeys,
    List<StackSuggestion> output,
  ) {
    for (final c in raw) {
      final fresh = [
        for (final s in c.screenshots)
          if (!claimed.contains(s.id)) s
      ];
      if (fresh.length < _minClusterSize) continue;

      final ids = fresh.map((s) => s.id!).toList()..sort();
      final dismissKey = ids.join(',');
      if (dismissedKeys.contains(dismissKey)) continue;

      output.add(StackSuggestion(
        name: c.name,
        screenshots: fresh,
        dismissKey: dismissKey,
      ));
      claimed.addAll(ids);
    }
  }

  List<_RawCluster> _sorted(List<_RawCluster> clusters) {
    clusters.sort(
        (a, b) => b.screenshots.length.compareTo(a.screenshots.length));
    return clusters;
  }

  // ── Label map — only allowed cluster types ───────────────────────────────

  String? _clusterLabel(String type) {
    switch (type) {
      case 'money':
        return 'Receipts';
      case 'flight':
        return 'Travel';
      case 'email':
      case 'qr_email':
        return 'Emails';
      case 'portrait':
        return 'Portraits';
      case 'qr_payment':
        return 'Payment QRs';
      case 'qr_wifi':
        return 'Wi-Fi QRs';
      case 'qr':
        return 'QR Codes';
    }
    return null;
  }
}

class _RawCluster {
  final String name;
  final List<Screenshot> screenshots;
  _RawCluster({required this.name, required this.screenshots});
}
