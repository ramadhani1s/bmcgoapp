import 'package:flutter/material.dart';
import 'attendance_card_shell.dart';

class AttendanceFilterCard extends StatelessWidget {
  const AttendanceFilterCard({
    super.key,
    required this.classOptions,
    required this.selectedClass,
    required this.selectedDateLabel,
    required this.onClassChanged,
    required this.onPickDate,
    required this.onReset,
  });

  final List<String> classOptions;
  final String selectedClass;
  final String selectedDateLabel;
  final ValueChanged<String> onClassChanged;
  final VoidCallback onPickDate;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return AttendanceCardShell(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Riwayat',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: classOptions.contains(selectedClass)
                ? selectedClass
                : 'Semua Kelas',
            items: classOptions
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onClassChanged(value);
              }
            },
            decoration: InputDecoration(
              labelText: 'Kelas',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickDate,
                  icon: const Icon(Icons.date_range),
                  label: Text(selectedDateLabel),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onReset,
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}