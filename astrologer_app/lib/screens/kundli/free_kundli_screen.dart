import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FreeKundliScreen extends StatefulWidget {
  const FreeKundliScreen({super.key});

  @override
  State<FreeKundliScreen> createState() => _FreeKundliScreenState();
}

class _FreeKundliScreenState extends State<FreeKundliScreen> with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  DateTime? _dob;
  TimeOfDay? _tob;

  bool _isCalculating = false;
  Map<String, dynamic>? _result;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _placeCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Pure-Dart Vedic calculations ─────────────────────────────────────────────

  static const _signs = ['Aries','Taurus','Gemini','Cancer','Leo','Virgo',
      'Libra','Scorpio','Sagittarius','Capricorn','Aquarius','Pisces'];

  static const _nakshatras = [
    'Ashwini','Bharani','Krittika','Rohini','Mrigashirsha','Ardra','Punarvasu',
    'Pushya','Ashlesha','Magha','Purva Phalguni','Uttara Phalguni','Hasta',
    'Chitra','Swati','Vishakha','Anuradha','Jyeshtha','Mula','Purva Ashadha',
    'Uttara Ashadha','Shravana','Dhanishtha','Shatabhisha','Purva Bhadrapada',
    'Uttara Bhadrapada','Revati',
  ];

  // Approximate sun sign from birthday (Western ≈ Vedic for basic display)
  String _sunSign(DateTime d) {
    final m = d.month; final day = d.day;
    if ((m == 3 && day >= 21) || (m == 4 && day <= 19)) return 'Aries';
    if ((m == 4 && day >= 20) || (m == 5 && day <= 20)) return 'Taurus';
    if ((m == 5 && day >= 21) || (m == 6 && day <= 20)) return 'Gemini';
    if ((m == 6 && day >= 21) || (m == 7 && day <= 22)) return 'Cancer';
    if ((m == 7 && day >= 23) || (m == 8 && day <= 22)) return 'Leo';
    if ((m == 8 && day >= 23) || (m == 9 && day <= 22)) return 'Virgo';
    if ((m == 9 && day >= 23) || (m == 10 && day <= 22)) return 'Libra';
    if ((m == 10 && day >= 23) || (m == 11 && day <= 21)) return 'Scorpio';
    if ((m == 11 && day >= 22) || (m == 12 && day <= 21)) return 'Sagittarius';
    if ((m == 12 && day >= 22) || (m == 1 && day <= 19)) return 'Capricorn';
    if ((m == 1 && day >= 20) || (m == 2 && day <= 18)) return 'Aquarius';
    return 'Pisces';
  }

  // Approximate nakshatra index from day-of-year (simplified)
  int _nakshatraIndex(DateTime d) {
    final dayOfYear = d.difference(DateTime(d.year, 1, 1)).inDays;
    return ((dayOfYear * 27) ~/ 365) % 27;
  }

  // Approximate moon sign (lags sun by ~30°, i.e. ~1 sign ahead)
  String _moonSign(DateTime d) {
    final idx = _signs.indexOf(_sunSign(d));
    return _signs[(idx + 1) % 12];
  }

  // Ascendant from birth hour (approx: changes every 2 hours)
  String _ascendant(DateTime d, TimeOfDay t) {
    final sunIdx = _signs.indexOf(_sunSign(d));
    final hourOffset = t.hour ~/ 2;
    return _signs[(sunIdx + hourOffset) % 12];
  }

  static const _planetSymbols = ['Su','Mo','Ma','Me','Ju','Ve','Sa','Ra','Ke'];
  static const _planetNames = ['Sun ☀️','Moon 🌙','Mars ♂','Mercury ☿','Jupiter ♃','Venus ♀','Saturn ♄','Rahu ☊','Ketu ☋'];
  static const _retrograde = [false,false,false,false,false,false,false,true,true];

  List<Map<String, dynamic>> _buildPlanets(DateTime dob, TimeOfDay tob) {
    final sunIdx = _signs.indexOf(_sunSign(dob));
    // Approximate each planet position offset from sun sign
    final offsets = [0, 1, 4, 11, 8, 2, 9, 5, 11];
    final nakIdx = _nakshatraIndex(dob);
    final nakOffsets = [0, 9, 4, 7, 2, 5, 18, 13, 22];

    return List.generate(9, (i) => {
      'name': _planetNames[i],
      'symbol': _planetSymbols[i],
      'sign': _signs[(sunIdx + offsets[i]) % 12],
      'nakshatra': _nakshatras[(nakIdx + nakOffsets[i]) % 27],
      'retrograde': _retrograde[i],
    });
  }

  Future<void> _calculate() async {
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select date of birth')));
      return;
    }
    setState(() => _isCalculating = true);
    await Future.delayed(const Duration(milliseconds: 600)); // simulate processing

    final tob = _tob ?? const TimeOfDay(hour: 12, minute: 0);
    final planets = _buildPlanets(_dob!, tob);
    final nakIdx = _nakshatraIndex(_dob!);

    setState(() {
      _result = {
        'name': _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Native',
        'sun_sign': _sunSign(_dob!),
        'moon_sign': _moonSign(_dob!),
        'nakshatra': _nakshatras[nakIdx],
        'ascendant': _ascendant(_dob!, tob),
        'planets': planets,
        'dob': '${_dob!.day}/${_dob!.month}/${_dob!.year}',
        'tob': '${tob.hour.toString().padLeft(2, '0')}:${tob.minute.toString().padLeft(2, '0')}',
        'place': _placeCtrl.text.isNotEmpty ? _placeCtrl.text : 'India',
      };
      _isCalculating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: const Text('Free Kundli'),
      ),
      body: _result == null ? _buildForm() : _buildResult(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        _field('Full Name', _nameCtrl, Icons.person_outline),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: DateTime(1990),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (c, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.orange)), child: child!),
            );
            if (d != null) setState(() => _dob = d);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              const Icon(Icons.cake_outlined, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 12),
              Text(_dob != null ? '${_dob!.day}/${_dob!.month}/${_dob!.year}' : 'Date of Birth *',
                  style: TextStyle(color: _dob != null ? AppColors.textPrimary : AppColors.textMuted)),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () async {
            final t = await showTimePicker(
              context: context,
              initialTime: _tob ?? const TimeOfDay(hour: 12, minute: 0),
              builder: (c, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.orange)), child: child!),
            );
            if (t != null) setState(() => _tob = t);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              const Icon(Icons.access_time_outlined, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 12),
              Text(_tob != null ? '${_tob!.hour.toString().padLeft(2,'0')}:${_tob!.minute.toString().padLeft(2,'0')}' : 'Time of Birth (optional)',
                  style: TextStyle(color: _tob != null ? AppColors.textPrimary : AppColors.textMuted)),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        _field('Birth Place', _placeCtrl, Icons.place_outlined, hint: 'City name (e.g. Delhi, Mumbai)'),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _isCalculating ? null : _calculate,
            child: _isCalculating
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text('Generate Kundli ✨', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    return Column(children: [
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2A1500), Color(0xFF1A0D00)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.orange.withOpacity(0.3)),
        ),
        child: Row(children: [
          CircleAvatar(radius: 28, backgroundColor: AppColors.orange.withOpacity(0.2),
              child: Text((r['name'] as String)[0].toUpperCase(), style: const TextStyle(fontSize: 24, color: AppColors.orange, fontWeight: FontWeight.bold))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r['name'], style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
            Text('${r['dob']}  ${r['tob']}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            Text(r['place'], style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ])),
          TextButton(onPressed: () => setState(() => _result = null), child: const Text('Reset', style: TextStyle(color: AppColors.orange))),
        ]),
      ),
      TabBar(
        controller: _tabController,
        indicatorColor: AppColors.orange,
        labelColor: AppColors.orange,
        unselectedLabelColor: AppColors.textMuted,
        tabs: const [Tab(text: 'Overview'), Tab(text: 'Planets'), Tab(text: 'Details')],
      ),
      Expanded(child: TabBarView(controller: _tabController, children: [
        _buildOverviewTab(r),
        _buildPlanetsTab(r),
        _buildDetailsTab(r),
      ])),
    ]);
  }

  Widget _buildOverviewTab(Map<String, dynamic> r) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      _infoRow('☀️ Sun Sign (Surya)', r['sun_sign']),
      _infoRow('🌙 Moon Sign (Chandra)', r['moon_sign']),
      _infoRow('⭐ Birth Nakshatra', r['nakshatra']),
      _infoRow('⬆️ Ascendant (Lagna)', r['ascendant']),
    ]),
  );

  Widget _buildPlanetsTab(Map<String, dynamic> r) {
    final planets = r['planets'] as List<Map<String, dynamic>>;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: planets.length,
      itemBuilder: (_, i) {
        final p = planets[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Text(p['name'], style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(p['sign'], style: const TextStyle(color: AppColors.orange, fontSize: 13)),
              Text(p['nakshatra'], style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ]),
            if (p['retrograde'] == true) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: const Text('Rx', style: TextStyle(color: AppColors.orange, fontSize: 11))),
            ],
          ]),
        );
      },
    );
  }

  Widget _buildDetailsTab(Map<String, dynamic> r) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('BIRTH DETAILS', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 10),
      _infoRow('Name', r['name']),
      _infoRow('Date of Birth', r['dob']),
      _infoRow('Time of Birth', r['tob']),
      _infoRow('Place', r['place']),
      const SizedBox(height: 20),
      const Text('KEY POSITIONS', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 10),
      _infoRow('Sun Sign (Rashi)', r['sun_sign']),
      _infoRow('Moon Sign (Chandra Rashi)', r['moon_sign']),
      _infoRow('Birth Nakshatra', r['nakshatra']),
      _infoRow('Ascendant (Lagna)', r['ascendant']),
    ]),
  );

  Widget _infoRow(String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      const Spacer(),
      Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _field(String label, TextEditingController ctrl, IconData icon, {String? hint}) => TextFormField(
    controller: ctrl,
    style: const TextStyle(color: AppColors.textPrimary),
    decoration: InputDecoration(
      labelText: label, hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      labelStyle: const TextStyle(color: AppColors.textMuted),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      filled: true, fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.orange)),
    ),
  );
}
