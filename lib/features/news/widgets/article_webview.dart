// Conditional export — selects the platform-specific ArticleWebView implementation.
// Mobile (Android/iOS) uses webview_flutter; Web uses an HTML iframe.
export 'article_webview_stub.dart'
    if (dart.library.io) 'article_webview_io.dart'
    if (dart.library.html) 'article_webview_web.dart';
