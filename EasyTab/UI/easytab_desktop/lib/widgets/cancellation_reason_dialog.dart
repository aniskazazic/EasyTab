import 'package:flutter/material.dart';

class CancellationReasonDialog extends StatefulWidget {
  final String description;
  final String hint;
  final String? refundMessage;

  const CancellationReasonDialog({
    super.key,
    required this.description,
    required this.hint,
    this.refundMessage,
  });

  @override
  State<CancellationReasonDialog> createState() =>
      _CancellationReasonDialogState();
}

class _CancellationReasonDialogState extends State<CancellationReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  String _reason = '';

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Row(
      children: [
        const Expanded(child: Text('Otkaži rezervaciju')),
        IconButton(
          tooltip: 'Zatvori',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
    content: Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          if (widget.refundMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(widget.refundMessage!),
            ),
          const SizedBox(height: 12),
          TextFormField(
            maxLength: 1000,
            maxLines: 3,
            onChanged: (value) => _reason = value.trim(),
            validator: (value) => (value ?? '').trim().isEmpty
                ? 'Razlog otkazivanja je obavezan.'
                : null,
            decoration: InputDecoration(
              labelText: 'Razlog otkazivanja (obavezno)',
              hintText: widget.hint,
              border: const OutlineInputBorder(),
              errorMaxLines: 3,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Odustani'),
      ),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.pop(context, _reason);
          }
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        child: const Text(
          'Otkaži rezervaciju',
          style: TextStyle(color: Colors.white),
        ),
      ),
    ],
  );
}
