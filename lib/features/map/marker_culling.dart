import 'dart:ui';

/// A candidate marker: its screen position (center) and a stable index into
/// the caller's priority-ordered list.
class MarkerCandidate {
  final int index;
  final Offset position;
  const MarkerCandidate(this.index, this.position);
}

/// Picks which markers to draw so they don't overlap.
///
/// [candidates] must already be in priority order (most important first). A
/// candidate is kept only if its [markerSize] box doesn't collide with an
/// already kept one, is on screen ([viewport], inflated by half a marker), and
/// the total stays under [maxMarkers]. Candidates in [forceShow] are always
/// kept first (e.g. the user's own city).
List<int> cullMarkers({
  required List<MarkerCandidate> candidates,
  required Size markerSize,
  required Size viewport,
  int maxMarkers = 45,
  Set<int> forceShow = const {},
}) {
  final kept = <Rect>[];
  final keptIndexes = <int>[];

  Rect boxOf(Offset c) => Rect.fromCenter(
      center: c, width: markerSize.width, height: markerSize.height);

  final screen = Rect.fromLTWH(0, 0, viewport.width, viewport.height)
      .inflate(markerSize.shortestSide / 2);

  bool tryKeep(MarkerCandidate c, {required bool force}) {
    if (!screen.contains(c.position)) return false;
    final box = boxOf(c.position);
    if (!force) {
      if (keptIndexes.length >= maxMarkers) return false;
      for (final k in kept) {
        if (k.overlaps(box)) return false;
      }
    }
    kept.add(box);
    keptIndexes.add(c.index);
    return true;
  }

  for (final c in candidates) {
    if (forceShow.contains(c.index)) tryKeep(c, force: true);
  }
  for (final c in candidates) {
    if (forceShow.contains(c.index)) continue;
    tryKeep(c, force: false);
  }
  return keptIndexes;
}
