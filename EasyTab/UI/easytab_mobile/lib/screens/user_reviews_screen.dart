import 'package:easytab_mobile/models/review.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/review_provider.dart';
import 'package:easytab_mobile/providers/locale_provider.dart';
import 'package:easytab_mobile/providers/utils.dart';
import 'package:easytab_mobile/widgets/form_feedback.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserReviewsScreen extends StatefulWidget {
  const UserReviewsScreen({super.key});
  @override
  State<UserReviewsScreen> createState() => _UserReviewsScreenState();
}

class _UserReviewsScreenState extends State<UserReviewsScreen> {
  final Map<int, String?> _logos = {};
  List<Review> _reviews = [];
  int? _rating;
  int _page = 0;
  int _totalCount = 0;
  int _requestVersion = 0;
  static const _pageSize = 10;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int page = 0}) async {
    final version = ++_requestVersion;
    final userId = AuthProvider.currentUserId;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Prijavite se ponovo za pregled recenzija.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final reviews = context.read<ReviewProvider>();
    final locales = context.read<LocaleProvider>();
    try {
      final result = await reviews.get(
        filter: {
          'UserId': userId,
          'Rating': _rating,
          'Page': page + 1,
          'PageSize': _pageSize,
          'IncludeTotalCount': true,
          'SortBy': 'latest',
        },
      );
      final items = result.items ?? [];
      if (!mounted || version != _requestVersion) return;
      if (page > 0 && items.isEmpty) {
        await _load();
        return;
      }
      final logos = <int, String?>{};
      await Future.wait(
        items
            .map((review) => review.localeId)
            .whereType<int>()
            .toSet()
            .where((id) => !_logos.containsKey(id))
            .map((id) async {
              try {
                logos[id] = (await locales.getById(id)).logo;
              } catch (_) {
                logos[id] = null;
              }
            }),
      );
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _reviews = items;
        _logos.addAll(logos);
        _page = page;
        _totalCount = result.totalCount ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || version != _requestVersion) return;
      setState(() {
        _error = userError(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    appBar: AppBar(title: const Text('Moje recenzije')),
    body: RefreshIndicator(
      onRefresh: () => _load(page: _page),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Sve ocjene'),
                        selected: _rating == null,
                        onSelected: (_) {
                          setState(() => _rating = null);
                          _load();
                        },
                      ),
                      for (var rating = 1; rating <= 5; rating++)
                        ChoiceChip(
                          label: Text('$rating ★'),
                          selected: _rating == rating,
                          onSelected: (_) {
                            setState(() => _rating = rating);
                            _load();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: () => _load(page: _page),
                      child: const Text('Pokušaj ponovo'),
                    ),
                  ],
                ),
              ),
            )
          else if (_reviews.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('Nema recenzija za odabrane kriterije.'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == _reviews.length) {
                    return PaginationUtils.buildPageControls(
                      currentPage: _page,
                      totalCount: _totalCount,
                      pageSize: _pageSize,
                      onPageChanged: (page) => _load(page: page),
                    );
                  }
                  final review = _reviews[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: ImageUtils.buildImage(
                                    _logos[review.localeId],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  review.localeName ?? 'Lokal',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(review.rating ?? 0).toStringAsFixed(0)} ★ · ${review.dateAdded == null ? '' : formatSystemDateOnly(review.dateAdded!)}',
                          ),
                          const SizedBox(height: 8),
                          Text(review.description ?? ''),
                        ],
                      ),
                    ),
                  );
                }, childCount: _reviews.length + 1),
              ),
            ),
        ],
      ),
    ),
  );
}
