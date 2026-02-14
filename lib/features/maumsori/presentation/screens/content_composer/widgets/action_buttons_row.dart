import 'package:flutter/material.dart';

class ActionButtonsRow extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onSave;
  final bool canSave;

  const ActionButtonsRow({
    super.key,
    required this.onReset,
    required this.onSave,
    required this.canSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(onPressed: onReset, child: const Text('초기화')),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: canSave ? onSave : null,
            child: const Text('저장 및 발행'),
          ),
        ),
      ],
    );
  }
}
