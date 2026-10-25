import 'package:easytab_mobile/models/recommended_locale.dart';
import 'package:easytab_mobile/providers/locale_provider.dart';
import 'package:easytab_mobile/providers/utils.dart';
import 'package:easytab_mobile/screens/locale_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RecommendedLocalesSection extends StatelessWidget {
  final List<RecommendedLocale> locales;

  const RecommendedLocalesSection({super.key, required this.locales});

  @override
  Widget build(BuildContext context) {
    if (locales.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preporučeno za vas',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          for (final locale in locales)
            _RecommendationCard(key: ValueKey(locale.id), locale: locale),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatefulWidget {
  final RecommendedLocale locale;

  const _RecommendationCard({super.key, required this.locale});

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _isOpening = false;

  Future<void> _open() async {
    if (_isOpening) return;
    setState(() => _isOpening = true);
    try {
      final locale = await context.read<LocaleProvider>().getById(
        widget.locale.id,
      );
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => LocaleDetailScreen(locale: locale)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nije moguće otvoriti detalje lokala.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.locale;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _isOpening ? null : _open,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: ImageUtils.buildImage(locale.logo),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('${locale.categoryName} · ${locale.cityName}'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFBBF24),
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(locale.averageRating.toStringAsFixed(1)),
                              if (_isOpening) ...[
                                const SizedBox(width: 12),
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    semanticsLabel: 'Otvaranje detalja lokala',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  locale.explanation,
                  style: const TextStyle(color: Color(0xFF475569), height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
