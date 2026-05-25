import 'package:flutter/material.dart';

class KategoriFilter extends StatelessWidget {
  const KategoriFilter({
    super.key,
    required this.kategori,
    required this.selected,
    required this.onTap,
    required this.accentColor,
    required this.mutedColor,
  });

  final List<String> kategori;
  final String selected;
  final void Function(String) onTap;
  final Color accentColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: kategori.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final k = kategori[index];
            final isSelected = selected == k;
            return GestureDetector(
              onTap: () => onTap(k),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? accentColor : const Color(0xFFE0E0E0)),
                ),
                child: Text(
                  k,
                  style: TextStyle(
                    color: isSelected ? Colors.white : mutedColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
