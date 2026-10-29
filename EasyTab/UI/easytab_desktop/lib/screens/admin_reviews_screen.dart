import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/review.dart';
import 'package:easytab_desktop/providers/review_provider.dart';
import 'package:easytab_desktop/screens/admin_reviews_details_screen.dart';
import 'package:easytab_desktop/providers/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  bool isLoading = false;
  late ReviewProvider _reviewProvider;
  int _totalCount = 0;
  int _currentPage = 0;
  final int _pageSize = 10;
  bool showDeleted = false;
  List<Review> _reviews = [];
  bool _initialized = false;
  DateTime? _selectedDate;
  int? _selectedRating;

  final TextEditingController searchController = TextEditingController();
  final Map<int, String> ratings = {
    5: '5 - Odlično',
    4: '4 - Vrlo dobro',
    3: '3 - Dobro',
    2: '2 - Loše',
    1: '1 - Vrlo loše',
    0: 'Sve ocjene',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reviewProvider = context.read<ReviewProvider>();
    if (!_initialized) {
      _initialized = true;
      _loadReviews();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onSearchPressed() {
    setState(() => _currentPage = 0);
    _loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Recenzije',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildSearchAndFilter(),
            const SizedBox(height: 16),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTable(),
            PaginationUtils.buildPageControls(
              currentPage: _currentPage,
              totalCount: _totalCount,
              pageSize: _pageSize,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
                _loadReviews();
              },
              pageButtonSize: 36,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Pretraži po korisniku, lokalu ili opisu...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _onSearchPressed(),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<int>(
              value: _selectedRating ?? 0,
              decoration: InputDecoration(
                labelText: 'Ocjena',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: ratings.entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRating = value == 0 ? null : value;
                  _currentPage = 0;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(
                _selectedDate != null ? _formatDate(_selectedDate!) : 'Datum',
              ),
              onPressed: _pickDate,
            ),
          ),
          if (_selectedDate != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Ukloni filter datuma',
              onPressed: _clearDateFilter,
            ),
          ],
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Pretraži'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
              ),
              onPressed: _onSearchPressed,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadReviews() async {
    setState(() => isLoading = true);
    try {
      final selectedDate = _selectedDate;
      final dateFrom = selectedDate == null
          ? null
          : DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
            ).toUtc();
      final filter = <String, dynamic>{
        "Page": _currentPage + 1,
        "PageSize": _pageSize,
        "IncludeTotalCount": true,
        "IsDeleted": showDeleted,
        if (searchController.text.trim().isNotEmpty)
          "Text": searchController.text.trim(),
        if (_selectedRating != null) "Rating": _selectedRating,
        if (dateFrom != null) "DateFrom": dateFrom.toIso8601String(),
        if (dateFrom != null)
          "DateTo": dateFrom.add(const Duration(days: 1)).toIso8601String(),
      };

      final result = await _reviewProvider.get(filter: filter);
      setState(() {
        _reviews = result.items ?? [];
        _totalCount = result.totalCount ?? _reviews.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError(e.toString());
    }
  }

  String _formatDate(DateTime date) {
    return formatSystemDateOnly(date);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _currentPage = 0;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      _currentPage = 0;
    });
    _loadReviews();
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Greška'),
        content: Text(message.replaceAll("Exception: ", "")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openReview(Review review, {bool editMode = false}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AdminReviewsDetailsScreen(review: review, editMode: editMode),
      ),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recenzija je uspješno ažurirana.')),
    );
    await _loadReviews();
  }

  Widget _buildTable() {
    if (_reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Nema recenzija za prikaz.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF1E40AF)),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          columns: const [
            DataColumn(label: Text('Korisnik')),
            DataColumn(label: Text('Lokal')),
            DataColumn(label: Text('Opis')),
            DataColumn(label: Text('Ocjena')),
            DataColumn(label: Text('Datum recenzije')),
            DataColumn(label: Text('Akcije')),
          ],
          rows: _reviews.map((review) {
            final formattedDate = review.dateAdded != null
                ? _formatDate(review.dateAdded!)
                : '';
            final ratingValue = (review.rating ?? 0).clamp(0, 5);

            return DataRow(
              cells: [
                DataCell(Text(review.userFullName ?? '')),
                DataCell(Text(review.localeName ?? '')),
                DataCell(
                  Text(
                    (review.description?.length ?? 0) > 10
                        ? "${review.description?.substring(0, 10)}..."
                        : review.description ?? '',
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      Text(ratingValue.toString()),
                      const SizedBox(width: 6),
                      Row(
                        children: List.generate(
                          ratingValue,
                          (_) => const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(formattedDate)),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'Detalji',
                        onPressed: () => _openReview(review),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Uredi',
                        onPressed: () => _openReview(review, editMode: true),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Obriši',
                        onPressed: () => _confirmDelete(review),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmDelete(Review review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Brisanje recenzije'),
        content: Text('Da li ste sigurni da želite obrisati ovu recenziju ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteReview(review.id!);
            },
            child: const Text('Obriši', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview(int id) async {
    try {
      await _reviewProvider.delete(id);
      await _loadReviews();
    } catch (e) {
      _showError(e.toString());
    }
  }
}
