import 'package:easytab_mobile/providers/locale_provider.dart';
import 'package:easytab_mobile/models/category.dart';

import 'package:easytab_mobile/models/locale.dart';
import 'package:easytab_mobile/providers/utils.dart';
import 'package:easytab_mobile/screens/locale_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoryLocalesScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  const CategoryLocalesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryLocalesScreen> createState() => _CategoryLocalesScreenState();
}

class _CategoryLocalesScreenState extends State<CategoryLocalesScreen> {
  late LocaleProvider _localeProvider;
  bool _isLoading = true;
  List<Locale> _locales = [];
  int _totalCount = 0;
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _localeProvider = context.read<LocaleProvider>();
    _loadLocales();
  }

  Future<void> _loadLocales() async {
    setState(() => _isLoading = true);
    try {
      final result = await _localeProvider.get(
        filter: {
          "categoryId": widget.categoryId,
          "Page": _currentPage + 1,
          "PageSize": _pageSize,
          "IncludeTotalCount": true,
        },
      );
      setState(() {
        _locales = result.items ?? [];
        _totalCount = result.totalCount ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading locales: $e');
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _currentPage = 0);
    await _loadLocales();
  }

  int get _totalPages =>
      _totalCount == 0 ? 1 : (_totalCount / _pageSize).ceil();

  void _goToPage(int page) {
    if (page < 0 || page >= _totalPages) return;
    setState(() => _currentPage = page);
    _loadLocales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        scrolledUnderElevation: 1,
        toolbarHeight: 45,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: false, // tekst lijevo, odmah iza strelice
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _locales.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                itemCount: _locales.length + 1,
                itemBuilder: (context, index) {
                  if (index == _locales.length) {
                    return _buildPagination();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _LocaleCard(locale: _locales[index]),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildPagination() {
    const int maxVisible = 3;
    int startPage = (_currentPage - maxVisible ~/ 2).clamp(0, _totalPages - 1);
    int endPage = (startPage + maxVisible - 1).clamp(0, _totalPages - 1);
    if (endPage - startPage < maxVisible - 1) {
      startPage = (endPage - maxVisible + 1).clamp(0, _totalPages - 1);
    }

    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Stranica ${_currentPage + 1}/$_totalPages',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _pageButton(
                  icon: Icons.first_page_rounded,
                  onTap: _currentPage > 0 ? () => _goToPage(0) : null,
                ),
                _pageButton(
                  icon: Icons.keyboard_arrow_left_rounded,
                  onTap: _currentPage > 0
                      ? () => _goToPage(_currentPage - 1)
                      : null,
                ),
                for (int i = startPage; i <= endPage; i++) _pageNumberButton(i),
                _pageButton(
                  icon: Icons.keyboard_arrow_right_rounded,
                  onTap: _currentPage < _totalPages - 1
                      ? () => _goToPage(_currentPage + 1)
                      : null,
                ),
                _pageButton(
                  icon: Icons.last_page_rounded,
                  onTap: _currentPage < _totalPages - 1
                      ? () => _goToPage(_totalPages - 1)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageButton({required IconData icon, VoidCallback? onTap}) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
      color: onTap != null ? const Color(0xFF1E40AF) : Colors.grey.shade400,
    );
  }

  Widget _pageNumberButton(int page) {
    final isActive = page == _currentPage;
    return GestureDetector(
      onTap: () => _goToPage(page),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E40AF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? const Color(0xFF1E40AF) : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            '${page + 1}',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade700,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
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
            'Nema lokala u ovoj kategoriji',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _LocaleCard extends StatelessWidget {
  final Locale locale;
  const _LocaleCard({required this.locale});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LocaleDetailScreen(locale: locale)),
      ),
      child: Container(
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
            // Slika
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
            // Informacije
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
