import 'dart:convert';
import 'package:http/http.dart' as http;
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
      // Parse XML response
      final papers = <ArxivPaper>[];
      final entries = _parseXmlResponse(xmlString);
      
      for (var entry in entries) {
        try {
          papers.add(ArxivPaper.fromJson(entry));
        } catch (e) {
          print('Error parsing paper: $e');
        }
      }
      
      return papers;
    } else {
      throw Exception('Failed to load papers');
    }
  }

  List<Map<String, dynamic>> _parseXmlResponse(String xmlString) {
    // Simple XML parsing for demonstration
    // In a production app, you should use a proper XML parser
    final entries = <Map<String, dynamic>>[];
    final entryPattern = RegExp(r'<entry>(.*?)</entry>', dotAll: true);
    final matches = entryPattern.allMatches(xmlString);

    for (var match in matches) {
      final entryXml = match.group(1)!;
      final entry = <String, dynamic>{};
      
      // Extract basic fields
      entry['id'] = _extractXmlValue(entryXml, 'id');
      entry['title'] = _extractXmlValue(entryXml, 'title');
      entry['summary'] = _extractXmlValue(entryXml, 'summary');
      entry['published'] = _extractXmlValue(entryXml, 'published');
      
      // Extract authors
      final authorPattern = RegExp(r'<author>.*?<name>(.*?)</name>.*?</author>', dotAll: true);
      final authorMatches = authorPattern.allMatches(entryXml);
      entry['author'] = authorMatches.map((m) => {'name': m.group(1)}).toList();
      
      // Extract links
      final linkPattern = RegExp(r'<link.*?href="(.*?)".*?title="(.*?)".*?>', dotAll: true);
      final linkMatches = linkPattern.allMatches(entryXml);
      entry['link'] = linkMatches.map((m) => {
        '@href': m.group(1),
        '@title': m.group(2),
      }).toList();
      
      // Extract categories
      final categoryPattern = RegExp(r'<category.*?term="(.*?)".*?>', dotAll: true);
      final categoryMatches = categoryPattern.allMatches(entryXml);
      entry['category'] = categoryMatches.map((m) => {'@term': m.group(1)}).toList();
      
      // Extract primary category
      final primaryCategoryPattern = RegExp(r'<arxiv:primary_category.*?term="(.*?)".*?>', dotAll: true);
      final primaryCategoryMatch = primaryCategoryPattern.firstMatch(entryXml);
      if (primaryCategoryMatch != null) {
        entry['arxiv:primary_category'] = {'@term': primaryCategoryMatch.group(1)};
      }
      
      entries.add(entry);
    }
    
    return entries;
  }

  String _extractXmlValue(String xml, String tag) {
    final pattern = RegExp('<$tag>(.*?)</$tag>', dotAll: true);
    final match = pattern.firstMatch(xml);
    return match?.group(1)?.trim() ?? '';
  }
} 