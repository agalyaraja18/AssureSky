import 'package:dio/dio.dart';
import 'package:xml/xml.dart';
import '../../models/official_alert_model.dart';
import 'alert_provider.dart';
import 'ndma_http_stub.dart' if (dart.library.io) 'ndma_http_io.dart';

/// India — National Disaster Management Authority's SACHET system, which
/// republishes alerts from the India Meteorological Department (IMD) and the
/// state disaster authorities as CAP (Common Alerting Protocol) documents.
///
/// The RSS feed lists the latest alerts (in many Indian languages); each item
/// links to a CAP XML with the full details.
class NdmaAlertProvider extends AlertProvider {
  static const String rssUrl =
      'https://sachet.ndma.gov.in/cap_public_website/rss/rss_india.xml';

  /// How many of the newest English alerts to fetch in full. Each is a ~1.5 KB
  /// request, so this keeps the cost small.
  static const int maxAlerts = 40;
  static const int concurrency = 8;

  final Dio _dio;
  NdmaAlertProvider({Dio? dio}) : _dio = dio ?? _newDio();

  /// SACHET's certificate chain ends at a root that older Android versions do
  /// not know (see ndma_http_io.dart), so trust it explicitly for this feed.
  static Dio _newDio() {
    final dio = AlertProvider.newDio();
    trustSectigoRoot(dio);
    return dio;
  }

  @override
  String get id => 'ndma';

  @override
  String get name => 'India — IMD / NDMA';

  @override
  Future<List<OfficialAlert>> fetchWorld() async {
    final rss = await _getText(rssUrl);
    final links = parseRssLinks(rss).take(maxAlerts).toList();
    if (links.isEmpty) return const [];

    final alerts = <OfficialAlert>[];
    var next = 0;

    // A small worker pool: `concurrency` workers pull links until none remain.
    Future<void> worker() async {
      while (true) {
        if (next >= links.length) return;
        final link = links[next++];
        try {
          final alert = parseCap(await _getText(link), fallbackId: link);
          if (alert != null) alerts.add(alert);
        } catch (_) {
          // One bad document must not discard the others.
        }
      }
    }

    await Future.wait(List.generate(concurrency, (_) => worker()));
    return alerts;
  }

  Future<String> _getText(String url) async {
    final res = await _dio.get<String>(url,
        options: Options(responseType: ResponseType.plain));
    return res.data ?? '';
  }

  /// Links to the CAP documents of the meteorological, English-language items
  /// in the RSS feed, newest first.
  static List<String> parseRssLinks(String rssXml) {
    final doc = XmlDocument.parse(rssXml);
    final links = <String>[];
    for (final item in doc.findAllElements('item')) {
      final category = item.getElement('category')?.innerText.trim() ?? '';
      if (category.isNotEmpty && category != 'Met') continue; // not weather

      // The feed mixes ~20 Indian languages. Titles that contain non-Latin
      // script are regional-language duplicates of an English alert.
      final title = item.getElement('title')?.innerText ?? '';
      if (title.runes.any((r) => r > 0x24F)) continue;

      final link = item.getElement('link')?.innerText.trim() ?? '';
      if (link.isNotEmpty) links.add(link);
    }
    return links;
  }

  /// Parses one CAP 1.2 XML document. Returns null for tests, cancellations
  /// and anything without usable content.
  static OfficialAlert? parseCap(String capXml, {required String fallbackId}) {
    final doc = XmlDocument.parse(capXml);
    final alert = doc.rootElement;

    // CAP elements are namespaced (`cap:status`), so match on any namespace.
    String text(XmlElement? e, String name) =>
        e?.getElement(name, namespaceUri: '*')?.innerText.trim() ?? '';

    final status = text(alert, 'status');
    final msgType = text(alert, 'msgType');
    if (status.isNotEmpty && status.toLowerCase() != 'actual') return null;
    if (msgType.toLowerCase() == 'cancel') return null;

    // Prefer the English <info> block when there are several languages.
    final infos = alert.findElements('info', namespaceUri: '*').toList();
    if (infos.isEmpty) return null;
    final info = infos.firstWhere(
      (i) => text(i, 'language').toLowerCase().startsWith('en'),
      orElse: () => infos.first,
    );

    final event = text(info, 'event');
    final headline = text(info, 'headline');
    final title = event.isNotEmpty ? event : headline;
    if (title.isEmpty) return null;

    final issued = DateTime.tryParse(text(alert, 'sent')) ?? DateTime.now();
    final effective = DateTime.tryParse(text(info, 'effective'));
    final onset = DateTime.tryParse(text(info, 'onset'));
    final expires = DateTime.tryParse(text(info, 'expires'));

    final areas = info
        .findElements('area', namespaceUri: '*')
        .map((a) => text(a, 'areaDesc'))
        .where((s) => s.isNotEmpty)
        .toList();

    final description = text(info, 'description');
    final (instructions, general) = AlertProvider.instructionsFor(
        text(info, 'instruction'), '$event $headline');

    final identifier = text(alert, 'identifier');

    return OfficialAlert(
      id: 'ndma:${identifier.isEmpty ? fallbackId : identifier}',
      provider: 'ndma',
      title: title,
      severity: OfficialSeverity.fromCap(text(info, 'severity')),
      location: areas.isEmpty ? 'India' : areas.join(', '),
      issued: issued,
      start: onset ?? effective,
      end: expires,
      // NDMA often leaves <description> empty and puts the text in <headline>.
      description: AlertProvider.tidy(description.isNotEmpty ? description : headline),
      instructions: instructions,
      instructionsAreGeneral: general,
      source: _sourceName(text(alert, 'sender')),
      countryCode: 'IN',
    );
  }

  /// "IMD-Bhubaneswar" → "India Meteorological Department (IMD Bhubaneswar) via NDMA SACHET".
  static String _sourceName(String sender) {
    if (sender.toUpperCase().startsWith('IMD')) {
      final office = sender.replaceFirst(RegExp(r'^IMD[-_ ]*', caseSensitive: false), '');
      final label = office.isEmpty ? 'IMD' : 'IMD $office';
      return 'India Meteorological Department ($label) via NDMA SACHET';
    }
    return sender.isEmpty
        ? 'National Disaster Management Authority, India (SACHET)'
        : '$sender via NDMA SACHET (National Disaster Management Authority, India)';
  }
}
