import 'dart:convert';

import 'package:frontend_mobile_bmc/models/mentor_latihan_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MentorLatihanService {
  static const String _storageKey = 'mentor_latihan_items';

  static Future<List<MentorLatihanModel>> getAll({String? kelas}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final items =
          decoded
              .whereType<Map<String, dynamic>>()
              .map(MentorLatihanModel.fromJson)
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (kelas == null || kelas == 'Semua Kelas') {
        return items;
      }
      return items.where((e) => e.kelas == kelas).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> saveAll(List<MentorLatihanModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  static Future<MentorLatihanModel> createOrUpdate({
    required String judul,
    required String kelas,
    required String mapel,
    required int jumlahSoal,
    required int durasiMenit,
    required String jadwalPelaksanaan,
    required bool isPublished,
    String? id,
  }) async {
    final items = await getAll();
    final now = DateTime.now();

    if (id == null || id.isEmpty) {
      final created = MentorLatihanModel(
        id: now.microsecondsSinceEpoch.toString(),
        judul: judul,
        kelas: kelas,
        mapel: mapel,
        jumlahSoal: jumlahSoal,
        durasiMenit: durasiMenit,
        jadwalPelaksanaan: jadwalPelaksanaan,
        isPublished: isPublished,
        createdAt: now,
        updatedAt: now,
      );
      await saveAll([created, ...items]);
      return created;
    }

    final updated = items.map((item) {
      if (item.id != id) {
        return item;
      }
      return item.copyWith(
        judul: judul,
        kelas: kelas,
        mapel: mapel,
        jumlahSoal: jumlahSoal,
        durasiMenit: durasiMenit,
        jadwalPelaksanaan: jadwalPelaksanaan,
        isPublished: isPublished,
        updatedAt: now,
      );
    }).toList();

    await saveAll(updated);
    return updated.firstWhere((item) => item.id == id);
  }

  static Future<void> deleteById(String id) async {
    final items = await getAll();
    final filtered = items.where((item) => item.id != id).toList();
    await saveAll(filtered);
  }
}
