import 'package:easytab_mobile/models/review.dart';
import 'package:easytab_mobile/models/search_result.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/review_provider.dart';
import 'package:easytab_mobile/providers/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserReviewsScreen extends StatefulWidget {
  const UserReviewsScreen({super.key});

  @override
  State<UserReviewsScreen> createState() => _UserReviewsScreenState();
}

class _UserReviewsScreenState extends State<UserReviewsScreen> {
  late ReviewProvider _reviewProvider;
  SearchResult<Review>? reviewResult;
  bool isLoading = true;

  int? selectedRating;

  final Map<int, String> ratings = {
    5: "Odlično",
    4: "Vrlo dobro",
    3: "Dobro",
    2: "Loše",
    1: "Vrlo loše",
    0: "Sve ocjene",
  };

  @override
  void initState() {
    super.initState();
    _reviewProvider = context.read<ReviewProvider>();
    initData();
  }

  Future<void> initData() async {
    try {
      var data = await _reviewProvider.get(
        filter: {
          'userId':
              int.tryParse(AuthProvider.accessTokenDecoded?['Id'] ?? '0') ?? 0,
          'rating': selectedRating,
        },
      );
      setState(() {
        reviewResult = data;
        isLoading = false;
      });
    } on Exception catch (e) {
      alertBox(context, 'Error', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    initialValue: selectedRating,
                    hint: const Text('Odaberite ocjenu'),
                    items: ratings.entries.map((entry) {
                      return DropdownMenuItem<int>(
                        value: entry.key,
                        child: entry.key == 0
                            ? Text(entry.value)
                            : Text('${entry.key} - ${entry.value}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == 0) {
                        value = null;
                      }
                      setState(() {
                        selectedRating = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    await initData();
                  },
                  child: Text('Pretraga'),
                ),
              ],
            ),
          ),
          SizedBox(width: 20),
          // --- OVDJE JE PROMJENA ---
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (reviewResult == null ||
              reviewResult!.items == null ||
              reviewResult!.items!.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Nema recenzija',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            _buildReviewList(),
        ],
      ),
    );
  }

  Expanded _buildReviewList() {
    return Expanded(
      child: ListView.builder(
        itemCount: reviewResult?.items?.length ?? 0,
        itemBuilder: (context, index) {
          var review = reviewResult?.items?[index];
          if (review == null) return const SizedBox.shrink();

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
              // Ovdje možeš dodati border ako želiš, ali nije potrebno
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
                const SizedBox(height: 8),
                Text(
                  review.description ?? '',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          );
        },
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
          Text(
            "Moje recenzije",
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
