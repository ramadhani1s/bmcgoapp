import 'package:flutter/material.dart';

import '../../services/tryout_service.dart';
import '../../widgets/tryout/package_card.dart';
import 'tryout_exam_screen.dart';

class TryOutListScreen extends StatefulWidget {
  const TryOutListScreen({super.key});

  @override
  State<TryOutListScreen> createState() => _TryOutListScreenState();
}

class _TryOutListScreenState extends State<TryOutListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _packages = [];
  String _tab = 'Tersedia';

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    setState(() => _isLoading = true);
    final list = await TryOutService.getPackages();
    setState(() {
      _packages = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Try Out'), backgroundColor: const Color(0xFFFF7070)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: ['Tersedia', 'Riwayat', 'Jadwal'].map((t) {
                final sel = t == _tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t),
                    selected: sel,
                    onSelected: (_) => setState(() => _tab = t),
                    selectedColor: const Color(0xFFFF7070),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7070)))
                : _packages.isEmpty
                    ? const Center(child: Text('Tidak ada paket Try Out'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (c, i) {
                          final p = _packages[i];
                          return PackageCard(
                            data: p,
                            onStart: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => TryOutExamScreen(package: p)));
                            },
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: _packages.length,
                      ),
          ),
        ],
      ),
    );
  }
}
