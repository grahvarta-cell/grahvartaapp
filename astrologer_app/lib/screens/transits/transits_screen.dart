import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/zodiac_wheel.dart';

class TransitsScreen extends StatefulWidget {
  const TransitsScreen({super.key});

  @override
  State<TransitsScreen> createState() => _TransitsScreenState();
}

class _TransitsScreenState extends State<TransitsScreen> {
  List<Transit> _transits = [];
  bool _isLoading = true;
  String _selectedCategory = 'love';
  final List<Map<String, String>> _categories = [
    {'key': 'love', 'label': 'Love'},
    {'key': 'friendship', 'label': 'Friendship'},
    {'key': 'work', 'label': 'Work'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTransits();
  }

  Future<void> _loadTransits() async {
    try {
      final data = await ApiService.getTransits(category: _selectedCategory);
      if (mounted) setState(() { _transits = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: context.clr.txtPrimary), onPressed: () {}),
        title: const Text('Transits'),
        actions: [IconButton(icon: Icon(Icons.menu, color: context.clr.txtPrimary), onPressed: () {})],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildWheel()),
          SliverToBoxAdapter(child: _buildInspirationSection()),
          SliverToBoxAdapter(child: _buildCategoryTabs()),
          SliverToBoxAdapter(child: _buildDescription()),
          if (_isLoading)
            SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: context.clr.accent)))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildTransitCard(_transits[i]),
                childCount: _transits.length,
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildWheel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(child: ZodiacWheel(size: MediaQuery.of(context).size.width * 0.7)),
    );
  }

  Widget _buildInspirationSection() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text('Inspiration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.clr.txtPrimary)),
    );
  }

  Widget _buildCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = cat['key'] == _selectedCategory;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() { _selectedCategory = cat['key']!; _isLoading = true; });
                  _loadTransits();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? context.clr.accent : context.clr.card,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(cat['label']!, textAlign: TextAlign.center,
                    style: TextStyle(color: isSelected ? Colors.white : context.clr.txtSecondary, fontWeight: FontWeight.w500, fontSize: 14)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDescription() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        'Transits in astrology are one of the a most powerful tools for the understanding the evolving themes of your life. They represent the ongoing movement of planets in the sky in relation to your natal chart, highlighting the areas of life where growth, challenges, and opportunities are currently unfolding.',
        style: TextStyle(color: context.clr.txtSecondary, fontSize: 13, height: 1.6),
      ),
    );
  }

  Widget _buildTransitCard(Transit transit) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.clr.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.clr.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _intensityDot(transit.intensity),
              const SizedBox(width: 8),
              Expanded(child: Text(transit.title, style: TextStyle(color: context.clr.txtPrimary, fontSize: 15, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 8),
          Text(transit.description, style: TextStyle(color: context.clr.txtSecondary, fontSize: 13, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _intensityDot(String? intensity) {
    final color = intensity == 'strong' ? const Color(0xFFE53935) : intensity == 'moderate' ? context.clr.accent : context.clr.accentAlt;
    return Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}
