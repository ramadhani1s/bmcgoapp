import 'package:flutter/material.dart';

class TryOutSubmitConfirm extends StatelessWidget {
  final int answered;
  final int total;
  const TryOutSubmitConfirm({super.key, required this.answered, required this.total});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Submit'), backgroundColor: const Color(0xFFFF7070)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Anda telah menjawab $answered dari $total soal.', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            const Text('Setelah submit, Anda tidak dapat mengubah jawaban.', textAlign: TextAlign.center),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7070)), child: const Text('Submit'))
              ],
            )
          ],
        ),
      ),
    );
  }
}
