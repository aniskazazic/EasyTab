import 'package:easytab_mobile/models/category.dart';
import 'package:easytab_mobile/models/locale.dart' as model;
import 'package:easytab_mobile/providers/locale_provider.dart';
import 'package:easytab_mobile/providers/utils.dart';
import 'package:easytab_mobile/screens/category_locales_screen.dart';
import 'package:easytab_mobile/screens/locale_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late LocaleProvider _localeProvider;
  bool _isLoading = true;
  Map<Category, List<model.Locale>> _groupedLocales = {};

  @override
  void initState() {
    super.initState();
    _localeProvider = context.read<LocaleProvider>();
    _loadLocales();
  }

  Future<void> _loadLocales() async {
    try {
      final result = await _localeProvider.get(filter: {});
      final locales = result.items ?? [];

      // Grupiranje po kategoriji (Category objekt)
      final Map<int, Category> categoryMap = {};
      final Map<int, List<model.Locale>> tempGroup = {};

      for (final locale in locales) {
        final catId = locale.categoryId ?? -1;
        final catName = locale.categoryName ?? 'Ostalo';
        if (!categoryMap.containsKey(catId)) {
          categoryMap[catId] = Category(id: catId, name: catName);
        }
        tempGroup.putIfAbsent(catId, () => []).add(locale);
      }

      // Ograniči na max 3 lokala po kategoriji
      final Map<Category, List<model.Locale>> trimmed = {};
      tempGroup.forEach((catId, list) {
        final category = categoryMap[catId]!;
        trimmed[category] = list.take(3).toList();
      });

      if (mounted) {
        setState(() {
          _groupedLocales = trimmed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading locales: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _groupedLocales.isEmpty
            ? _buildEmpty()
            : RefreshIndicator(
                onRefresh: _loadLocales,
                child: ListView(
                  padding: const EdgeInsets.only(top: 20, bottom: 8),
                  children: _groupedLocales.entries.map((entry) {
                    return _CategoryCarousel(
                      category: entry.key,
                      locales: entry.value,
                      onLocaleOpened: _loadLocales,
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.store_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            'Nema dostupnih lokala',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _CategoryCarousel extends StatefulWidget {
  final Category category;
  final List<model.Locale> locales;
  final Future<void> Function() onLocaleOpened;

  const _CategoryCarousel({
    required this.category,
    required this.locales,
    required this.onLocaleOpened,
  });

  @override
  State<_CategoryCarousel> createState() => _CategoryCarouselState();
}

class _CategoryCarouselState extends State<_CategoryCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.category.name ?? '',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryLocalesScreen(
                      categoryId: widget.category.id ?? 0,
                      categoryName: widget.category.name ?? '',
                    ),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Prikaži sve',
                  style: TextStyle(color: Color(0xFF1E40AF), fontSize: 13),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        SizedBox(
          height: 248,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.locales.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              return _LocaleCard(
                locale: widget.locales[index],
                onLocaleOpened: widget.onLocaleOpened,
              );
            },
          ),
        ),
        if (widget.locales.length > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.locales.length, (i) {
              final isActive = i == _currentPage;
              return GestureDetector(
                onTap: () => _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? const Color(0xFF1E40AF)
                        : Colors.grey.shade300,
                  ),
                ),
              );
            }),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _LocaleCard extends StatelessWidget {
  final model.Locale locale;
  final Future<void> Function() onLocaleOpened;
  const _LocaleCard({required this.locale, required this.onLocaleOpened});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LocaleDetailScreen(locale: locale)),
        );
        await onLocaleOpened();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: SizedBox(
                height: 148,
                width: double.infinity,
                child: ImageUtils.buildImage(
                  locale.logo,
                  fit: BoxFit.cover,
                  placeholder: _placeholder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SizedBox(
                height: 68,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            locale.name ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (locale.averageRating != null &&
                            locale.averageRating! > 0) ...[
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                locale.averageRating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFBBF24),
                                size: 25,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            locale.categoryName ?? 'Ostalo',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (locale.address != null &&
                            locale.address!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    locale.address!,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1E40AF),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: Color(0xFF1E40AF),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFEFF6FF),
      child: const Center(
        child: Icon(Icons.store_outlined, size: 48, color: Color(0xFF1E40AF)),
      ),
    );
  }
}
