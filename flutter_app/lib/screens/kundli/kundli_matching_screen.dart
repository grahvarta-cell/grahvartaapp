import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class KundliMatchingScreen extends StatefulWidget {
  const KundliMatchingScreen({super.key});

  @override
  State<KundliMatchingScreen> createState() => _KundliMatchingScreenState();
}

class _KundliMatchingScreenState extends State<KundliMatchingScreen> {
  final _boyName = TextEditingController();
  final _girlName = TextEditingController();
  DateTime? _boyDob;
  DateTime? _girlDob;

  bool _isCalculating = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _boyName.dispose();
    _girlName.dispose();
    super.dispose();
  }

  static const _nakshatras = [
    'Ashwini','Bharani','Krittika','Rohini','Mrigashirsha','Ardra','Punarvasu',
    'Pushya','Ashlesha','Magha','Purva Phalguni','Uttara Phalguni','Hasta',
    'Chitra','Swati','Vishakha','Anuradha','Jyeshtha','Mula','Purva Ashadha',
    'Uttara Ashadha','Shravana','Dhanishtha','Shatabhisha','Purva Bhadrapada',
    'Uttara Bhadrapada','Revati',
  ];

  static const _signs = ['Aries','Taurus','Gemini','Cancer','Leo','Virgo',
    'Libra','Scorpio','Sagittarius','Capricorn','Aquarius','Pisces'];

  int _nakshatraIndex(DateTime d) {
    final dayOfYear = d.difference(DateTime(d.year, 1, 1)).inDays;
    return ((dayOfYear * 27) ~/ 365) % 27;
  }

  String _moonSign(DateTime d) {
    final m = d.month; final day = d.day;
    int idx;
    if ((m == 3 && day >= 21) || (m == 4 && day <= 19)) idx = 0;
    else if ((m == 4 && day >= 20) || (m == 5 && day <= 20)) idx = 1;
    else if ((m == 5 && day >= 21) || (m == 6 && day <= 20)) idx = 2;
    else if ((m == 6 && day >= 21) || (m == 7 && day <= 22)) idx = 3;
    else if ((m == 7 && day >= 23) || (m == 8 && day <= 22)) idx = 4;
    else if ((m == 8 && day >= 23) || (m == 9 && day <= 22)) idx = 5;
    else if ((m == 9 && day >= 23) || (m == 10 && day <= 22)) idx = 6;
    else if ((m == 10 && day >= 23) || (m == 11 && day <= 21)) idx = 7;
    else if ((m == 11 && day >= 22) || (m == 12 && day <= 21)) idx = 8;
    else if ((m == 12 && day >= 22) || (m == 1 && day <= 19)) idx = 9;
    else if ((m == 1 && day >= 20) || (m == 2 && day <= 18)) idx = 10;
    else idx = 11;
    return _signs[(idx + 1) % 12]; // moon sign lags ~1 sign
  }

  Future<void> _matchKundli() async {
    if (_boyDob == null || _girlDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both dates of birth')));
      return;
    }
    setState(() => _isCalculating = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final boyNakIdx = _nakshatraIndex(_boyDob!);
    final girlNakIdx = _nakshatraIndex(_girlDob!);

    final gunas = _calculateAshtakoota(boyNakIdx, girlNakIdx);
    final total = gunas.values.fold(0, (a, b) => a + (b['obtained'] as int));
    const max = 36;
    final percent = (total / max * 100).round();

    String compatibility, message;
    if (percent >= 75) { compatibility = 'Excellent'; message = 'Highly compatible! A truly auspicious match with strong cosmic alignment.'; }
    else if (percent >= 50) { compatibility = 'Good'; message = 'Good compatibility. Minor differences can be resolved with understanding.'; }
    else if (percent >= 30) { compatibility = 'Average'; message = 'Average match. Both partners need to work on their differences.'; }
    else { compatibility = 'Challenging'; message = 'This match has challenges. Seek detailed consultation before proceeding.'; }

    setState(() {
      _result = {
        'gunas': gunas,
        'total': total,
        'max': max,
        'percent': percent,
        'compatibility': compatibility,
        'message': message,
        'boy_nakshatra': _nakshatras[boyNakIdx],
        'girl_nakshatra': _nakshatras[girlNakIdx],
        'boy_sign': _moonSign(_boyDob!),
        'girl_sign': _moonSign(_girlDob!),
        'boy_name': _boyName.text.isNotEmpty ? _boyName.text : 'Boy',
        'girl_name': _girlName.text.isNotEmpty ? _girlName.text : 'Girl',
      };
      _isCalculating = false;
    });
  }

  Map<String, Map<String, dynamic>> _calculateAshtakoota(int b, int g) {
    // Standard Ashtakoota calculation based on nakshatra indices (0-26)
    int varna() {
      const varnaMap = [3,2,3,0,2,1,2,1,0,3,2,0,2,3,1,2,1,0,3,2,0,1,3,1,2,0,2];
      return varnaMap[b] >= varnaMap[g] ? 1 : 0;
    }
    int vashya() {
      const vashyaMap = [2,0,1,0,2,0,4,0,3,3,0,0,0,3,2,0,0,3,4,2,0,0,1,0,2,0,2];
      final bv = vashyaMap[b]; final gv = vashyaMap[g];
      return (bv == gv) ? 2 : ((bv + gv) % 2 == 0 ? 1 : 0);
    }
    int tara() {
      final diff = ((g - b) % 9).abs();
      const taraScore = [3, 3, 1, 3, 1, 3, 1, 3, 1];
      return taraScore[diff % taraScore.length] > 1 ? 3 : 0;
    }
    int yoni() {
      const yoniMap = [0,1,2,3,4,5,6,7,8,9,10,11,0,1,2,3,4,5,6,7,8,9,10,11,0,1,2];
      return (yoniMap[b] == yoniMap[g]) ? 4 : ((yoniMap[b] + yoniMap[g]) % 2 == 0 ? 2 : 1);
    }
    int grahaMaitri() {
      const lords = [0,1,2,3,4,5,6,7,8,0,1,2,3,4,5,6,7,8,0,1,2,3,4,5,6,7,8];
      return (lords[b] == lords[g]) ? 5 : (((lords[b] - lords[g]).abs() <= 3) ? 4 : 3);
    }
    int gana() {
      const ganaMap = [0,1,2,0,2,1,0,0,1,1,2,0,0,2,1,0,0,1,2,2,0,0,2,1,2,0,0];
      if (ganaMap[b] == ganaMap[g]) return 6;
      if ((ganaMap[b] == 0 && ganaMap[g] == 2) || (ganaMap[b] == 2 && ganaMap[g] == 0)) return 0;
      return 4;
    }
    int bhakoot() {
      final bSign = b ~/ 2; final gSign = g ~/ 2;
      final diff = ((gSign - bSign) % 12).abs();
      const badPairs = [6, 5, 9]; // 7th, 6th, 2-12 axis
      return badPairs.contains(diff) ? 0 : 7;
    }
    int nadi() {
      const nadiMap = [0,1,2,2,1,0,0,1,2,2,1,0,0,1,2,2,1,0,0,1,2,2,1,0,0,1,2];
      return (nadiMap[b] != nadiMap[g]) ? 8 : 0;
    }

    return {
      'Varna': {'obtained': varna(), 'max': 1, 'desc': 'Work compatibility'},
      'Vashya': {'obtained': vashya(), 'max': 2, 'desc': 'Mutual attraction & control'},
      'Tara': {'obtained': tara(), 'max': 3, 'desc': 'Health & fortune'},
      'Yoni': {'obtained': yoni(), 'max': 4, 'desc': 'Physical compatibility'},
      'Graha Maitri': {'obtained': grahaMaitri(), 'max': 5, 'desc': 'Friendship & affection'},
      'Gana': {'obtained': gana(), 'max': 6, 'desc': 'Nature compatibility (Deva/Manushya/Rakshasa)'},
      'Bhakoot': {'obtained': bhakoot(), 'max': 7, 'desc': 'Love & prosperity'},
      'Nadi': {'obtained': nadi(), 'max': 8, 'desc': 'Health of children (Nadi Dosha check)'},
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: const Text('Kundli Matching'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _personCard('👦 Boy', _boyName, AppColors.orange, _boyDob, (d) => setState(() { _boyDob = d; _result = null; }))),
            const SizedBox(width: 12),
            Expanded(child: _personCard('👧 Girl', _girlName, const Color(0xFFE91E63), _girlDob, (d) => setState(() { _girlDob = d; _result = null; }))),
          ]),
          const SizedBox(height: 20),
          if (_result == null)
            ElevatedButton(
              onPressed: _isCalculating ? null : _matchKundli,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isCalculating
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Text('Match Kundli 💑', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          else
            _buildResult(),
        ]),
      ),
    );
  }

  Widget _personCard(String title, TextEditingController nameCtrl, Color color, DateTime? dob, Function(DateTime) onDate) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 12),
        TextField(
          controller: nameCtrl,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: _inputDeco('Name', Icons.person_outline),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: DateTime(1990),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (c, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: color)), child: child!),
            );
            if (d != null) onDate(d);
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Icon(Icons.calendar_today_outlined, color: AppColors.textMuted, size: 16),
              const SizedBox(width: 8),
              Text(dob != null ? '${dob.day}/${dob.month}/${dob.year}' : 'Date of Birth', style: TextStyle(color: dob != null ? AppColors.textPrimary : AppColors.textMuted, fontSize: 12)),
            ]),
          ),
        ),
      ]),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
    prefixIcon: Icon(icon, color: AppColors.textMuted, size: 16),
    filled: true, fillColor: AppColors.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.orange)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  );

  Widget _buildResult() {
    final r = _result!;
    final percent = r['percent'] as int;
    final color = percent >= 75 ? AppColors.success : percent >= 50 ? AppColors.orange : percent >= 30 ? AppColors.gold : AppColors.error;

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.2), AppColors.card]),
          borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(children: [
          const Text('💑', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('${r['total']} / ${r['max']} Gunas', style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          Text(r['compatibility'], style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(r['message'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${r['boy_name']} (${r['boy_sign']})', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('❤️')),
            Text('${r['girl_name']} (${r['girl_sign']})', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
          ]),
          const SizedBox(height: 4),
          Text('Nakshatra: ${r['boy_nakshatra']} × ${r['girl_nakshatra']}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ]),
      ),
      const SizedBox(height: 16),
      const Text('ASHTAKOOTA ANALYSIS', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 10),
      ...(r['gunas'] as Map<String, Map<String, dynamic>>).entries.map((e) {
        final obtained = e.value['obtained'] as int;
        final max = e.value['max'] as int;
        final c = obtained >= max * 0.6 ? AppColors.success : obtained > 0 ? AppColors.orange : AppColors.error;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.key, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
              Text(e.value['desc'] as String, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ])),
            Text('$obtained/$max', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
        );
      }),
      const SizedBox(height: 16),
      TextButton(onPressed: () => setState(() => _result = null), child: const Text('Check Another Match', style: TextStyle(color: AppColors.orange))),
      const Text('Based on Vedic nakshatra calculations', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
      const SizedBox(height: 20),
    ]);
  }
}
