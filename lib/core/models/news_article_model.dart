class NewsArticleModel {
  final String title;
  final String description;
  final String content;
  final String? urlToImage;
  final String url;
  final String sourceName;
  final DateTime publishedAt;

  const NewsArticleModel({
    required this.title,
    required this.description,
    required this.content,
    this.urlToImage,
    required this.url,
    required this.sourceName,
    required this.publishedAt,
  });

  factory NewsArticleModel.fromJson(Map<String, dynamic> json) {
    return NewsArticleModel(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      content: json['content'] as String? ?? '',
      urlToImage: json['urlToImage'] as String?,
      url: json['url'] as String? ?? '',
      sourceName: (json['source'] as Map<String, dynamic>?)?['name'] as String? ?? '',
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
