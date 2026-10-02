import 'package:flutter/material.dart';

class PinPad extends StatelessWidget {
  final void Function(String) onNumberTapped;
  final VoidCallback onBackspaceTapped;

  const PinPad({
    super.key,
    required this.onNumberTapped,
    required this.onBackspaceTapped,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        for (var i = 1; i <= 9; i++) _buildButton(context, i.toString()),
        const SizedBox.shrink(), // Empty space bottom left
        _buildButton(context, '0'),
        IconButton(
          icon: const Icon(Icons.backspace_outlined, size: 28),
          onPressed: onBackspaceTapped,
        ),
      ],
    );
  }

  Widget _buildButton(BuildContext context, String number) {
    return TextButton(
      style: TextButton.styleFrom(
        shape: const CircleBorder(),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: () => onNumberTapped(number),
      child: Text(
        number,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
      ),
    );
  }
}