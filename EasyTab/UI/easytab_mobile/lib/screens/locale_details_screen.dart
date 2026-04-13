import 'package:easytab_mobile/models/favourite.dart';
import 'package:easytab_mobile/models/locale.dart' as model;
import 'package:easytab_mobile/models/review.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/favourite_provider.dart';
import 'package:easytab_mobile/providers/reaction_provider.dart';
import 'package:easytab_mobile/providers/review_provider.dart';
import 'package:easytab_mobile/providers/utils.dart';
import 'package:easytab_mobile/screens/add_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LocaleDetailScreen extends StatefulWidget {
  final model.Locale locale;
  const LocaleDetailScreen({super.key, required this.locale});

  @override
  State<LocaleDetailScreen> createState() => _LocaleDetailScreenState();
}

class _LocaleDetailScreenState extends State<LocaleDetailScreen> {
  late ReviewProvider _reviewProvider;
  late ReactionProvider _reactionProvider;
  late FavouriteProvider _favouriteProvider;

  bool _isFavourite = false;
  bool _isLoadingReviews = true;
  Favourite? _currentFavourite;
  bool _isTogglingFav = false;

  List<Review> _reviews = [];
  double _averageRating = 0;
  Map<String, int> _ratingCounts = {
    'Odlično': 0,
    'Dobro': 0,
    'Prosječno': 0,
    'Loše': 0,
    'Užasno': 0,
  };

  model.Locale get locale => widget.locale;
  int? get _currentUserId => AuthProvider.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _reviewProvider = context.read<ReviewProvider>();
    _reactionProvider = context.read<ReactionProvider>();
    _favouriteProvider = context.read<FavouriteProvider>();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadReviews(), _checkFavourite()]);
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final results = await Future.wait([
        _reviewProvider.getByLocale(locale.id!),
        _reviewProvider.getAverage(locale.id!),
        _reviewProvider.getRatingCounts(locale.id!),
      ]);

      setState(() {
        _reviews = results[0] as List<Review>;
        _averageRating = results[1] as double;
        _ratingCounts = results[2] as Map<String, int>;
      });
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    } finally {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _toggleFavourite() async {
    if (_isTogglingFav || _currentUserId == null) return;
    setState(() => _isTogglingFav = true);

    try {
      if (_isFavourite) {
        // Ukloni
        await _favouriteProvider.removeFavourite(_currentUserId!, locale.id!);
        setState(() => _isFavourite = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${locale.name ?? 'Lokal'} uklonjen iz omiljenih'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Dodaj
        await _favouriteProvider.addFavourite(_currentUserId!, locale.id!);
        setState(() => _isFavourite = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${locale.name ?? 'Lokal'} dodan u omiljene!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Toggle favourite error: $e');
    } finally {
      if (mounted) setState(() => _isTogglingFav = false);
    }
  }

  Future<void> _checkFavourite() async {
    try {
      if (_currentUserId == null || locale.id == null) return;
      final isFav = await _favouriteProvider.isFavourited(
        _currentUserId!,
        locale.id!,
      );
      if (mounted) {
        setState(() {
          _isFavourite = isFav;
          // _currentFavourite više ne koristimo, možemo ga ukloniti iz state-a
        });
      }
    } catch (e) {
      debugPrint('Error checking favourite: $e');
    }
  }

  void _goToAddReview({Review? existingReview}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddReviewScreen(
          localeId: locale.id!,
          existingReview: existingReview,
          onSaved: _loadReviews,
        ),
      ),
    );
  }

  void _confirmDelete(Review review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Brisanje recenzije'),
        content: const Text(
          'Da li ste sigurni da želite obrisati ovu recenziju?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _reviewProvider.deleteReview(review.id!);
                _loadReviews();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Obriši', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReaction(Review review, bool isLike) async {
    // Ne dozvoli reakciju na vlastitu recenziju
    if (review.userId == _currentUserId) return;

    debugPrint(
      'ReviweId: ${review.id}, userId: $_currentUserId, islike: $isLike',
    );

    try {
      await _reactionProvider.react(
        reviewId: review.id!,
        userId: _currentUserId!,
        isLike: isLike,
      );
      _loadReviews();
    } catch (e) {
      debugPrint('Reaction error: $e');
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

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
                _isTogglingFav
                    ? Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        ),
                      )
                    : _circleButton(
                        _isFavourite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavourite ? Colors.red : null,
                        onTap: _toggleFavourite,
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

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      height: 240,
      color: Colors.white,
      child: ImageUtils.buildImage(
        locale.logo,
        fit: BoxFit.contain,
        placeholder: _logoFallback(),
      ),
    );
  }

  Widget _logoFallback() => Container(
    color: const Color(0xFFEFF6FF),
    child: const Center(
      child: Icon(Icons.store_outlined, size: 72, color: Color(0xFF1E40AF)),
    ),
  );

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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          _infoRow(
            Icons.category_outlined,
            'Kategorija',
            locale.categoryName ?? '-',
          ),
          const Divider(height: 24),
          _infoRow(
            Icons.access_time_outlined,
            'Radno vrijeme',
            'Pon - Ned  ${_formatTime(locale.startOfWorkingHours)} - ${_formatTime(locale.endOfWorkingHours)}',
          ),
          const Divider(height: 24),
          _infoRow(
            Icons.location_on_outlined,
            'Adresa',
            '${locale.address ?? '-'}, ${locale.cityName ?? ''}',
          ),
          if (locale.phoneNumber != null && locale.phoneNumber!.isNotEmpty) ...[
            const Divider(height: 24),
            _infoRow(Icons.phone_outlined, 'Telefon', locale.phoneNumber!),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
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

  Widget _buildGallerySection() {
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
              itemBuilder: (context, i) => ClipRRect(
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection() {
    final total = _reviews.length;
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
                Column(
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
                      '($total recenzije)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: _ratingCounts.entries.map((entry) {
                      final pct = total > 0 ? entry.value / total : 0.0;
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
                                  value: pct.toDouble(),
                                  backgroundColor: Colors.grey.shade200,
                                  color: _barColor(entry.key),
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

  Color _barColor(String label) {
    switch (label) {
      case 'Odlično':
        return Colors.green;
      case 'Dobro':
        return Colors.lightGreen;
      case 'Prosječno':
        return Colors.orange;
      case 'Loše':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

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
                onPressed: () => _goToAddReview(),
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

  Widget _buildReviewCard(Review review) {
    final isMyReview = review.userId == _currentUserId;
    final rating = review.rating ?? 0;
    final dateStr = review.dateAdded != null
        ? '${review.dateAdded!.day}.${review.dateAdded!.month}.${review.dateAdded!.year}.'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isMyReview
            ? Border.all(color: const Color(0xFF1E40AF), width: 1.5)
            : null,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userFullName ?? 'Korisnik',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _buildStars(rating.toDouble(), size: 13),
                        const SizedBox(width: 6),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Edit/Delete samo za moje recenzije
              if (isMyReview)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFF1E40AF),
                      ),
                      onPressed: () => _goToAddReview(existingReview: review),
                      tooltip: 'Uredi',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () => _confirmDelete(review),
                      tooltip: 'Obriši',
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.description ?? '',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),

          // Like/dislike dugmad (samo ako nije moja recenzija)
          if (!isMyReview)
            Row(
              children: [
                _reactionButton(
                  Icons.thumb_up,
                  review.likes?.toString() ?? '0',
                  isActive: review.userReaction == 1,
                  activeColor: Colors.green,
                  onTap: () => _handleReaction(review, true),
                ),
                const SizedBox(width: 10),
                _reactionButton(
                  Icons.thumb_down,
                  review.dislikes?.toString() ?? '0',
                  isActive: review.userReaction == -1,
                  activeColor: Colors.red,
                  onTap: () => _handleReaction(review, false),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _reactionButton(
    IconData icon,
    String count, {
    required VoidCallback onTap,
    bool isActive = false,
    Color activeColor = Colors.green,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withOpacity(0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: activeColor, width: 1) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? activeColor : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? activeColor : Colors.grey.shade600,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
