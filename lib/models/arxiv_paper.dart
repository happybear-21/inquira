import 'package:hive/hive.dart';
part 'arxiv_paper.g.dart';

@HiveType(typeId: 1)
class ArxivPaper extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final List<String> authors;
  @HiveField(3)
  final String abstract;
  @HiveField(4)
  final String pdfUrl;
  @HiveField(5)
  final DateTime publishedDate;
  @HiveField(6)
  final List<String> categories;
  @HiveField(7)
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