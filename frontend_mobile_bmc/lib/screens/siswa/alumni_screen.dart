import 'package:flutter/material.dart';
import 'package:frontend_mobile_bmc/config/api_config.dart';
import 'package:frontend_mobile_bmc/models/alumni_model.dart';
import 'package:frontend_mobile_bmc/services/alumni_service.dart';

class AlumniScreen extends StatefulWidget {
  const AlumniScreen({super.key});

  @override
  State<AlumniScreen> createState() => _AlumniScreenState();
}

class _AlumniScreenState extends State<AlumniScreen> {
  static const Color _accent = Color(0xFFFF7070);
  static const Color _background = Color(0xFFFAF2F3);
  static const Color _textPrimary = Color(0xFF25273D);
  static const Color _textMuted = Color(0xFF8D90A3);
  static const Color _themeGreen = Color(0xFF4CAF50);

  List<AlumniModel> _allAlumni = [];
  List<AlumniModel> _filteredAlumni = [];
  bool _isLoading = true;
  String _selectedYear = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetchAlumni();
  }

  Future<void> _fetchAlumni() async {
    setState(() => _isLoading = true);
    final alumni = await AlumniMobileService.getAllAlumni();
    if (mounted) {
      setState(() {
        _allAlumni = alumni;
        _filterAlumni();
        _isLoading = false;
      });
    }
  }

  void _filterAlumni() {
    if (_selectedYear == 'Semua') {
      _filteredAlumni = List.from(_allAlumni);
    } else {
      final intYear = int.tryParse(_selectedYear);
      _filteredAlumni = _allAlumni.where((item) => item.tahunLulus == intYear).toList();
    }
  }

  void _onYearTap(String year) {
    setState(() {
      _selectedYear = year;
      _filterAlumni();
    });
  }

  String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '${ApiConfig.baseUrl}$cleanPath';
  }

  List<String> get _availableYears {
    final yearsSet = _allAlumni.map((item) => item.tahunLulus.toString()).toSet();
    final yearsList = yearsSet.toList()..sort((a, b) => b.compareTo(a));
    return ['Semua', ...yearsList];
  }



  void _showAlumniDetails(BuildContext context, AlumniModel alumni) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 100,
                      height: 120,
                      color: Colors.grey.shade100,
                      child: alumni.foto.isNotEmpty
                          ? Image.network(
                              getImageUrl(alumni.foto),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.school_outlined, size: 40, color: Colors.grey),
                            )
                          : const Icon(Icons.school_outlined, size: 40, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECEC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Angkatan ${alumni.tahunLulus}',
                            style: const TextStyle(
                              color: _accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          alumni.nama,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.account_balance_rounded, size: 16, color: _textMuted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                alumni.sekolah,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: _textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Prestasi & Pencapaian',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Text(
                  alumni.prestasi.isNotEmpty ? alumni.prestasi : 'Tidak ada detail prestasi tambahan.',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF5A5D75),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _themeGreen))
            : RefreshIndicator(
                onRefresh: _fetchAlumni,
                color: _themeGreen,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      _buildHeader(),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Filter Angkatan Box
                            _buildFilterBox(),
                            const SizedBox(height: 16),
                            
                            // Blue banner promo
                            _buildInfoBanner(),
                            const SizedBox(height: 20),
                            
                            // Title section
                            Text(
                              'Semua Alumni (${_filteredAlumni.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Staggered Masonry Grid List
                            _buildAlumniGrid(),
                            const SizedBox(height: 24),
                            
                            // Bottom join promo card
                            _buildBottomPromo(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1E824C), // Dark green (Emerald)
            Color(0xFF145A32), // Deep forest green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          
          // Title & Subtitle
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Alumni Bimbel',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Bintang Muda Center',
                  style: TextStyle(
                    color: const Color(0xE6FFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Total Alumni stat badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(45),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withAlpha(65),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_allAlumni.length}+',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Total Alumni',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBox() {
    final years = _availableYears;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Angkatan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: years.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final year = years[index];
                final isSelected = _selectedYear == year;
                return GestureDetector(
                  onTap: () => _onYearTap(year),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _accent : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      year == 'Semua' ? 'Semua' : 'Angkatan $year',
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF6B7280),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withAlpha(50),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bangga dengan Prestasi Alumni!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Mereka telah berhasil diterima di berbagai universitas terkemuka.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlumniGrid() {
    if (_filteredAlumni.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Belum ada data alumni.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Smart Staggered Masonry: split left and right columns
    final List<AlumniModel> leftCol = [];
    final List<AlumniModel> rightCol = [];

    for (int i = 0; i < _filteredAlumni.length; i++) {
      if (i % 2 == 0) {
        leftCol.add(_filteredAlumni[i]);
      } else {
        rightCol.add(_filteredAlumni[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: leftCol.asMap().entries.map((entry) {
              final idx = entry.key;
              final alumni = entry.value;
              return _buildGridCard(alumni, idx * 2);
            }).toList(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: rightCol.asMap().entries.map((entry) {
              final idx = entry.key;
              final alumni = entry.value;
              return _buildGridCard(alumni, idx * 2 + 1);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGridCard(AlumniModel alumni, int index) {
    // Generate simulated varying heights to mimic staggered grid
    final double cardHeight = (index % 3 == 0) ? 190.0 : ((index % 3 == 1) ? 220.0 : 170.0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _showAlumniDetails(context, alumni),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: cardHeight,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ]
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Network Image
                alumni.foto.isNotEmpty
                    ? Image.network(
                        getImageUrl(alumni.foto),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildImagePlaceholder(alumni),
                      )
                    : _buildImagePlaceholder(alumni),
                
                // Dark Gradient overlay for text legibility
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withAlpha(150),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.6],
                    ),
                  ),
                ),
                
                // Info Text & Year Badge
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              alumni.nama,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alumni.sekolah,
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Year badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(120),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withAlpha(60),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${alumni.tahunLulus}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  Widget _buildImagePlaceholder(AlumniModel alumni) {
    // Beautiful dynamic color placeholder for images
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFFFF6B6B),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9F43),
      const Color(0xFF00D2D3),
    ];
    final color = colors[alumni.id % colors.length];
    
    return Container(
      color: color,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school_outlined,
              color: Colors.white60,
              size: 32,
            ),
            const SizedBox(height: 6),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withAlpha(60),
              child: Text(
                alumni.nama.isNotEmpty ? alumni.nama[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPromo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.military_tech_rounded,
              color: _accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kamu Bisa Jadi Salah Satunya!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Bergabunglah dengan Bimbel Bintang Muda Center dan raih prestasi gemilang seperti kakak-kakak alumni kami.',
                  style: TextStyle(
                    fontSize: 11,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
