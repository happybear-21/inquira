import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/arxiv_paper.dart';

class ArxivService {
  static const String _baseUrl = 'http://export.arxiv.org/api/query';

  Future<List<ArxivPaper>> searchPapers({
    String searchQuery = 'cat:cs.AI',
    int maxResults = 20,
    int start = 0,
  }) async {
    final queryParams = {
      'search_query': searchQuery,
      'start': start.toString(),
      'max_results': maxResults.toString(),
      'sortBy': 'submittedDate',
      'sortOrder': 'descending',
    };

    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final xmlString = response.body;
      final xmlDoc = XmlDocument.parse(xmlString);
      final entries = xmlDoc.findAllElements('entry');
      final papers = <ArxivPaper>[];
      for (final entry in entries) {
        try {
          // Extract authors
          final authors = entry.findElements('author').map((authorElem) {
            final nameElem = authorElem.findElements('name').firstOrNull;
            return {'name': nameElem?.text ?? ''};
          }).toList();

          // Extract links
          final links = entry.findElements('link').map((linkElem) {
            return {
              '@href': linkElem.getAttribute('href') ?? '',
              '@title': linkElem.getAttribute('title') ?? '',
            };
          }).toList();

          // Extract categories
          final categories = entry.findElements('category').map((catElem) {
            return {'@term': catElem.getAttribute('term') ?? ''};
          }).toList();

          // Extract primary category (namespace aware)
          final primaryCatElem = entry.getElement('arxiv:primary_category', namespace: '*');
          final primaryCategory = primaryCatElem?.getAttribute('term') ?? '';

          final entryMap = {
            'id': entry.getElement('id')?.text ?? '',
            'title': entry.getElement('title')?.text ?? '',
            'summary': entry.getElement('summary')?.text ?? '',
            'published': entry.getElement('published')?.text ?? '',
            'author': authors,
            'link': links,
            'category': categories,
            'arxiv:primary_category': {'@term': primaryCategory},
          };

          papers.add(ArxivPaper.fromJson({'entry': entryMap}));
        } catch (e) {
          print('Error parsing paper: $e');
        }
      }
      return papers;
    } else {
      throw Exception('Failed to load papers');
    }
  }
}