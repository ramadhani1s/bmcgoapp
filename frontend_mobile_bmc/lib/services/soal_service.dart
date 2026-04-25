import 'package:frontend_mobile_bmc/models/soal_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SoalService {
  static const String _soalPrefix = 'soal_';

  static String _getKey(String latihanId, String soalId) {
    return '$_soalPrefix${latihanId}_$soalId';
  }

  static String _getListKey(String latihanId) {
    return '${_soalPrefix}list_$latihanId';
  }

  static Future<List<SoalModel>> getByLatihanId(String latihanId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getString(_getListKey(latihanId));
      if (listJson == null) return [];

      final List<dynamic> list = jsonDecode(listJson);
      return list
          .map((item) => SoalModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<SoalModel?> getById(String latihanId, String soalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_getKey(latihanId, soalId));
      if (json == null) return null;

      return SoalModel.fromJson(jsonDecode(json));
    } catch (e) {
      return null;
    }
  }

  static Future<void> create(SoalModel soal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soalJson = jsonEncode(soal.toJson());
      await prefs.setString(_getKey(soal.latihanId, soal.id), soalJson);

      // Update list
      final existingList = await getByLatihanId(soal.latihanId);
      final newList = [soal, ...existingList];
      final listJson = jsonEncode(newList.map((e) => e.toJson()).toList());
      await prefs.setString(_getListKey(soal.latihanId), listJson);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> update(SoalModel soal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soalJson = jsonEncode(soal.toJson());
      await prefs.setString(_getKey(soal.latihanId, soal.id), soalJson);

      // Update list
      final existingList = await getByLatihanId(soal.latihanId);
      final newList = existingList
          .map((e) => e.id == soal.id ? soal : e)
          .toList();
      final listJson = jsonEncode(newList.map((e) => e.toJson()).toList());
      await prefs.setString(_getListKey(soal.latihanId), listJson);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteById(String latihanId, String soalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getKey(latihanId, soalId));

      // Update list
      final existingList = await getByLatihanId(latihanId);
      final newList = existingList.where((e) => e.id != soalId).toList();
      final listJson = jsonEncode(newList.map((e) => e.toJson()).toList());
      await prefs.setString(_getListKey(latihanId), listJson);
    } catch (e) {
      rethrow;
    }
  }
}
