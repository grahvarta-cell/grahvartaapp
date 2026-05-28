import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ListenScreen extends StatefulWidget {
  const ListenScreen({super.key});

  @override
  State<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends State<ListenScreen> {
  List<AudioContent> _stories = [];
  bool _isLoading = true;
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final data = await ApiService.getAudioContent(category: 'sleep_story');
      if (mounted) setState(() { _stories = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () {}),
        title: const Text('Listen'),
        actions: [IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () {})],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          if (_isLoading)
            SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: context.clr.accent))))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildStoryCard(_stories[i]),
                childCount: _stories.isEmpty ? 3 : _stories.length,
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          Text('Sleep stories', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: context.clr.txtPrimary)),
          const SizedBox(height: 8),
          Text(
            'Transits explain the current themes of your life and the where you are being asked to grow and show up.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.clr.txtSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(AudioContent? story) {
    final planets = [
      {'name': 'Journey to moon', 'planet': 'Moon', 'color': const Color(0xFF8B9DC3)},
      {'name': 'Journey to Jupiter', 'planet': 'Jupiter', 'color': const Color(0xFFB87333)},
      {'name': 'Journey to mars', 'planet': 'Mars', 'color': const Color(0xFFCD5C5C)},
    ];

    final index = _stories.isNotEmpty ? _stories.indexOf(story!) : 0;
    final demo = planets[index % planets.length];
    final title = story?.title ?? demo['name'] as String;
    final isPlaying = story?.id == _playingId;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.clr.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.clr.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: context.clr.txtPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  "I don't have a birth chart, a but if I did, I'd be Mercury ruled curious.",
                  style: TextStyle(color: context.clr.txtSecondary, fontSize: 12, height: 1.4),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _playingId = isPlaying ? null : story?.id),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: context.clr.accent, shape: BoxShape.circle),
                    child: Icon(isPlaying ? Icons.pause : Icons.arrow_forward, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildPlanetImage(demo['planet'] as String, demo['color'] as Color),
        ],
      ),
    );
  }

  Widget _buildPlanetImage(String planet, Color color) {
    return Container(
      width: 90, height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment.topLeft,
          colors: [color.withOpacity(0.8), color.withOpacity(0.3), Colors.transparent],
        ),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          planet == 'Moon' ? '🌙' : planet == 'Jupiter' ? '🪐' : '🔴',
          style: const TextStyle(fontSize: 36),
        ),
      ),
    );
  }
}
