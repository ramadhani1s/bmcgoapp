import 'package:flutter/material.dart';

class OlimpiadeHeader extends StatelessWidget {
  const OlimpiadeHeader({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onTabSelected,
    required this.accentColor,
  });

  final List<Map<String, String>> tabs;
  final String selected;
  final void Function(String) onTabSelected;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.22 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Olimpiade', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                    Text('Kompetisi akademik untuk asah kemampuan', style: TextStyle(color: Color(0xFFFFE5E5), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: tabs.map((tab) {
              final isSelected = selected == tab['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onTabSelected(tab['value']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? Colors.white : Colors.white.withAlpha((0.5 * 255).round())),
                    ),
                    child: Text(
                      tab['label']!,
                      style: TextStyle(
                        color: isSelected ? accentColor : Colors.white,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
