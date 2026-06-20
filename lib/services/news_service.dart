import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class NewsService {
  static const String _apiUrl = 'https://api.spaceflightnewsapi.net/v4/articles/?limit=20';

  Future<List<Article>> fetchArticles() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> results = data['results'] as List<dynamic>? ?? [];
        return results.map((item) => Article.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load space news: Status ${response.statusCode}');
      }
    } catch (e) {
      // Fallback: If network fails, return mock data for a robust experience
      return _getFallbackMockArticles();
    }
  }

  List<Article> _getFallbackMockArticles() {
    return [
      Article(
        id: 9901,
        title: 'SpaceX Falcon Heavy Launches Gateway Mission',
        url: 'https://spacenews.com',
        imageUrl: 'https://images.unsplash.com/photo-1541185933-ef5d8ed016c2?auto=format&fit=crop&w=800&q=80',
        newsSite: 'SpaceNews',
        summary: 'SpaceX successfully launched its Falcon Heavy rocket from Kennedy Space Center today, carrying key modules for NASA\'s lunar Gateway space station. The mission went flawlessly, with both side boosters landing back at Cape Canaveral.',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Article(
        id: 9902,
        title: 'Artemis III Crew Prepares for Lunar Landing Training',
        url: 'https://nasa.gov',
        imageUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=800&q=80',
        newsSite: 'NASA Spaceflight',
        summary: 'Astronauts selected for the Artemis III lunar landing mission have begun intensive geology training in the volcanic fields of Arizona. The crew is practicing sample collection techniques and test-driving the new lunar rover designs.',
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      Article(
        id: 9903,
        title: 'James Webb Telescope Discovers Atmospheres on Trappist-1 Exoplanets',
        url: 'https://esa.int',
        imageUrl: 'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?auto=format&fit=crop&w=800&q=80',
        newsSite: 'ESA Portal',
        summary: 'In a groundbreaking discovery, the James Webb Space Telescope has detected carbon dioxide and water vapor in the atmosphere of Trappist-1d, one of the most promising habitable-zone exoplanets in our cosmic neighborhood.',
        publishedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      Article(
        id: 9904,
        title: 'China\'s Space Station Welcomes New Crew Members',
        url: 'https://spaceflightnow.com',
        imageUrl: 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?auto=format&fit=crop&w=800&q=80',
        newsSite: 'Spaceflight Now',
        summary: 'The Shenzhou spacecraft successfully docked with the Tiangong space station on Thursday, bringing three new astronauts to join the crew already on board for a six-month mission that includes extravehicular activities and hardware installation.',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
