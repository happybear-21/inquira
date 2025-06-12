class ArxivPaper {
  final String id;
  final String title;
  final List<String> authors;
  final String abstract;
  final String pdfUrl;
  final DateTime publishedDate;
  final List<String> categories;
  final String primaryCategory;

  ArxivPaper({
    required this.id,
    required this.title,
    required this.authors,
    required this.abstract,
    required this.pdfUrl,
    required this.publishedDate,
    required this.categories,
    required this.primaryCategory,
  });

  factory ArxivPaper.fromJson(Map<String, dynamic> json) {
    final entry = json['entry'] as Map<String, dynamic>;
    final authorList = entry['author'] as List;
    final authors = authorList.map((author) => author['name'] as String).toList();
    
    return ArxivPaper(
      id: entry['id'] as String,
      title: entry['title'] as String,
      authors: authors,
      abstract: entry['summary'] as String,
      pdfUrl: entry['link'][0]['@href'] as String,
      publishedDate: DateTime.parse(entry['published'] as String),
      categories: (entry['category'] as List).map((cat) => cat['@term'] as String).toList(),
      primaryCategory: entry['arxiv:primary_category']['@term'] as String,
    );
  }
} 