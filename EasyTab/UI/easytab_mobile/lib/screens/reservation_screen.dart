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

  // Canvas dimensions for floor plan
  static const double _canvasWidth = 320;
  static const double _canvasHeight = 300;

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
                    child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
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
      bottomNavigationBar: _selectedTable != null ? _buildProceedButton() : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
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
                child: Icon(Icons.store_outlined,
                    size: 28, color: Color(0xFF1E40AF)),
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
                      const Icon(Icons.star,
                          color: Color(0xFFFBBF24), size: 16),
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

  Widget _buildEmptyFloorPlan() {
    return Container(
      height: 200,
      color: const Color(0xFFF8FAFC),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant_outlined,
                size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              'Nema postavljenih stolova',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorPlan() {
    // Find bounding box from tables and zones to compute scale
    double maxX = _canvasWidth;
    double maxY = _canvasHeight;

    for (var t in _tables) {
      if ((t.xCoordinate ?? 0) > maxX) maxX = t.xCoordinate! + 60;
      if ((t.yCoordinate ?? 0) > maxY) maxY = t.yCoordinate! + 60;
    }
    for (var z in _zones) {
      if ((z.xCoordinate ?? 0) + (z.width ?? 0) > maxX) {
        maxX = (z.xCoordinate ?? 0) + (z.width ?? 0);
      }
      if ((z.yCoordinate ?? 0) + (z.height ?? 0) > maxY) {
        maxY = (z.yCoordinate ?? 0) + (z.height ?? 0);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final scaleX = availableWidth / maxX;
        final scaleY = (_canvasHeight / maxY).clamp(0.3, 1.5);
        final scale = scaleX < scaleY ? scaleX : scaleY;
        final scaledHeight = maxY * scale;

        return SizedBox(
          height: scaledHeight.clamp(180, 360),
          child: Stack(
            children: [
              // Grid background
              Positioned.fill(
                child: CustomPaint(painter: _GridPainter()),
              ),
              // Zones
              ..._zones.map((zone) => _buildZone(zone, scale)),
              // Tables
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
    final tableSize = 44.0 * scale;
    final isSelected = _selectedTable?.id == table.id;

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () => _onTableTap(table),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: tableSize,
          height: tableSize,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1E40AF)
                : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8 * scale),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1E40AF)
                  : const Color(0xFF93C5FD),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF1E40AF).withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.table_restaurant,
                size: (16 * scale).clamp(10, 20),
                color: isSelected ? Colors.white : const Color(0xFF3B82F6),
              ),
              if (tableSize > 28)
                Text(
                  table.name ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (7 * scale).clamp(6, 9),
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF1E40AF),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
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
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF1E40AF), size: 18),
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
              _detailRow(
                Icons.phone_outlined,
                'Telefon',
                locale.phoneNumber!,
              ),
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
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 18),
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
            const Icon(Icons.error_outline,
                size: 56, color: Color(0xFFCBD5E1)),
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
              child: const Text('Pokušaj ponovo',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for grid background on floor plan
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    // Fill background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF8FAFC),
    );

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
