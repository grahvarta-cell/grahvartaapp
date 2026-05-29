import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class BirthChartScreen extends StatefulWidget {
  const BirthChartScreen({super.key});

  @override
  State<BirthChartScreen> createState() => _BirthChartScreenState();
}

class _BirthChartScreenState extends State<BirthChartScreen> {
  bool _isLoading = true;
  String? _error;
  int _selectedTab = 0;
  Map<String, dynamic>? _chartData;

  final List<String> _tabs = ['Planets in Signs', 'Planets in Houses'];

  @override
  void initState() {
    super.initState();
    _loadChart();
  }

  Future<void> _loadChart() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService.getBirthChart();
      setState(() { _chartData = data['data'] ?? data; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Could not load birth chart. Please ensure your birth details are filled in your profile.'; _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _planets {
    final raw = _chartData?['planets'] as List?;
    if (raw == null) return [];
    return raw.map((p) => Map<String, dynamic>.from(p as Map)).toList();
  }

  String get _sunSign => _chartData?['sun_sign'] ?? _chartData?['sunSign'] ?? '—';
  String get _moonSign => _chartData?['moon_sign'] ?? _chartData?['moonSign'] ?? '—';
  String get _ascendant => _chartData?['ascendant'] ?? _chartData?['lagna'] ?? '—';
  String get _nakshatra => _chartData?['moon_nakshatra'] ?? _chartData?['nakshatra'] ?? '—';

  // Build 12-house list from planet data for Kundali grid
  List<List<String>> get _houses {
    final houses = List.generate(12, (_) => <String>[]);
    for (final p in _planets) {
      final house = (p['house'] as num?)?.toInt();
      final symbol = p['symbol'] as String? ?? p['name']?.toString().substring(0, 2) ?? '';
      if (house != null && house >= 1 && house <= 12) {
        houses[house - 1].add(symbol);
      }
    }
    return houses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: context.clr.txtPrimary), onPressed: () => Navigator.pop(context)),
        title: const Text('Your Birth Chart'),
        actions: [IconButton(icon: Icon(Icons.refresh, color: context.clr.txtPrimary), onPressed: _loadChart)],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: context.clr.accent))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.auto_graph, color: context.clr.txtMuted, size: 64),
        const SizedBox(height: 16),
        Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: context.clr.txtSecondary, fontSize: 14, height: 1.6)),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _loadChart, child: const Text('Try Again')),
        const SizedBox(height: 10),
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Go Back', style: TextStyle(color: context.clr.txtMuted))),
      ]),
    ));
  }

  Widget _buildContent() {
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _buildKundaliChart()),
      SliverToBoxAdapter(child: _buildKeyPositions()),
      SliverToBoxAdapter(child: _buildTabSelector()),
      SliverToBoxAdapter(child: _buildPlanetList()),
      SliverToBoxAdapter(child: SizedBox(height: 100)),
    ]);
  }

  Widget _buildKundaliChart() {
    final size = MediaQuery.of(context).size.width * 0.85;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: SizedBox(
          width: size, height: size,
          child: CustomPaint(
            painter: _NorthIndianKundaliPainter(houses: _houses, accentColor: context.clr.accent),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyPositions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(spacing: 8, runSpacing: 8, children: [
        _badge('☀️ Sun: $_sunSign'),
        _badge('🌙 Moon: $_moonSign'),
        _badge('⬆️ Asc: $_ascendant'),
        if (_nakshatra != '—') _badge('⭐ $_nakshatra'),
      ]),
    );
  }

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: context.clr.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: context.clr.accent.withValues(alpha: 0.2))),
    child: Text(text, style: TextStyle(color: context.clr.accent, fontSize: 12)),
  );

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(children: List.generate(_tabs.length, (i) {
        final isSelected = i == _selectedTab;
        return Expanded(child: Padding(
          padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: isSelected ? context.clr.accent : context.clr.card, borderRadius: BorderRadius.circular(10)),
              child: Text(_tabs[i], textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : context.clr.txtSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ),
        ));
      })),
    );
  }

  Widget _buildPlanetList() {
    if (_planets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: Text('No planet data available', style: TextStyle(color: context.clr.txtMuted))),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: _planets.map((p) {
        final name = p['name'] as String? ?? '';
        final symbol = p['symbol'] as String? ?? name.substring(0, min(2, name.length));
        final sign = p['sign'] as String? ?? p['zodiac_sign'] as String? ?? '—';
        final nakshatra = p['nakshatra'] as String? ?? '—';
        final house = p['house'] as num?;
        final value = _selectedTab == 0 ? sign : 'House ${house ?? '—'}';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.clr.border)),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [context.clr.surface, context.clr.card]), borderRadius: BorderRadius.circular(22)),
              child: Center(child: Text(symbol, style: TextStyle(color: context.clr.accent, fontWeight: FontWeight.bold, fontSize: 13))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: TextStyle(color: context.clr.txtPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(nakshatra, style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
            ])),
            Text(value, style: TextStyle(color: context.clr.accent, fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
        );
      }).toList()),
    );
  }
}

// ── North Indian Kundali Chart (CustomPainter) ────────────────────────────────
class _NorthIndianKundaliPainter extends CustomPainter {
  final List<List<String>> houses;
  final Color accentColor;

  _NorthIndianKundaliPainter({required this.houses, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final linePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Outer border
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), linePaint);

    // Inner square (rotated 45° diamond)
    final cx = w / 2;
    final cy = h / 2;
    final path = Path()
      ..moveTo(cx, 0)
      ..lineTo(w, cy)
      ..lineTo(cx, h)
      ..lineTo(0, cy)
      ..close();
    canvas.drawPath(path, linePaint);

    // Corner triangles → diagonal lines from corners to diamond vertices
    canvas.drawLine(Offset(0, 0), Offset(cx, cy), linePaint);
    canvas.drawLine(Offset(w, 0), Offset(cx, cy), linePaint);
    canvas.drawLine(Offset(w, h), Offset(cx, cy), linePaint);
    canvas.drawLine(Offset(0, h), Offset(cx, cy), linePaint);

    // House labels — North Indian fixed house positions
    // House centers (approximate) for 12 houses in North Indian style
    final centers = [
      Offset(cx, cy * 0.30),          // 1 - top center (lagna)
      Offset(cx * 0.25, cy * 0.25),   // 2 - top-left triangle top
      Offset(cx * 0.15, cy),          // 3 - left
      Offset(cx * 0.25, cy * 1.75),   // 4 - bottom-left triangle bottom
      Offset(cx, cy * 1.70),          // 5 - bottom center
      Offset(cx * 1.75, cy * 1.75),   // 6 - bottom-right
      Offset(cx * 1.85, cy),          // 7 - right
      Offset(cx * 1.75, cy * 0.25),   // 8 - top-right triangle top
      Offset(cx * 1.55, cy * 0.55),   // 9 - inner top-right
      Offset(cx * 1.55, cy * 1.45),   // 10 - inner bottom-right
      Offset(cx * 0.45, cy * 1.45),   // 11 - inner bottom-left
      Offset(cx * 0.45, cy * 0.55),   // 12 - inner top-left
    ];

    final houseNumStyle = TextStyle(color: accentColor.withValues(alpha: 0.4), fontSize: w * 0.03, fontWeight: FontWeight.bold);
    final planetStyle = TextStyle(color: Colors.white, fontSize: w * 0.035, fontWeight: FontWeight.w600);

    for (int i = 0; i < 12; i++) {
      final center = centers[i];
      // Draw house number (small, dimmed)
      _drawText(canvas, '${i + 1}', center + Offset(-w * 0.03, -h * 0.04), houseNumStyle);
      // Draw planets
      final planets = i < houses.length ? houses[i] : <String>[];
      final planetStr = planets.join(' ');
      if (planetStr.isNotEmpty) {
        _drawText(canvas, planetStr, center, planetStyle);
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, offset - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _NorthIndianKundaliPainter old) => old.houses != houses || old.accentColor != accentColor;
}
