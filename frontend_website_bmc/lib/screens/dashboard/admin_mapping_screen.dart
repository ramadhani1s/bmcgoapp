import 'package:flutter/material.dart';
import '../../services/admin_mapping_service.dart';

class AdminMappingScreen extends StatefulWidget {
  const AdminMappingScreen({super.key});

  @override
  State<AdminMappingScreen> createState() => _AdminMappingScreenState();
}

class _AdminMappingScreenState extends State<AdminMappingScreen> {
  static const Color _primaryPurple = Color(0xFF7C3AED);
  static const Color _border = Color(0xFFDDE4F0);
  static const Color _textDark = Color(0xFF1E2A3E);
  static const Color _textLight = Color(0xFF667287);

  bool _loading = true;
  bool _syncing = false;
  List<dynamic> _mappings = [];
  List<dynamic> _users = [];
  final Map<int, int?> _selectedUsers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        AdminMappingService.getMappings(),
        AdminMappingService.getUsers(),
      ]);
      if (!mounted) return;
      setState(() {
        _mappings = results[0];
        _users = results[1];
        _selectedUsers.clear();
        for (final row in _mappings) {
          final adminId = row['admin_id'] as int?;
          final userId = row['user_id'] as int?;
          if (adminId != null) {
            _selectedUsers[adminId] = userId;
          }
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data mapping')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final result = await AdminMappingService.syncMappings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Sinkron selesai'),
          backgroundColor: result['status'] == 'success'
              ? Colors.green
              : Colors.red,
        ),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _save(int adminId) async {
    final selectedUserId = _selectedUsers[adminId];
    if (selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih user terlebih dahulu')),
      );
      return;
    }

    final result = await AdminMappingService.updateMapping(
      adminId,
      selectedUserId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? 'Mapping tersimpan'),
        backgroundColor: result['status'] == 'success'
            ? Colors.green
            : Colors.red,
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kelola Mapping Admin',
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sinkronkan user login ke admin, lalu atur pairing manual bila perlu.',
                    style: TextStyle(color: _textLight, fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _syncing ? null : _sync,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              icon: _syncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sync, size: 18),
              label: const Text(
                'Sinkron Otomatis',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F0FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE4D5FF)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF7C3AED), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Panel ini memakai admin.id sebagai FK di tabel pengumuman. Tombol sinkron akan mengisi admin.user_id berdasarkan email yang cocok dengan tabel users.',
                  style: TextStyle(color: Color(0xFF4B3F72), fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  decoration: const BoxDecoration(
                    color: _primaryPurple,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Daftar Mapping Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_mappings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Belum ada data admin'),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _headerRow(),
                        const SizedBox(height: 8),
                        for (final row in _mappings) ...[
                          _mappingRow(row),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _headerRow() {
    return const Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            'ADMIN',
            style: TextStyle(
              color: Color(0xFF9AA4B6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'EMAIL',
            style: TextStyle(
              color: Color(0xFF9AA4B6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'USER TERPAKAI',
            style: TextStyle(
              color: Color(0xFF9AA4B6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'PILIH USER',
            style: TextStyle(
              color: Color(0xFF9AA4B6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'AKSI',
            style: TextStyle(
              color: Color(0xFF9AA4B6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _mappingRow(dynamic row) {
    final adminId = row['admin_id'] as int;
    final adminName = row['admin_name']?.toString() ?? '-';
    final adminEmail = row['admin_email']?.toString() ?? '-';
    final currentUserName = row['user_name']?.toString();
    final currentUserEmail = row['user_email']?.toString();
    final selectedUserId = _selectedUsers[adminId];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF6)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              adminName,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              adminEmail,
              style: const TextStyle(fontSize: 12, color: _textLight),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              currentUserName == null
                  ? 'Belum terhubung'
                  : '$currentUserName${currentUserEmail != null ? ' ($currentUserEmail)' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: currentUserName == null
                    ? const Color(0xFFB45309)
                    : const Color(0xFF15803D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              initialValue: selectedUserId,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border),
                ),
              ),
              hint: const Text('Pilih user'),
              items: _users.map((user) {
                final userId = user['id'] as int;
                final nama = user['nama']?.toString() ?? '-';
                final email = user['email']?.toString() ?? '-';
                return DropdownMenuItem<int>(
                  value: userId,
                  child: Text(
                    '$nama (#$userId) - $email',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedUsers[adminId] = value;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _save(adminId),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B58E8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'Simpan',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
