import 'package:easytab_mobile/models/favourite.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/favourite_provider.dart';
import 'package:easytab_mobile/providers/locale_provider.dart';
import 'package:easytab_mobile/providers/utils.dart';
import 'package:easytab_mobile/screens/locale_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easytab_mobile/models/locale.dart' as model;

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  late FavouriteProvider _favouriteProvider;
  late LocaleProvider _localeProvider;
  List<Favourite> _favourites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _favouriteProvider = context.read<FavouriteProvider>();
    _localeProvider = context.read<LocaleProvider>();
    // Ne učitavaj ovdje, nego u didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFavourites(); // svaki put kad se ekran prikaže
  }

  Future<void> _loadFavourites() async {
    setState(() => _isLoading = true);
    try {
      final userId = AuthProvider.currentUser?.id;
      if (userId == null) return;
      final favs = await _favouriteProvider.getMyFavourites(userId);
      setState(() => _favourites = favs);
    } catch (e) {
      debugPrint('Error loading favourites: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavourite(Favourite fav) async {
    try {
      await _favouriteProvider.removeFavourite(
        AuthProvider.currentUser!.id!,
        fav.localeId!,
      );
      setState(() => _favourites.remove(fav));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${fav.localeName ?? 'Lokal'} uklonjen iz omiljenih'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error removing favourite: $e');
    }
  }

  Future<void> _goToLocale(Favourite fav) async {
    try {
      final result = await _localeProvider.get(filter: {'RetrieveAll': true});
      final locale = result.items?.firstWhere(
        (l) => l.id == fav.localeId,
        orElse: () => model.Locale(),
      );
      if (locale?.id != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LocaleDetailScreen(locale: locale!),
          ),
        ).then((_) => _loadFavourites());
      }
    } catch (e) {
      debugPrint('Error navigating to locale: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favourites.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _loadFavourites,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _favourites.length,
                itemBuilder: (context, index) =>
                    _buildFavouriteCard(_favourites[index]),
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Nemate omiljenih lokala',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dodajte lokale klikom na srce\nu detalje lokala',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildFavouriteCard(Favourite fav) {
    return GestureDetector(
      onTap: () => _goToLocale(fav),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo - koristi ImageUtils
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: ImageUtils.buildImage(
                  fav.localeLogo,
                  fit: BoxFit.cover,
                  placeholder: _logoPlaceholder(),
                ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fav.localeName ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (fav.localeCategoryName != null)
                      Text(
                        fav.localeCategoryName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    const SizedBox(height: 6),
                    if (fav.localeCityName != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Color(0xFF1E40AF),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            fav.localeCityName!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1E40AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Ukloni dugme
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _confirmRemove(fav),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Container(
      color: const Color(0xFFEFF6FF),
      child: const Center(
        child: Icon(Icons.store_outlined, size: 32, color: Color(0xFF1E40AF)),
      ),
    );
  }

  void _confirmRemove(Favourite fav) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ukloni iz omiljenih'),
        content: Text(
          'Da li želite ukloniti ${fav.localeName ?? 'lokal'} iz omiljenih?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _removeFavourite(fav);
            },
            child: const Text('Ukloni', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
