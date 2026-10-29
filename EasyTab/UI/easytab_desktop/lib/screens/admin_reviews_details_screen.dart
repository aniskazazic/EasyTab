import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/review.dart';
import 'package:easytab_desktop/providers/review_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminReviewsDetailsScreen extends StatefulWidget {
  final Review review;
  final bool editMode;

  const AdminReviewsDetailsScreen({
    super.key,
    required this.review,
    this.editMode = false,
  });

  @override
  State<AdminReviewsDetailsScreen> createState() =>
      _AdminReviewsDetailsScreenState();
}

class _AdminReviewsDetailsScreenState extends State<AdminReviewsDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late bool _isEditing;
  int? _rating;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.review.description);
    _rating = widget.review.rating;
    _isEditing = widget.editMode;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await context.read<ReviewProvider>().update(widget.review.id!, {
        'description': _controller.text.trim(),
        'rating': _rating,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _saveError = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: _isEditing ? 'Uredi recenziju' : 'Detalji recenzije',
      showCloseButton: true,
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 30),
                Text(
                  "Recenzent: ${widget.review.userFullName ?? 'Korisnik'}",
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text('Lokal: ${widget.review.localeName ?? ''}'),
                const SizedBox(height: 20),
                if (_isEditing)
                  SizedBox(
                    width: 600,
                    child: DropdownButtonFormField<int>(
                      initialValue: _rating,
                      decoration: const InputDecoration(
                        labelText: 'Ocjena',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(
                        5,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('${index + 1}'),
                        ),
                      ),
                      onChanged: _isSaving
                          ? null
                          : (value) => setState(() => _rating = value),
                      validator: (value) =>
                          value == null ? 'Odaberite ocjenu od 1 do 5.' : null,
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < (_rating ?? 0) ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 30,
                      );
                    }),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 600,
                  child: TextFormField(
                    controller: _controller,
                    readOnly: !_isEditing || _isSaving,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Opis recenzije',
                    ),
                    maxLines: 5,
                    maxLength: 1000,
                    validator: (value) {
                      final description = value?.trim() ?? '';
                      if (description.isEmpty) {
                        return 'Opis recenzije je obavezan.';
                      }
                      if (description.length > 1000) {
                        return 'Opis recenzije ne može imati više od 1000 karaktera.';
                      }
                      return null;
                    },
                  ),
                ),
                if (_saveError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _saveError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Nazad'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSaving
                          ? null
                          : _isEditing
                          ? _save
                          : () => setState(() => _isEditing = true),

                      label: Text(
                        _isSaving
                            ? 'Spremanje...'
                            : _isEditing
                            ? 'Spremi'
                            : 'Uredi',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
