import 'package:easytab_mobile/models/review.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/review_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _handleSave() async {
    if (_selectedRating == 0) {
      _showError('Odaberite ocjenu!');
      return;
    }
    if (_descController.text.trim().isEmpty) {
      _showError('Unesite opis recenzije!');
      return;
    }

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
          userId: AuthProvider.currentUser!.id!,
          rating: _selectedRating,
          description: _descController.text.trim(),
        );
      }

      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
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
            child: SingleChildScrollView(
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
                        color: _selectedRating == 0
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
                              onTap: () =>
                                  setState(() => _selectedRating = i + 1),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Icon(
                                  i < _selectedRating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: const Color(0xFFFBBF24),
                                  size: 42,
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
                  const SizedBox(height: 24),

                  // Opis
                  const Text(
                    'Ostavite opis *',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Podijelite svoje iskustvo...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF1E40AF)),
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
            child: const Icon(Icons.close, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Text(
            _isEdit ? 'Uredi recenziju' : 'Napiši recenziju',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
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
