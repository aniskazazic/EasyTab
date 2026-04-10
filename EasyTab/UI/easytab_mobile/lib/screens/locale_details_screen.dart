import 'dart:convert';
import 'package:easytab_mobile/models/locale.dart' as model;
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LocaleDetailScreen extends StatefulWidget {
  final model.Locale locale;
  const LocaleDetailScreen({super.key, required this.locale});

  @override
  State<LocaleDetailScreen> createState() => _LocaleDetailScreenState();
}

class _LocaleDetailScreenState extends State<LocaleDetailScreen> {
  bool _isFavourite = false;
  bool _isLoadingReviews = true;
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0;
  Map<String, int> _ratingCounts = {
    'Odlično': 0,
    'Dobro': 0,
    'Prosječno': 0,
    'Loše': 0,
    'Užasno': 0,
  };

  model.Locale get locale => widget.locale;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final baseUrl = BaseProvider.baseUrl ?? 'http://10.0.2.2:5241';
      final headers = _createHeaders();

      final responses = await Future.wait([
        http.get(
          Uri.parse('$baseUrl/Reviews?LocaleId=${locale.id}&RetrieveAll=true'),
          headers: headers,
        ),
        http.get(
          Uri.parse('$baseUrl/Reviews/average/${locale.id}'),
          headers: headers,
        ),
        http.get(
          Uri.parse('$baseUrl/Reviews/rating-counts/${locale.id}'),
          headers: headers,
        ),
      ]);

      if (responses[0].statusCode == 200) {
        final data = jsonDecode(responses[0].body);
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(data['items'] ?? []);
        });
      }

      if (responses[1].statusCode == 200) {
        final data = jsonDecode(responses[1].body);
        setState(
          () => _averageRating = (data['averageRating'] as num).toDouble(),
        );
      }

      if (responses[2].statusCode == 200) {
        final data = jsonDecode(responses[2].body);
        setState(() {
          _ratingCounts = {
            'Odlično': data['excellent'] ?? 0,
            'Dobro': data['good'] ?? 0,
            'Prosječno': data['average'] ?? 0,
            'Loše': data['poor'] ?? 0,
            'Užasno': data['terrible'] ?? 0,
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    } finally {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Map<String, String> _createHeaders() {
    final username = AuthProvider.username ?? '';
    final password = AuthProvider.password ?? '';
    final basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    return {'Content-Type': 'application/json', 'Authorization': basicAuth};
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _dayRange() => 'Pon - Ned';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(),
                _buildInfoCard(),
                const SizedBox(height: 16),
                _buildGallerySection(),
                const SizedBox(height: 16),
                _buildRatingsSection(),
                const SizedBox(height: 16),
                _buildReviewsSection(),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Top dugmad
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleButton(
                  Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
                _circleButton(
                  _isFavourite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavourite ? Colors.red : null,
                  onTap: () => setState(() => _isFavourite = !_isFavourite),
                ),
              ],
            ),
          ),

          // Rezerviši dugme
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: const Color(0xFFF5F7FA),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Rezerviši stol',
                  style: TextStyle(
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

  // ── Hero ──────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      width: double.infinity,
      height: 240,
      color: Colors.white,
      child: locale.logo != null && locale.logo!.isNotEmpty
          ? Image.network(
              locale.logo!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _logoFallback(),
            )
          : _logoFallback(),
    );
  }

  Widget _logoFallback() {
    return Container(
      color: const Color(0xFFEFF6FF),
      child: const Center(
        child: Icon(Icons.store_outlined, size: 72, color: Color(0xFF1E40AF)),
      ),
    );
  }

  // ── Info kartica ──────────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.name ?? '',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),

          // Prosječna ocjena
          if (_averageRating > 0) ...[
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFBBF24), size: 20),
                const SizedBox(width: 4),
                Text(
                  '$_averageRating  (${_reviews.length} recenzije)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          _buildInfoRow(
            Icons.category_outlined,
            'Kategorija',
            locale.categoryName ?? '-',
          ),
          const Divider(height: 24),

          _buildInfoRow(
            Icons.access_time_outlined,
            'Radno vrijeme',
            '${_dayRange()}  ${_formatTime(locale.startOfWorkingHours)} - ${_formatTime(locale.endOfWorkingHours)}',
          ),
          const Divider(height: 24),

          _buildInfoRow(
            Icons.location_on_outlined,
            'Adresa',
            '${locale.address ?? '-'}, ${locale.cityName ?? ''}',
          ),

          if (locale.phoneNumber != null && locale.phoneNumber!.isNotEmpty) ...[
            const Divider(height: 24),
            _buildInfoRow(Icons.phone_outlined, 'Telefon', locale.phoneNumber!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Galerija ──────────────────────────────────────────────────────────────
  Widget _buildGallerySection() {
    // Placeholder slike za galeriju — zamijeniti sa LocaleImages API-jem
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Galerija lokala',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Prikaži sve',
                  style: TextStyle(color: Color(0xFF1E40AF), fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 130,
                    color: const Color(0xFFEFF6FF),
                    child: const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 36,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Ocjene ────────────────────────────────────────────────────────────────
  Widget _buildRatingsSection() {
    final totalReviews = _reviews.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ocjene gostiju',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lijeva strana — broj i zvjezdice
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    _buildStars(_averageRating),
                    const SizedBox(height: 4),
                    Text(
                      '(${totalReviews} recenzije)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),

                // Desna strana — barovi
                Expanded(
                  child: Column(
                    children: _ratingCounts.entries.map((entry) {
                      final percent = totalReviews > 0
                          ? entry.value / totalReviews
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 58,
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent.toDouble(),
                                  backgroundColor: Colors.grey.shade200,
                                  color: entry.key == 'Odlično'
                                      ? Colors.green
                                      : entry.key == 'Dobro'
                                      ? Colors.lightGreen
                                      : entry.key == 'Prosječno'
                                      ? Colors.orange
                                      : entry.key == 'Loše'
                                      ? Colors.deepOrange
                                      : Colors.red,
                                  minHeight: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Recenzije ─────────────────────────────────────────────────────────────
  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recenzije gostiju',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showAddReviewDialog(),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text(
                  'Napiši recenziju',
                  style: TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E40AF),
                  side: const BorderSide(color: Color(0xFF1E40AF)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _isLoadingReviews
              ? const Center(child: CircularProgressIndicator())
              : _reviews.isEmpty
              ? Center(
                  child: Text(
                    'Nema recenzija',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                )
              : Column(
                  children: _reviews.map((r) => _buildReviewCard(r)).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final firstName = review['username'] ?? 'Korisnik';
    final description = review['description'] ?? '';
    final likes = review['likes'] ?? 0;
    final dislikes = review['dislikes'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                firstName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(children: [_buildStars(rating, size: 14)]),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),

          // Like/dislike
          Row(
            children: [
              _reactionButton(Icons.thumb_up_outlined, likes.toString()),
              const SizedBox(width: 12),
              _reactionButton(Icons.thumb_down_outlined, dislikes.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reactionButton(IconData icon, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            count,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ── Add Review Dialog ─────────────────────────────────────────────────────
  void _showAddReviewDialog() {
    int selectedRating = 0;
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Napiši recenziju',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Zvjezdice za ocjenu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selectedRating == 0
                        ? Colors.red.shade300
                        : Colors.grey.shade200,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Ukupna ocjena *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedRating = i + 1),
                          child: Icon(
                            i < selectedRating ? Icons.star : Icons.star_border,
                            color: const Color(0xFFFBBF24),
                            size: 36,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Ostavite opis *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E40AF)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (selectedRating == 0 || descController.text.isEmpty)
                      return;
                    try {
                      final baseUrl =
                          BaseProvider.baseUrl ?? 'http://10.0.2.2:5241';
                      await http.post(
                        Uri.parse('$baseUrl/Reviews'),
                        headers: _createHeaders(),
                        body: jsonEncode({
                          'localeId': locale.id,
                          'userId': AuthProvider.currentUser?.id,
                          'rating': selectedRating,
                          'description': descController.text,
                        }),
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        _loadReviews();
                      }
                    } catch (e) {
                      debugPrint('Error adding review: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Dodaj recenziju',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildStars(double rating, {double size = 18}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating.floor()
              ? Icons.star
              : (i < rating ? Icons.star_half : Icons.star_border),
          color: const Color(0xFFFBBF24),
          size: size,
        );
      }),
    );
  }

  Widget _circleButton(
    IconData icon, {
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: color ?? const Color(0xFF0F172A)),
      ),
    );
  }
}
