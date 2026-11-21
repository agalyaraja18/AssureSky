/// Decides whether a news article is really about the weather.
///
/// A plain "contains" check is too loose: "rain" matches "train" and
/// "Ukraine", "hail" matches "Thailand", "fog" matches "foggy memories" and
/// "storm" matches "brainstorm". Everything here matches whole words only.
class WeatherNewsFilter {
  WeatherNewsFilter._();

  /// Terms that are almost always about weather on their own.
  static final RegExp _strong = RegExp(
    r'\b('
    r'weather|monsoon|cyclones?|hurricanes?|typhoons?|tornado(es)?|'
    r'heat ?waves?|cold waves?|cold snap|rainfall|thunderstorms?|'
    r'blizzards?|snowfall|snowstorms?|floods?|flooding|flash floods?|'
    r'droughts?|el ni.o|la ni.a|meteorolog\w*|meteorologists?|imd|noaa|'
    r'heavy rains?|torrential rains?|rain alert|storm surge|'
    r'severe storms?|winter storms?|tropical storms?|dust storms?|'
    r'sandstorms?|hailstorms?|lightning|wildfire smoke|air quality|'
    r'weather (alert|warning|forecast|department|service|office)|'
    r'(red|orange|yellow) alert|heat index|wind chill|'
    r'temperatures?|forecasters?'
    r')\b',
    caseSensitive: false,
  );

  /// Weather words that also have everyday meanings. They only count as
  /// supporting evidence next to another weather word.
  static final RegExp _weak = RegExp(
    r'\b(rains?|rainy|storms?|stormy|snow|snowy|hail|fog|foggy|mist|haze|'
    r'humidity|heat|hot|cold|climate|forecasts?|winds?|windy|showers?|'
    r'downpour|drizzle|frost|freezing|chill|sunny|cloudy|gusts?)\b',
    caseSensitive: false,
  );

  /// Topics that reuse weather words ("Hurricanes" the NHL team, "Storm" the
  /// Marvel character, "fog of war" the game term...). A match in the headline
  /// rejects the article; a match only in the description rejects it unless the
  /// headline itself has a strong weather term.
  static final RegExp _offTopic = RegExp(
    r'\b('
    r'nhl|nba|nfl|mlb|ipl|fifa|hockey|stanley cup|cricket|football|soccer|'
    r'box office|movie|film|trailer|episode|season \d+|netflix|album|song|'
    r'lyrics|concert|celebrity|kardashian|stock|stocks|shares|sensex|nifty|'
    r'bitcoin|crypto|ipo|earnings|marvel|x-men|fortnite|gta|playstation|xbox|'
    r'fog of war|snow white|purple rain|rain man|brainstorm|rainbow six|'
    r'pitcher|baseball|quarterback|touchdown|insurance|insurers|profits|'
    r'game of thrones|political climate|business climate|investment climate'
    r')\b',
    caseSensitive: false,
  );

  static bool isWeatherNews(String title, String description) {
    // A sports / entertainment / finance headline is not weather news, even
    // if it uses a weather word ("Hurricanes beat Rangers").
    if (_offTopic.hasMatch(title)) return false;
    final inTitleStrong = _strong.hasMatch(title);
    if (inTitleStrong) return true;
    if (_offTopic.hasMatch(description)) return false;

    final strongInDesc = _strong.hasMatch(description);
    final weakInTitle = _weak.hasMatch(title);
    final weakWords = _weak
        .allMatches('$title $description')
        .map((m) => m.group(0)!.toLowerCase())
        .toSet();

    // Strong term in the text plus a weather word in the headline.
    if (strongInDesc && weakInTitle) return true;
    // Strong term in the text plus a second, different weather word.
    if (strongInDesc && weakWords.length >= 2) return true;
    // Headline about e.g. "heavy snow" with more weather words in the text.
    if (weakInTitle && weakWords.length >= 3) return true;
    return false;
  }
}
