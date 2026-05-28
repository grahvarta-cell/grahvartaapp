import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({super.key});

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  String? _sign1, _sign2;
  Map<String, dynamic>? _result;

  final List<Map<String, String>> _signs = [
    {'name': 'Aries', 'symbol': '♈'}, {'name': 'Taurus', 'symbol': '♉'},
    {'name': 'Gemini', 'symbol': '♊'}, {'name': 'Cancer', 'symbol': '♋'},
    {'name': 'Leo', 'symbol': '♌'}, {'name': 'Virgo', 'symbol': '♍'},
    {'name': 'Libra', 'symbol': '♎'}, {'name': 'Scorpio', 'symbol': '♏'},
    {'name': 'Sagittarius', 'symbol': '♐'}, {'name': 'Capricorn', 'symbol': '♑'},
    {'name': 'Aquarius', 'symbol': '♒'}, {'name': 'Pisces', 'symbol': '♓'},
  ];

  final Map<String, Map<String, int>> _compatibilityMatrix = {
    'Aries': {'Aries': 70, 'Taurus': 50, 'Gemini': 85, 'Cancer': 40, 'Leo': 95, 'Virgo': 45, 'Libra': 75, 'Scorpio': 55, 'Sagittarius': 90, 'Capricorn': 35, 'Aquarius': 80, 'Pisces': 60},
    'Taurus': {'Aries': 50, 'Taurus': 80, 'Gemini': 45, 'Cancer': 90, 'Leo': 55, 'Virgo': 95, 'Libra': 60, 'Scorpio': 85, 'Sagittarius': 40, 'Capricorn': 92, 'Aquarius': 35, 'Pisces': 88},
    'Gemini': {'Aries': 85, 'Taurus': 45, 'Gemini': 75, 'Cancer': 50, 'Leo': 80, 'Virgo': 55, 'Libra': 92, 'Scorpio': 40, 'Sagittarius': 85, 'Capricorn': 45, 'Aquarius': 90, 'Pisces': 55},
    'Cancer': {'Aries': 40, 'Taurus': 90, 'Gemini': 50, 'Cancer': 78, 'Leo': 55, 'Virgo': 82, 'Libra': 45, 'Scorpio': 92, 'Sagittarius': 40, 'Capricorn': 80, 'Aquarius': 35, 'Pisces': 95},
    'Leo': {'Aries': 95, 'Taurus': 55, 'Gemini': 80, 'Cancer': 55, 'Leo': 70, 'Virgo': 50, 'Libra': 85, 'Scorpio': 45, 'Sagittarius': 90, 'Capricorn': 40, 'Aquarius': 75, 'Pisces': 55},
    'Virgo': {'Aries': 45, 'Taurus': 95, 'Gemini': 55, 'Cancer': 82, 'Leo': 50, 'Virgo': 75, 'Libra': 55, 'Scorpio': 88, 'Sagittarius': 40, 'Capricorn': 90, 'Aquarius': 50, 'Pisces': 78},
    'Libra': {'Aries': 75, 'Taurus': 60, 'Gemini': 92, 'Cancer': 45, 'Leo': 85, 'Virgo': 55, 'Libra': 72, 'Scorpio': 55, 'Sagittarius': 82, 'Capricorn': 50, 'Aquarius': 88, 'Pisces': 60},
    'Scorpio': {'Aries': 55, 'Taurus': 85, 'Gemini': 40, 'Cancer': 92, 'Leo': 45, 'Virgo': 88, 'Libra': 55, 'Scorpio': 80, 'Sagittarius': 45, 'Capricorn': 85, 'Aquarius': 40, 'Pisces': 95},
    'Sagittarius': {'Aries': 90, 'Taurus': 40, 'Gemini': 85, 'Cancer': 40, 'Leo': 90, 'Virgo': 40, 'Libra': 82, 'Scorpio': 45, 'Sagittarius': 75, 'Capricorn': 45, 'Aquarius': 88, 'Pisces': 50},
    'Capricorn': {'Aries': 35, 'Taurus': 92, 'Gemini': 45, 'Cancer': 80, 'Leo': 40, 'Virgo': 90, 'Libra': 50, 'Scorpio': 85, 'Sagittarius': 45, 'Capricorn': 82, 'Aquarius': 55, 'Pisces': 80},
    'Aquarius': {'Aries': 80, 'Taurus': 35, 'Gemini': 90, 'Cancer': 35, 'Leo': 75, 'Virgo': 50, 'Libra': 88, 'Scorpio': 40, 'Sagittarius': 88, 'Capricorn': 55, 'Aquarius': 78, 'Pisces': 55},
    'Pisces': {'Aries': 60, 'Taurus': 88, 'Gemini': 55, 'Cancer': 95, 'Leo': 55, 'Virgo': 78, 'Libra': 60, 'Scorpio': 95, 'Sagittarius': 50, 'Capricorn': 80, 'Aquarius': 55, 'Pisces': 82},
  };

  void _checkCompatibility() {
    if (_sign1 == null || _sign2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select both signs')));
      return;
    }
    final score = _compatibilityMatrix[_sign1]?[_sign2] ?? 50;
    setState(() => _result = _buildResult(score));
  }

  Map<String, dynamic> _buildResult(int score) {
    String level, desc;
    if (score >= 85) { level = 'Soulmates'; desc = 'A truly cosmic connection! You are destined for each other.'; }
    else if (score >= 70) { level = 'Highly Compatible'; desc = 'Great match with strong natural chemistry and mutual understanding.'; }
    else if (score >= 55) { level = 'Compatible'; desc = 'Good compatibility with some differences that can be worked through.'; }
    else if (score >= 40) { level = 'Challenging'; desc = 'This pair requires effort and compromise to make it work.'; }
    else { level = 'Difficult'; desc = 'Very different energies. Significant work needed to find harmony.'; }

    return {
      'score': score,
      'level': level,
      'desc': desc,
      'love': (score * 0.95).round().clamp(0, 100),
      'friendship': (score * 0.85).round().clamp(0, 100),
      'work': (score * 0.75).round().clamp(0, 100),
      'trust': (score * 0.80).round().clamp(0, 100),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: context.clr.txtPrimary), onPressed: () => Navigator.pop(context)),
        title: const Text('Compatibility'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Row(children: [
            Expanded(child: _signPicker('Your Sign', _sign1, (s) => setState(() { _sign1 = s; _result = null; }))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('❤️', style: TextStyle(fontSize: 28)),
            ),
            Expanded(child: _signPicker('Their Sign', _sign2, (s) => setState(() { _sign2 = s; _result = null; }))),
          ]),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _checkCompatibility,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63), minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Check Compatibility ❤️', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            _buildCompatResult(),
          ],
        ]),
      ),
    );
  }

  Widget _signPicker(String label, String? selected, Function(String) onSelect) {
    final selectedData = selected != null ? _signs.firstWhere((s) => s['name'] == selected) : null;
    return GestureDetector(
      onTap: () => _showSignPicker(onSelect),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.clr.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected != null ? context.clr.accent.withValues(alpha: 0.5) : context.clr.border),
        ),
        child: Column(children: [
          Text(selectedData?['symbol'] ?? '?', style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 6),
          Text(selected ?? 'Select', style: TextStyle(color: selected != null ? context.clr.txtPrimary : context.clr.txtMuted, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(label, style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
        ]),
      ),
    );
  }

  void _showSignPicker(Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.clr.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Select Zodiac Sign', style: TextStyle(color: context.clr.txtPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 1, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: _signs.length,
            itemBuilder: (_, i) {
              final s = _signs[i];
              return GestureDetector(
                onTap: () { onSelect(s['name']!); Navigator.pop(context); },
                child: Container(
                  decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.clr.border)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(s['symbol']!, style: const TextStyle(fontSize: 24)),
                    Text(s['name']!, style: TextStyle(color: context.clr.txtPrimary, fontSize: 10), overflow: TextOverflow.ellipsis),
                  ]),
                ),
              );
            },
          ),
        ]),
      ),
    );
  }

  Widget _buildCompatResult() {
    final r = _result!;
    final score = r['score'] as int;
    final color = score >= 70 ? context.clr.success : score >= 50 ? context.clr.accent : context.clr.error;
    final sign1Data = _signs.firstWhere((s) => s['name'] == _sign1);
    final sign2Data = _signs.firstWhere((s) => s['name'] == _sign2);

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.15), context.clr.card]),
          borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(sign1Data['symbol']!, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 12),
            Column(children: [
              Text('$score%', style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.bold)),
              Text(r['level'], style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(width: 12),
            Text(sign2Data['symbol']!, style: const TextStyle(fontSize: 36)),
          ]),
          const SizedBox(height: 12),
          Text(r['desc'], style: TextStyle(color: context.clr.txtSecondary, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
        ]),
      ),
      const SizedBox(height: 16),
      ...[
        {'label': '❤️ Love', 'key': 'love'},
        {'label': '🤝 Friendship', 'key': 'friendship'},
        {'label': '💼 Work', 'key': 'work'},
        {'label': '🤲 Trust', 'key': 'trust'},
      ].map((item) {
        final val = r[item['key']] as int;
        final c = val >= 70 ? context.clr.success : val >= 50 ? context.clr.accent : context.clr.error;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(item['label']!, style: TextStyle(color: context.clr.txtSecondary, fontSize: 13)),
              Text('$val%', style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: val / 100, backgroundColor: context.clr.border, color: c, minHeight: 6),
            ),
          ]),
        );
      }),
    ]);
  }
}
