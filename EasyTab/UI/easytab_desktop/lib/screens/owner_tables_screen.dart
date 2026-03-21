import 'package:easytab_desktop/models/table.dart';
import 'package:easytab_desktop/models/zone.dart';
import 'package:easytab_desktop/providers/table_provider.dart';
import 'package:easytab_desktop/providers/zone_provider.dart';
import 'package:easytab_desktop/widgets/owner_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OwnerTablesScreen extends StatefulWidget {
  final int localeId;
  final String localeName;
  final Function(int localeId, String section)? onSectionTap;
  final VoidCallback? onRefresh;

  const OwnerTablesScreen({
    super.key,
    required this.localeId,
    required this.localeName,
    this.onSectionTap,
    this.onRefresh,
  });

  @override
  State<OwnerTablesScreen> createState() => _OwnerTablesScreenState();
}

class _OwnerTablesScreenState extends State<OwnerTablesScreen> {
  late TableProvider tableProvider;
  late ZoneProvider zoneProvider;

  List<Tables> tables = [];
  List<Zone> zones = [];
  bool isLoading = false;

  // Canvas dimenzije
  static const double canvasWidth = 900.0;
  static const double canvasHeight = 600.0;
  static const double tableSize = 80.0;

  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    tableProvider = context.read<TableProvider>();
    zoneProvider = context.read<ZoneProvider>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        tableProvider.getByLocale(widget.localeId),
        zoneProvider.getByLocale(widget.localeId),
      ]);

      final loadedTables = results[0] as List<Tables>;
      final loadedZones = results[1] as List<Zone>;

      // DEBUG — vidi šta dolazi
      for (var t in loadedTables) {
        print("Table: ${t.name}, X: ${t.xCoordinate}, Y: ${t.yCoordinate}");
      }
      for (var z in loadedZones) {
        print("Zone: ${z.name}, X: ${z.xCoordinate}, Y: ${z.yCoordinate}");
      }

      setState(() {
        tables = loadedTables;
        zones = loadedZones;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Greška'),
        content: Text(message.replaceAll("Exception: ", "")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _tableImage(int guests) {
    final imagePath = 'assets/tables/${guests}seat.png';
    return Image.asset(
      imagePath,
      width: tableSize - 16,
      height: tableSize - 16,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.table_restaurant, size: 28, color: Colors.brown),
          Text(
            '$guests',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showTableDialog({Tables? table, int? index}) {
    final nameController = TextEditingController(text: table?.name ?? '');
    int guests = table?.numberOfGuests ?? 2;
    final isEdit = table != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(isEdit ? 'Uredi stol' : 'Novi stol'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Naziv stola',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Broj gostiju:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (guests > 2) setStateDialog(() => guests--);
                    },
                  ),
                  // Preview slike
                  SizedBox(width: 60, height: 60, child: _tableImage(guests)),
                  Text(
                    '  $guests  ',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      if (guests < 8) setStateDialog(() => guests++);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            if (isEdit)
              TextButton(
                onPressed: () {
                  setState(() => tables.removeAt(index!));
                  Navigator.pop(context);
                },
                child: const Text(
                  'Obriši',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
              ),
              onPressed: () {
                if (nameController.text.isEmpty) return;
                setState(() {
                  if (isEdit) {
                    tables[index!] = tables[index].copyWith(
                      name: nameController.text,
                      numberOfGuests: guests,
                    );
                  } else {
                    tables.add(
                      Tables(
                        id: 0,
                        name: nameController.text,
                        localeId: widget.localeId,
                        xCoordinate: 10,
                        yCoordinate: 10,
                        numberOfGuests: guests,
                      ),
                    );
                  }
                });
                Navigator.pop(context);
              },
              child: Text(
                isEdit ? 'Spremi' : 'Dodaj',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showZoneDialog({Zone? zone, int? index}) {
    final nameController = TextEditingController(text: zone?.name ?? '');
    double width = zone?.width ?? 160;
    double height = zone?.height ?? 80;
    final isEdit = zone != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(isEdit ? 'Uredi zonu' : 'Nova zona'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Naziv zone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Širina: ${width.toInt()}px'),
                        Slider(
                          value: width,
                          min: 80,
                          max: 400,
                          divisions: 16,
                          onChanged: (v) => setStateDialog(() => width = v),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Visina: ${height.toInt()}px'),
                        Slider(
                          value: height,
                          min: 80,
                          max: 300,
                          divisions: 11,
                          onChanged: (v) => setStateDialog(() => height = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            if (isEdit)
              TextButton(
                onPressed: () {
                  setState(() => zones.removeAt(index!));
                  Navigator.pop(context);
                },
                child: const Text(
                  'Obriši',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Otkaži'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
              ),
              onPressed: () {
                if (nameController.text.isEmpty) return;
                setState(() {
                  if (isEdit) {
                    zones[index!] = zones[index].copyWith(
                      name: nameController.text,
                      width: width,
                      height: height,
                    );
                  } else {
                    zones.add(
                      Zone(
                        id: 0,
                        name: nameController.text,
                        localeId: widget.localeId,
                        xCoordinate: 10,
                        yCoordinate: 10,
                        width: width,
                        height: height,
                      ),
                    );
                  }
                });
                Navigator.pop(context);
              },
              child: Text(
                isEdit ? 'Spremi' : 'Dodaj',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSave() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spremi raspored'),
        content: const Text(
          'Da li ste sigurni da želite snimiti trenutni raspored?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
            ),
            onPressed: () {
              Navigator.pop(context);
              _saveLayout();
            },
            child: const Text('Spremi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLayout() async {
    try {
      await Future.wait([
        tableProvider.saveLayout(widget.localeId, tables),
        zoneProvider.saveLayout(widget.localeId, zones),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Raspored uspješno snimljen!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Offset _getCanvasOffset() {
    final RenderBox? box =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.localToGlobal(Offset.zero) ?? Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          OwnerSidebar(
            activeLocaleId: widget.localeId,
            onSectionTap: widget.onSectionTap,
            onRefresh: widget.onRefresh,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      if (Navigator.canPop(context))
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Nazad'),
                        ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stolovi',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Prikaz tlocrta stolova za ${widget.localeName}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Expanded(
                          child: Column(
                            children: [
                              // Canvas
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey.shade50,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SingleChildScrollView(
                                        child: SizedBox(
                                          width: canvasWidth,
                                          height: canvasHeight,
                                          child: Stack(
                                            key: _canvasKey,
                                            children: [
                                              // Grid pozadina
                                              CustomPaint(
                                                size: const Size(
                                                  canvasWidth,
                                                  canvasHeight,
                                                ),
                                                painter: _GridPainter(),
                                              ),

                                              // Zone — idu ispod stolova
                                              ...zones.asMap().entries.map(
                                                (entry) => _buildZone(
                                                  entry.value,
                                                  entry.key,
                                                ),
                                              ),

                                              // Stolovi — idu iznad zona
                                              ...tables.asMap().entries.map(
                                                (entry) => _buildTable(
                                                  entry.value,
                                                  entry.key,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Dugmad
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E40AF),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Dodaj novi stol',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onPressed: () => _showTableDialog(),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E40AF),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.crop_square,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Dodaj novu zonu',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onPressed: () => _showZoneDialog(),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.save,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Spremi promjene',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onPressed: _confirmSave,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(Tables table, int index) {
    double x = table.xCoordinate ?? 0;
    double y = table.yCoordinate ?? 0;

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onDoubleTap: () => _showTableDialog(table: table, index: index),

        onPanUpdate: (details) {
          setState(() {
            double newX = (x + details.delta.dx).clamp(
              0,
              canvasWidth - tableSize,
            );
            double newY = (y + details.delta.dy).clamp(
              0,
              canvasHeight - tableSize,
            );
            tables[index] = table.copyWith(
              xCoordinate: newX,
              yCoordinate: newY,
            );

            x = newX;
            y = newY;
          });
        },
        child: Container(
          width: tableSize,
          height: tableSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tableImage(table.numberOfGuests ?? 2),
              Text(
                table.name ?? '',
                style: const TextStyle(fontSize: 9),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZone(Zone zone, int index) {
    double x = zone.xCoordinate ?? 0;
    double y = zone.yCoordinate ?? 0;
    final w = zone.width ?? 160;
    final h = zone.height ?? 80;

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onDoubleTap: () => _showZoneDialog(zone: zone, index: index),
        onPanUpdate: (details) {
          setState(() {
            double newX = (x + details.delta.dx).clamp(0, canvasWidth - w);
            double newY = (y + details.delta.dy).clamp(0, canvasHeight - h);
            zones[index] = zone.copyWith(xCoordinate: newX, yCoordinate: newY);
            x = newX;
            y = newY;
          });
        },
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.lightBlue.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.lightBlue.shade700, width: 1.5),
          ),
          child: Center(
            child: Text(
              zone.name ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.lightBlue.shade900,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    const cellSize = 60.0;

    for (double x = 0; x <= size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
