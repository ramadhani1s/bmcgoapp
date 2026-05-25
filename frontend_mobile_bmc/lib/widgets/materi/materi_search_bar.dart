import 'package:flutter/material.dart';

class MateriSearchBar extends StatelessWidget {
  const MateriSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.mutedColor,
  });

  final TextEditingController controller;
  final String hint;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: mutedColor),
            hintText: hint,
            hintStyle: TextStyle(color: mutedColor, fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
