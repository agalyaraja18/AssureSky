/// Generic safety guidance for a hazard, used when an authority publishes an
/// alert without usable instructions (many feeds leave the field empty or write
/// only "follow local guidelines").
///
/// This is deliberately general advice — the UI labels it as such and always
/// tells people to follow the authority's own instructions first.
class SafetyAdvice {
  SafetyAdvice._();

  /// True when [instruction] from the authority has real, specific content.
  static bool isUseful(String? instruction) {
    final text = (instruction ?? '').trim();
    return text.length >= 40; // "Please follow SDMA guidelines." etc. are shorter
  }

  /// Guidance for the hazard named in [text] (usually the alert title/event).
  ///
  /// Matching is on whole words (or word *prefixes* for stems such as `flood`),
  /// never raw substrings — otherwise "window" would look like "wind" and
  /// "notice" like "ice".
  static String forHazard(String text) {
    final lower = text.toLowerCase();
    final words = RegExp('[a-z]+').allMatches(lower).map((m) => m.group(0)!).toList();

    /// True if any word starts with one of [stems], equals one of [exact], or
    /// the text contains one of [phrases].
    bool has({
      List<String> stems = const [],
      List<String> exact = const [],
      List<String> phrases = const [],
    }) {
      for (final w in words) {
        if (exact.contains(w)) return true;
        for (final s in stems) {
          if (w.startsWith(s)) return true;
        }
      }
      return phrases.any(lower.contains);
    }

    if (has(stems: ['tornado'])) {
      return _bullets([
        'Take shelter immediately in an interior room on the lowest floor.',
        'Stay away from windows, doors and outside walls.',
        'Do not try to outrun a tornado in a vehicle.',
        'Protect your head and neck with a mattress or heavy blanket.',
      ]);
    }
    if (has(
        stems: ['cyclon', 'hurricane', 'typhoon'],
        phrases: ['tropical storm', 'storm surge'])) {
      return _bullets([
        'Stay indoors, away from windows, and avoid all unnecessary travel.',
        'Keep away from the coast, rivers and low-lying areas; follow evacuation orders.',
        'Keep torches, water, food, medicines and a charged phone ready.',
        'Secure or bring in loose outdoor objects and unplug electronics.',
      ]);
    }
    if (has(
        stems: ['flood', 'waterlog', 'downpour', 'rainfall'],
        phrases: ['heavy rain', 'very heavy rain', 'extremely heavy rain'])) {
      return _bullets([
        'Move to higher ground; avoid low-lying areas, underpasses and river banks.',
        'Never walk or drive through flood water — it can be deeper and faster than it looks.',
        'Turn off electricity at the mains if water enters your home.',
        'Keep drinking water, torches and emergency contacts ready.',
      ]);
    }
    if (has(stems: ['thunder', 'lightning'])) {
      return _bullets([
        'Go indoors and stay away from windows until the storm passes.',
        'Avoid open fields, hilltops, water and tall isolated trees.',
        'Unplug sensitive electronics and avoid using wired phones.',
        'Wait 30 minutes after the last thunder before going back outside.',
      ]);
    }
    if (has(stems: ['hail'])) {
      return _bullets([
        'Shelter indoors and stay away from windows and skylights.',
        'Move vehicles under cover if you can do so safely.',
        'If caught outside, protect your head and take cover immediately.',
      ]);
    }
    if (has(
        stems: ['heat'],
        exact: ['hot'],
        phrases: ['high temperature'])) {
      return _bullets([
        'Stay indoors in the coolest part of the day, roughly 11 AM to 4 PM.',
        'Drink water often, even if you are not thirsty.',
        'Wear light, loose clothing; never leave children or pets in a parked vehicle.',
        'Check on elderly neighbours and anyone who lives alone.',
      ]);
    }
    if (has(
        stems: ['cold', 'frost', 'freez', 'winter', 'snow', 'blizzard', 'sleet', 'icy'],
        exact: ['ice'],
        phrases: ['low temperature'])) {
      return _bullets([
        'Stay indoors if possible and dress in several warm layers.',
        'Avoid travel; if you must drive, carry water, blankets and a charged phone.',
        'Watch for ice on roads and paths.',
        'Check on elderly neighbours and keep pets sheltered.',
      ]);
    }
    if (has(exact: [
      'wind', 'winds', 'windy', 'gale', 'gales', 'gust', 'gusts', 'gusty',
      'squall', 'squalls',
    ])) {
      return _bullets([
        'Stay indoors and away from windows; secure or bring in loose objects.',
        'Avoid trees, hoardings, power lines and unsafe structures.',
        'Take extra care when driving, especially high-sided vehicles and two-wheelers.',
      ]);
    }
    if (has(stems: ['fog', 'mist', 'smog'], phrases: ['visibility'])) {
      return _bullets([
        'Avoid unnecessary travel; if driving, slow down and use low-beam or fog lights.',
        'Keep a larger distance from the vehicle in front.',
        'Pedestrians and cyclists should wear bright or reflective clothing.',
      ]);
    }
    if (has(stems: ['dust', 'sand'])) {
      return _bullets([
        'Stay indoors with doors and windows closed.',
        'Wear a mask and eye protection if you must go out.',
        'People with asthma or breathing problems should stay inside and keep medication handy.',
      ]);
    }
    if (has(stems: ['drought'], exact: ['dry'])) {
      return _bullets([
        'Use water carefully and follow local restrictions.',
        'Avoid any open flames or burning in dry vegetation.',
        'Stay hydrated and watch for local advisories.',
      ]);
    }
    if (has(stems: ['wildfire'], exact: ['fire', 'fires'])) {
      return _bullets([
        'Avoid any open flames and do not burn waste or vegetation.',
        'Be ready to leave if told to; keep documents, medicines and a phone charger together.',
        'Follow instructions from local fire and emergency services.',
      ]);
    }
    // Ordinary rain / showers (after flood, so "heavy rain" gets flood advice).
    if (has(exact: ['rain', 'rains', 'shower', 'showers', 'drizzle'])) {
      return _bullets([
        'Carry an umbrella or raincoat and allow extra travel time.',
        'Take care on wet, slippery roads and avoid waterlogged areas.',
        'Avoid sheltering under trees if there is thunder or lightning.',
      ]);
    }
    return _bullets([
      'Stay informed through official weather updates and local news.',
      'Avoid unnecessary travel in the affected area.',
      'Keep your phone charged and emergency contacts handy.',
    ]);
  }

  static String _bullets(List<String> lines) =>
      lines.map((l) => '• $l').join('\n');
}
