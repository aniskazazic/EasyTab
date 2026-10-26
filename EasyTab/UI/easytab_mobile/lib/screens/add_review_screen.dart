import 'package:easytab_mobile/models/review.dart';
import 'package:easytab_mobile/exceptions/api_exception.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/review_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easytab_mobile/widgets/form_feedback.dart';

class AddReviewScreen extends StatefulWidget {
  final int localeId;
  final Review? existingReview; // null = dodavanje, not null = editovanje
  final VoidCallback? onSaved;

  const AddReviewScreen({
    super.key,
    required this.localeId,
    this.existingReview,
    this.onSaved,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  late ReviewProvider _reviewProvider;
  final _descController = TextEditingController();
  int _selectedRating = 0;
  bool _isLoading = false;
  bool _isChecking = true;
  String? _prerequisiteError;
  String? _ratingError;
  String? _descriptionError;

  bool get _isEdit => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    _reviewProvider = context.read<ReviewProvider>();

    // Popuni ako edit
    if (_isEdit) {
      _selectedRating = widget.existingReview!.rating?.toInt() ?? 0;
      _descController.text = widget.existingReview!.description ?? '';
    }
    _checkPrerequisites();
  }

  Future<void> _checkPrerequisites() async {
    setState(() {
      _isChecking = true;
      _prerequisiteError = null;
    });
    String? error;
    try {
      if (AuthProvider.currentUserId == null || widget.localeId <= 0) {
        error = 'Prijavite se i odaberite dostupan lokal za recenziju.';
      } else if (_isEdit) {
        if (widget.existingReview!.id == null ||
            widget.existingReview!.userId != AuthProvider.currentUserId) {
          error = 'Možete uređivati samo svoju recenziju.';
        }
      } else {
        final eligibility = await _reviewProvider.canReview(widget.localeId);
        if (!eligibility.canReview) {
          error =
              eligibility.reason ??
              'Trenutno ne možete dodati recenziju za ovaj lokal.';
        }
      }
    } catch (e) {
      error = userError(e);
    }
    if (mounted) {
      setState(() {
        _prerequisiteError = error;
        _isChecking = false;
      });
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (mounted) showFeedback(context, message, error: true);
  }

  Future<void> _handleSave() async {
    if (_isLoading || _isChecking || _prerequisiteError != null) return;
    setState(() {
      _ratingError = _selectedRating < 1 || _selectedRating > 5
          ? 'Odaberite ocjenu od 1 do 5 zvjezdica.'
          : null;
      _descriptionError = _descController.text.trim().isEmpty
          ? 'Unesite opis recenzije (1–1000 karaktera).'
          : null;
    });
    if (_ratingError != null || _descriptionError != null) return;

    setState(() => _isLoading = true);

    try {
      if (_isEdit) {
        await _reviewProvider.editReview(
          reviewId: widget.existingReview!.id!,
          rating: _selectedRating,
          description: _descController.text.trim(),
        );
      } else {
        await _reviewProvider.addReview(
          localeId: widget.localeId,
          rating: _selectedRating,
          description: _descController.text.trim(),
        );
      }

      if (!mounted) return;
      showFeedback(
        context,
        _isEdit
            ? 'Recenzija je uspješno izmijenjena.'
            : 'Recenzija je uspješno dodana.',
      );
      widget.onSaved?.call();
      Navigator.pop(context, true);
    } on ApiClientException catch (e) {
      if (!mounted) return;
      var handled = false;
      for (final entry in e.validationErrors.entries) {
        final key = entry.key.split('.').last.toLowerCase();
        if (key == 'rating') {
          _ratingError = entry.value.join('\n');
          handled = true;
        }
        if (key == 'description') {
          _descriptionError = entry.value.join('\n');
          handled = true;
        }
      }
      if (handled) {
        setState(() {});
      } else {
        _showError(e.message);
      }
    } catch (e) {
      _showError(userError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isChecking
                ? const Center(child: CircularProgressIndicator())
                : _prerequisiteError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_prerequisiteError!, textAlign: TextAlign.center),
                        TextButton(
                          onPressed: _checkPrerequisites,
                          child: const Text('Provjeri ponovo'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Ocjena
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _ratingError != null
                                  ? Colors.red.shade300
                                  : Colors.grey.shade200,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Ukupna ocjena *',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (i) {
                                  return GestureDetector(
                                    onTap: _isLoading
                                        ? null
                                        : () => setState(() {
                                            _selectedRating = i + 1;
                                            _ratingError = null;
                                          }),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Icon(
                                        i < _selectedRating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: const Color(0xFFFBBF24),
                                        size: 32,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              if (_selectedRating > 0) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _ratingLabel(_selectedRating),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_ratingError != null)
                          Text(
                            _ratingError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Opis
                        const Text(
                          'Ostavite opis *',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _descController,
                          enabled: !_isLoading,
                          maxLength: 1000,
                          onChanged: (_) {
                            if (_descriptionError != null) {
                              setState(() => _descriptionError = null);
                            }
                          },
                          maxLines: 6,
                          decoration: InputDecoration(
                            errorText: _descriptionError,
                            errorMaxLines: 3,
                            hintText: 'Podijelite svoje iskustvo...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Dugme
          if (!_isChecking && _prerequisiteError == null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Spremi izmjene' : 'Dodaj recenziju',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1E40AF),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        20,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _isEdit ? 'Uredi recenziju' : 'Napiši recenziju',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Zatvori',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Užasno';
      case 2:
        return 'Loše';
      case 3:
        return 'Prosječno';
      case 4:
        return 'Dobro';
      case 5:
        return 'Odlično';
      default:
        return '';
    }
  }
}
