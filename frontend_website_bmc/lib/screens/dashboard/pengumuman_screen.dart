import 'package:flutter/material.dart';
import '../../services/pengumuman_service.dart';

class PengumumanScreen extends StatefulWidget {
  const PengumumanScreen({super.key});

  @override
  State<PengumumanScreen> createState() => _PengumumanScreenModernState();
}

class _PengumumanScreenModernState extends State<PengumumanScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryPurple = Color(0xFF7C3AED);
  static const Color _primaryBlue = Color(0xFF3B82F6);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _warningOrange = Color(0xFFF59E0B);
  static const Color _dangerRed = Color(0xFFEF4444);
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textMedium = Color(0xFF6B7280);
  static const Color _textLight = Color(0xFF9CA3AF);
  static const Color _bgLight = Color(0xFFF9FAFB);
  static const Color _border = Color(0xFFE5E7EB);

  late TabController _tabController;
  bool _loading = true;
  List<dynamic> _items = [];
  List<dynamic> _filteredItems = [];
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  String _selectedStatus = 'Semua';

  final List<String> _categories = [
    'Semua',
    'Umum',
    'Akademik',
    'Event',
    'Pembayaran',
  ];
  final List<String> _statuses = [
    'Semua',
    'Draft',
    'Diterbitkan',
    'Dijadwalkan',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await PengumumanService.getPengumumanList();
      if (!mounted) return;
      setState(() {
        _items = list;
        _applyFilters();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    _filteredItems = _items.where((item) {
      final judul = (item['judul'] ?? '').toString().toLowerCase();
      final isi = (item['isi'] ?? '').toString().toLowerCase();
      final kategori = (item['kategori'] ?? 'Umum').toString();
      final status = (item['status'] ?? 'Diterbitkan').toString();

      final matchesSearch =
          judul.contains(_searchQuery.toLowerCase()) ||
          isi.contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'Semua' || kategori == _selectedCategory;
      final matchesStatus =
          _selectedStatus == 'Semua' || status == _selectedStatus;

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'Semua';
      _selectedStatus = 'Semua';
      _applyFilters();
    });
  }

  int _getStatusCount(String status) {
    if (status == 'Semua') return _items.length;
    return _items
        .where((item) => (item['status'] ?? 'Diterbitkan').toString() == status)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgLight,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            _buildStatsSection(),
            _buildSearchFilterSection(),
            _buildContentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryPurple, _primaryPurple.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kelola Pengumuman',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buat, kelola, dan terbitkan pengumuman',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: ElevatedButton.icon(
                  onPressed: _showCreateModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _primaryPurple,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Buat Pengumuman',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Pengumuman',
                  value: _items.length.toString(),
                  icon: Icons.campaign_rounded,
                  gradient: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                  bgColor: Color(0xFFF3E8FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Diterbitkan',
                  value: _getStatusCount('Diterbitkan').toString(),
                  icon: Icons.check_circle_rounded,
                  gradient: [Color(0xFF10B981), Color(0xFF059669)],
                  bgColor: Color(0xFFD1FAE5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Draft',
                  value: _getStatusCount('Draft').toString(),
                  icon: Icons.edit_rounded,
                  gradient: [Color(0xFF6B7280), Color(0xFF4B5563)],
                  bgColor: Color(0xFFF3F4F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Dijadwalkan',
                  value: _getStatusCount('Dijadwalkan').toString(),
                  icon: Icons.schedule_rounded,
                  gradient: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  bgColor: Color(0xFFDEF2FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
    required Color bgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _textLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari pengumuman berdasarkan judul atau isi...',
                hintStyle: const TextStyle(
                  color: _textLight,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _textLight,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Category Filter
                PopupMenuButton<String>(
                  initialValue: _selectedCategory,
                  onSelected: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _applyFilters();
                    });
                  },
                  child: _buildFilterChip(
                    'Kategori',
                    _selectedCategory,
                    Icons.category_rounded,
                  ),
                  itemBuilder: (context) => _categories
                      .map(
                        (cat) => PopupMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              if (cat == _selectedCategory)
                                const Icon(Icons.check, color: _primaryPurple)
                              else
                                const SizedBox(width: 24),
                              const SizedBox(width: 8),
                              Text(cat),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(width: 8),
                // Status Filter
                PopupMenuButton<String>(
                  initialValue: _selectedStatus,
                  onSelected: (value) {
                    setState(() {
                      _selectedStatus = value;
                      _applyFilters();
                    });
                  },
                  child: _buildFilterChip(
                    'Status',
                    _selectedStatus,
                    Icons.filter_list_rounded,
                  ),
                  itemBuilder: (context) => _statuses
                      .map(
                        (status) => PopupMenuItem(
                          value: status,
                          child: Row(
                            children: [
                              if (status == _selectedStatus)
                                const Icon(Icons.check, color: _primaryPurple)
                              else
                                const SizedBox(width: 24),
                              const SizedBox(width: 8),
                              Text(status),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(width: 8),
                // Reset Button
                if (_searchQuery.isNotEmpty ||
                    _selectedCategory != 'Semua' ||
                    _selectedStatus != 'Semua')
                  OutlinedButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryPurple,
                      side: const BorderSide(color: _primaryPurple, width: 1.2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _textMedium),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: _textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: _textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_drop_down_rounded,
            size: 18,
            color: _textMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // List Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryPurple,
                    _primaryPurple.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Daftar Pengumuman',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Text(
                      '${_filteredItems.length} item',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // List Content
            if (_loading)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: _primaryPurple),
                    const SizedBox(height: 16),
                    Text(
                      'Memuat pengumuman...',
                      style: TextStyle(
                        color: _textMedium,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else if (_filteredItems.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _bgLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.campaign_rounded,
                        size: 40,
                        color: _textLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada pengumuman',
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mulai buat pengumuman pertama Anda sekarang',
                      style: TextStyle(
                        color: _textMedium,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredItems.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 0, color: _border, thickness: 1),
                itemBuilder: (context, index) =>
                    _buildAnnouncementCard(_filteredItems[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(dynamic item) {
    final judul = (item['judul'] ?? 'N/A').toString();
    final isi = (item['isi'] ?? '').toString();
    final createdAt = (item['created_at'] ?? '').toString();
    final kategori = (item['kategori'] ?? 'Umum').toString();
    final status = (item['status'] ?? 'Diterbitkan').toString();

    return InkWell(
      onTap: () => _showDetailModal(item),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    judul,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Description
                  Text(
                    _truncateText(isi, 100),
                    style: const TextStyle(
                      color: _textMedium,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildTag(kategori, _getCategoryColor(kategori)),
                      _buildTag(status, _getStatusColor(status)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Actions
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Date
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(
                    color: _textLight,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: Icons.visibility_rounded,
                      color: _primaryBlue,
                      onPressed: () => _showDetailModal(item),
                    ),
                    const SizedBox(width: 6),
                    _buildActionButton(
                      icon: Icons.edit_rounded,
                      color: _warningOrange,
                      onPressed: () => _showEditModal(item),
                    ),
                    const SizedBox(width: 6),
                    _buildActionButton(
                      icon: Icons.delete_rounded,
                      color: _dangerRed,
                      onPressed: () => _showDeleteConfirmation(item),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Color _getCategoryColor(String kategori) {
    switch (kategori) {
      case 'Akademik':
        return Color(0xFF3B82F6);
      case 'Event':
        return Color(0xFFEF4444);
      case 'Pembayaran':
        return Color(0xFF10B981);
      default:
        return Color(0xFF7C3AED);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Draft':
        return Color(0xFF6B7280);
      case 'Dijadwalkan':
        return Color(0xFFF59E0B);
      case 'Diterbitkan':
        return Color(0xFF10B981);
      default:
        return Color(0xFF7C3AED);
    }
  }

  // Modal Dialogs

  Future<void> _showCreateModal() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final judulController = TextEditingController();
    final isiController = TextEditingController();
    String selectedKategori = 'Umum';
    String selectedTarget = 'Semua';
    String selectedStatus = 'Draft';
    bool isPinned = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        final dialogNavigator = Navigator.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setDialogState) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 840,
                maxHeight: MediaQuery.of(ctx).size.height * 0.9,
              ),
              child: SingleChildScrollView(
                child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF1D4ED8),
                                        Color(0xFF2563EB),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.campaign_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Buat Pengumuman Baru',
                                  style: TextStyle(
                                    color: _textDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Isi form di bawah untuk membuat pengumuman baru',
                              style: TextStyle(
                                color: _textMedium,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _bgLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: _textMedium,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Form Fields
                    _buildModalFieldLabel('Judul Pengumuman', required: true),
                    const SizedBox(height: 8),
                    _buildModalTextField(
                      controller: judulController,
                      hintText: 'Masukkan judul pengumuman',
                    ),
                    const SizedBox(height: 16),
                    _buildModalFieldLabel('Isi Pengumuman', required: true),
                    const SizedBox(height: 8),
                    _buildModalTextField(
                      controller: isiController,
                      hintText: 'Tulis isi pengumuman di sini...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    // Dropdowns Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModalFieldLabel('Kategori'),
                              const SizedBox(height: 8),
                              _buildModalDropdown(
                                value: selectedKategori,
                                items: const [
                                  'Umum',
                                  'Akademik',
                                  'Event',
                                  'Pembayaran',
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(
                                      () => selectedKategori = value,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModalFieldLabel('Target Penerima'),
                              const SizedBox(height: 8),
                              _buildModalDropdown(
                                value: selectedTarget,
                                items: const [
                                  'Semua',
                                  'Siswa',
                                  'Mentor',
                                  'Orang Tua',
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(
                                      () => selectedTarget = value,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Status and Pin
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModalFieldLabel('Status'),
                              const SizedBox(height: 8),
                              _buildModalDropdown(
                                value: selectedStatus,
                                items: const [
                                  'Draft',
                                  'Diterbitkan',
                                  'Dijadwalkan',
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(
                                      () => selectedStatus = value,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModalFieldLabel('Pin Pengumuman'),
                              const SizedBox(height: 8),
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _bgLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _border, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Transform.scale(
                                        scale: 0.85,
                                        child: Switch(
                                          value: isPinned,
                                          onChanged: (value) {
                                            setDialogState(
                                              () => isPinned = value,
                                            );
                                          },
                                          activeThumbColor: _primaryBlue,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      isPinned ? 'Ya' : 'Tidak',
                                      style: TextStyle(
                                        color: isPinned
                                            ? _primaryBlue
                                            : _textMedium,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textDark,
                            side: const BorderSide(color: _border, width: 1.5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (judulController.text.trim().isEmpty ||
                                isiController.text.trim().isEmpty) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Judul dan isi tidak boleh kosong',
                                  ),
                                  backgroundColor: _dangerRed,
                                ),
                              );
                              return;
                            }

                            try {
                              final result =
                                  await PengumumanService.createPengumuman({
                                    'judul': judulController.text.trim(),
                                    'isi': isiController.text.trim(),
                                    'kategori': selectedKategori,
                                    'target': selectedTarget,
                                    'status': selectedStatus,
                                    'pinned': isPinned,
                                  });

                              if (!mounted) return;

                              if (result['status'] == 'success') {
                                dialogNavigator.pop();
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result['message']?.toString() ??
                                          'Pengumuman berhasil dibuat',
                                    ),
                                    backgroundColor: _successGreen,
                                  ),
                                );
                                _load();
                              } else {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result['message']?.toString() ??
                                          'Gagal membuat pengumuman',
                                    ),
                                    backgroundColor: _dangerRed,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: _dangerRed,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text(
                            'Buat Pengumuman',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDetailModal(dynamic item) async {
    final judul = (item['judul'] ?? 'N/A').toString();
    final isi = (item['isi'] ?? '').toString();
    final createdAt = (item['created_at'] ?? '').toString();
    final kategori = (item['kategori'] ?? 'Umum').toString();
    final target = (item['target'] ?? 'Semua').toString();
    final status = (item['status'] ?? 'Diterbitkan').toString();

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 840,
            maxHeight: MediaQuery.of(ctx).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - NOT in Flexible
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1D4ED8),
                                    Color(0xFF2563EB),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.campaign_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Detail Pengumuman',
                              style: TextStyle(
                                color: _textDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Informasi lengkap pengumuman',
                          style: TextStyle(
                            color: _textMedium,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _bgLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: _textMedium,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content - IN Flexible for scrolling
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildDetailTag(kategori, _getCategoryColor(kategori)),
                            _buildDetailTag(target, Color(0xFFD97706)),
                            _buildDetailTag(status, _getStatusColor(status)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Title
                        Text(
                          judul,
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Content
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _bgLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _border, width: 1),
                          ),
                          child: Text(
                            isi,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: _textMedium,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Info
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _bgLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _border, width: 1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dibuat',
                                      style: const TextStyle(
                                        color: _textLight,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(createdAt),
                                      style: const TextStyle(
                                        color: _textDark,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Diterbitkan',
                                      style: const TextStyle(
                                        color: _textLight,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(createdAt),
                                      style: const TextStyle(
                                        color: _textDark,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dibuat Oleh',
                                      style: const TextStyle(
                                        color: _textLight,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Admin',
                                      style: TextStyle(
                                        color: _textDark,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Close Button - NOT in Flexible
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textDark,
                      side: const BorderSide(color: _border, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditModal(dynamic item) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final id = item['id'];
    final judulController = TextEditingController(
      text: (item['judul'] ?? '').toString(),
    );
    final isiController = TextEditingController(
      text: (item['isi'] ?? '').toString(),
    );

    String selectedKategori = (item['kategori'] ?? 'Umum').toString();
    String selectedTarget = (item['target'] ?? 'Semua').toString();
    String selectedStatus = (item['status'] ?? 'Diterbitkan').toString();
    bool isPinned = (item['pinned'] is bool) ? item['pinned'] as bool : false;

    await showDialog(
      context: context,
      builder: (ctx) {
        final dialogNavigator = Navigator.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setDialogState) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 840,
                maxHeight: MediaQuery.of(ctx).size.height * 0.9,
              ),
              child: SingleChildScrollView(
                child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF1D4ED8),
                                        Color(0xFF2563EB),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Edit Pengumuman',
                                  style: TextStyle(
                                    color: _textDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ubah isi atau pengaturan pengumuman',
                              style: TextStyle(
                                color: _textMedium,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _bgLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: _textMedium,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Form Fields (sama seperti create modal)
                    _buildModalFieldLabel('Judul Pengumuman', required: true),
                    const SizedBox(height: 8),
                    _buildModalTextField(
                      controller: judulController,
                      hintText: 'Masukkan judul pengumuman',
                    ),
                    const SizedBox(height: 16),
                    _buildModalFieldLabel('Isi Pengumuman', required: true),
                    const SizedBox(height: 8),
                    _buildModalTextField(
                      controller: isiController,
                      hintText: 'Tulis isi pengumuman di sini...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModalFieldLabel('Kategori'),
                              const SizedBox(height: 8),
                              _buildModalDropdown(
                                value: selectedKategori,
                                items: const [
                                  'Umum',
                                  'Akademik',
                                  'Event',
                                  'Pembayaran',
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(
                                      () => selectedKategori = value,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModalFieldLabel('Target Penerima'),
                              const SizedBox(height: 8),
                              _buildModalDropdown(
                                value: selectedTarget,
                                items: const [
                                  'Semua',
                                  'Siswa',
                                  'Mentor',
                                  'Orang Tua',
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(
                                      () => selectedTarget = value,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModalFieldLabel('Status'),
                              const SizedBox(height: 8),
                              _buildModalDropdown(
                                value: selectedStatus,
                                items: const [
                                  'Draft',
                                  'Diterbitkan',
                                  'Dijadwalkan',
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(
                                      () => selectedStatus = value,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModalFieldLabel('Pin Pengumuman'),
                              const SizedBox(height: 8),
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _bgLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _border, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Transform.scale(
                                        scale: 0.85,
                                        child: Switch(
                                          value: isPinned,
                                          onChanged: (value) {
                                            setDialogState(
                                              () => isPinned = value,
                                            );
                                          },
                                          activeThumbColor: _warningOrange,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      isPinned ? 'Ya' : 'Tidak',
                                      style: TextStyle(
                                        color: isPinned
                                            ? _warningOrange
                                            : _textMedium,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textDark,
                            side: const BorderSide(color: _border, width: 1.5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (judulController.text.trim().isEmpty ||
                                isiController.text.trim().isEmpty) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Judul dan isi tidak boleh kosong',
                                  ),
                                  backgroundColor: _dangerRed,
                                ),
                              );
                              return;
                            }

                            try {
                              final result =
                                  await PengumumanService.updatePengumuman(id, {
                                    'judul': judulController.text.trim(),
                                    'isi': isiController.text.trim(),
                                    'kategori': selectedKategori,
                                    'target': selectedTarget,
                                    'status': selectedStatus,
                                    'pinned': isPinned,
                                  });

                              if (!mounted) return;

                              if (result['status'] == 'success') {
                                dialogNavigator.pop();
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result['message']?.toString() ??
                                          'Pengumuman berhasil diperbarui',
                                    ),
                                    backgroundColor: _successGreen,
                                  ),
                                );
                                _load();
                              } else {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result['message']?.toString() ??
                                          'Gagal memperbarui pengumuman',
                                    ),
                                    backgroundColor: _dangerRed,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: _dangerRed,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(dynamic item) async {
    final id = item['id'];
    final judul = (item['judul'] ?? 'pengumuman ini').toString();

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon & Title
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      color: _dangerRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Hapus Pengumuman?',
                      style: TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Message
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: _textMedium,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    const TextSpan(text: 'Anda akan menghapus pengumuman '),
                    TextSpan(
                      text: '"$judul"',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                    const TextSpan(
                      text: '. Tindakan ini tidak dapat dibatalkan.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textDark,
                      side: const BorderSide(color: _border, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        Navigator.pop(ctx);
                        final result = await PengumumanService.deletePengumuman(
                          id,
                        );

                        if (!mounted) return;

                        if (result['status'] == 'success') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message']?.toString() ??
                                    'Pengumuman berhasil dihapus',
                              ),
                              backgroundColor: _successGreen,
                            ),
                          );
                          _load();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message']?.toString() ??
                                    'Gagal menghapus pengumuman',
                              ),
                              backgroundColor: _dangerRed,
                            ),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: _dangerRed,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_rounded, size: 18),
                    label: const Text(
                      'Ya, Hapus',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _dangerRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widgets

  Widget _buildModalFieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: _textDark,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: -0.2,
        ),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: _dangerRed),
            ),
        ],
      ),
    );
  }

  Widget _buildModalTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: _textLight,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: _bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primaryPurple, width: 2),
        ),
        contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      ),
      style: const TextStyle(
        color: _textDark,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildModalDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _bgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: _textMedium,
            size: 22,
          ),
          style: const TextStyle(
            color: _textDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDetailTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    return text.length > maxLength
        ? '${text.substring(0, maxLength)}...'
        : text;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
