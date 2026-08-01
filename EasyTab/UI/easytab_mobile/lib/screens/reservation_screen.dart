import 'package:easytab_mobile/models/locale.dart' as model;
import 'package:easytab_mobile/models/table.dart';
import 'package:easytab_mobile/models/zone.dart';
import 'package:easytab_mobile/providers/table_provider.dart';
import 'package:easytab_mobile/providers/utils.dart';
import 'package:easytab_mobile/providers/zone_provider.dart';
import 'package:easytab_mobile/screens/reservation_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReservationScreen extends StatefulWidget {
  final model.Locale locale;

  const ReservationScreen({super.key, required this.locale});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  late TableProvider _tableProvider;
  late ZoneProvider _zoneProvider;

  List<Tables> _tables = [];
  List<Zone> _zones = [];
  Tables? _selectedTable;
  bool _isLoading = true;
  String? _error;

  // Iste dimenzije platna kao u desktop aplikaciji (owner_tables_screen)
  static const double _canvasWidth = 900.0;
  static const double _canvasHeight = 600.0;
  static const double _tableSize = 80.0;

  model.Locale get locale => widget.locale;

  @override
  void initState() {
    super.initState();
    _tableProvider = context.read<TableProvider>();
    _zoneProvider = context.read<ZoneProvider>();
    _loadData();
  }

  Future<void> _loadData() async {
    if (locale.id == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _tableProvider.getByLocale(locale.id!),
        _zoneProvider.getByLocale(locale.id!),
      ]);
      if (mounted) {
        setState(() {
          _tables = results[0] as List<Tables>;
          _zones = results[1] as List<Zone>;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Greška pri učitavanju podataka.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _onTableTap(Tables table) {
    setState(() => _selectedTable = table);
  }

  void _proceedToDetails() {
    if (_selectedTable == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReservationDetailsScreen(
          locale: locale,
          selectedTable: _selectedTable!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 175, 30, 30),
                    ),
                  )
                : _error != null
                ? _buildErrorState()
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLocaleInfoCard(),
                        _buildFloorPlanSection(),
                        _buildLocaleDetailsSection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedTable != null
          ? _buildProceedButton()
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(color: const Color(0xFF1E40AF)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Rezervišite stol',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocaleInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            clipBehavior: Clip.hardEdge,
            child: ImageUtils.buildImage(
              locale.logo,
              fit: BoxFit.cover,
              placeholder: const Center(
                child: Icon(
                  Icons.store_outlined,
                  size: 28,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.name ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                if (locale.averageRating != null && locale.averageRating! > 0)
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFBBF24),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        locale.averageRating!.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorPlanSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pritisnite na stol koji želite i odaberite termin',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _tables.isEmpty && _zones.isEmpty
                  ? _buildEmptyFloorPlan()
                  : _buildFloorPlan(),
            ),
          ),
          if (_selectedTable != null) ...[
            const SizedBox(height: 12),
            _buildSelectedTableInfo(),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _tableAssetPath(int? guests) {
    final count = (guests ?? 2).clamp(2, 8);
    return 'assets/tables/${count}Seat.png';
  }

  Widget _tableImage(int? guests, double size) {
    return Image.asset(
      _tableAssetPath(guests),
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.table_restaurant,
        size: size * 0.55,
        color: const Color(0xFF3B82F6),
      ),
    );
  }

  Widget _buildEmptyFloorPlan() {
    return Container(
      height: 280,
      color: const Color(0xFFF8FAFC),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant_outlined,
              size: 48,
              color: Color(0xFFCBD5E1),
            ),
            SizedBox(height: 12),
            Text(
              'Nema postavljenih stolova',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorPlan() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final scale = availableWidth / _canvasWidth;
        final scaledHeight = _canvasHeight * scale;

        return SizedBox(
          width: availableWidth,
          height: scaledHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _GridPainter(gridStep: 60 * scale)),
              ),
              ..._zones.map((zone) => _buildZone(zone, scale)),
              ..._tables.map((table) => _buildTableWidget(table, scale)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZone(Zone zone, double scale) {
    final x = (zone.xCoordinate ?? 0) * scale;
    final y = (zone.yCoordinate ?? 0) * scale;
    final w = (zone.width ?? 80) * scale;
    final h = (zone.height ?? 60) * scale;

    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0).withOpacity(0.6),
          borderRadius: BorderRadius.circular(6 * scale),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        ),
        child: Center(
          child: Text(
            zone.name ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: (11 * scale).clamp(8, 13),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableWidget(Tables table, double scale) {
    final x = (table.xCoordinate ?? 0) * scale;
    final y = (table.yCoordinate ?? 0) * scale;
    final tableSize = _tableSize * scale;
    final isSelected = _selectedTable?.id == table.id;

    return Positioned(
      left: x,
      top: y,
      width: tableSize,
      height: tableSize,
      child: GestureDetector(
        onTap: () => _onTableTap(table),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(8 * scale),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1E40AF)
                  : const Color(0xFFCBD5E1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF1E40AF).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(1, 2),
                    ),
                  ],
          ),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: _tableSize,
              height: _tableSize,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _tableImage(table.numberOfGuests, _tableSize - 16),
                  if ((table.name ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        table.name ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF1E40AF)
                              : const Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTableInfo() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _selectedTable != null ? 1 : 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF1E40AF),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Odabrani stol: ${_selectedTable?.name ?? ''}  ·  ${_selectedTable?.numberOfGuests ?? '-'} gosta',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1E40AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocaleDetailsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
        child: Column(
          children: [
            _detailRow(
              Icons.category_outlined,
              'Kategorija',
              locale.categoryName ?? '-',
            ),
            const Divider(height: 20),
            _detailRow(
              Icons.access_time_outlined,
              'Radno vrijeme',
              'Pon - Ned  ${_formatTime(locale.startOfWorkingHours)} - ${_formatTime(locale.endOfWorkingHours)}',
            ),
            const Divider(height: 20),
            _detailRow(
              Icons.location_on_outlined,
              'Adresa',
              '${locale.address ?? '-'}, ${locale.cityName ?? ''}',
            ),
            if (locale.phoneNumber != null &&
                locale.phoneNumber!.isNotEmpty) ...[
              const Divider(height: 20),
              _detailRow(Icons.phone_outlined, 'Telefon', locale.phoneNumber!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
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
                  fontSize: 11,
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

  Widget _buildProceedButton() {
    return Container(
      color: const Color(0xFFF5F7FA),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: ElevatedButton(
        onPressed: _proceedToDetails,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E40AF),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Odaberi termin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Greška pri učitavanju',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
              ),
              child: const Text(
                'Pokušaj ponovo',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for grid background on floor plan
class _GridPainter extends CustomPainter {
  final double gridStep;

  const _GridPainter({this.gridStep = 40});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF8FAFC),
    );

    for (double x = 0; x < size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.gridStep != gridStep;
}
