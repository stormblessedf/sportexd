import 'package:flutter/material.dart';

class CommentTextField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const CommentTextField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: 4,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Share your experience...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            counterText: '',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${controller.text.length}/200',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: controller.text.length > 200
                    ? Colors.red
                    : Colors.grey[600],
              ),
        ),
      ],
    );
  }
}
