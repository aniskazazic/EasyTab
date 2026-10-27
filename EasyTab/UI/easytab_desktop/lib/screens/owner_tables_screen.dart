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
  String? _tableDialogError;
  String? _zoneDialogError;
  bool _overlapNoticeShown = false;

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
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        tableProvider.getByLocale(widget.localeId),
        zoneProvider.getByLocale(widget.localeId),
      ]);

      final loadedTables = results[0] as List<Tables>;
      final loadedZones = results[1] as List<Zone>;

      if (!mounted) return;
      setState(() {
        tables = loadedTables;
        zones = loadedZones;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    if (!mounted) return;
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

  Offset? _findFreePosition({required double width, required double height}) {
    for (double y = 10; y + height <= canvasHeight; y += 20) {
      for (double x = 10; x + width <= canvasWidth; x += 20) {
        if (_canPlaceElement(left: x, top: y, width: width, height: height)) {
          return Offset(x, y);
        }
      }
    }
    return null;
  }

  bool _canPlaceElement({
    required double left,
    required double top,
    required double width,
    required double height,
    int? ignoredTableIndex,
    int? ignoredZoneIndex,
  }) {
    if (left < 0 ||
        top < 0 ||
        left + width > canvasWidth ||
        top + height > canvasHeight) {
      return false;
    }

    bool overlaps({
      required double x,
      required double y,
      required double otherWidth,
      required double otherHeight,
    }) =>
        left < x + otherWidth &&
        left + width > x &&
        top < y + otherHeight &&
        top + height > y;

    for (var index = 0; index < tables.length; index++) {
      if (index == ignoredTableIndex) continue;
      final table = tables[index];
      if (overlaps(
        x: table.xCoordinate ?? 0,
        y: table.yCoordinate ?? 0,
        otherWidth: tableSize,
        otherHeight: tableSize,
      )) {
        return false;
      }
    }
    for (var index = 0; index < zones.length; index++) {
      if (index == ignoredZoneIndex) continue;
      final zone = zones[index];
      if (overlaps(
        x: zone.xCoordinate ?? 0,
        y: zone.yCoordinate ?? 0,
        otherWidth: zone.width ?? 160,
        otherHeight: zone.height ?? 80,
      )) {
        return false;
      }
    }
    return true;
  }

  void _showOverlapNotice() {
    if (_overlapNoticeShown) return;
    _overlapNoticeShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stolovi i zone se ne mogu preklapati.')),
    );
  }

  Future<void> _showTableDialog({Tables? table, int? index}) async {
    var canDelete = table?.canDelete ?? true;
    final tableId = table?.id;
    if (tableId != null && tableId > 0) {
      try {
        final currentTable = await tableProvider.getById(tableId);
        canDelete = currentTable.canDelete;
      } catch (e) {
        if (mounted) {
          _showError('Nije moguće provjeriti rezervacije i uplate stola: $e');
        }
        return;
      }
    }
    if (!mounted) return;

    _tableDialogError = null;
    final nameController = TextEditingController(text: table?.name ?? '');
    int guests = table?.numberOfGuests ?? 2;
    final isEdit = table != null;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Row(
            children: [
              Expanded(child: Text(isEdit ? 'Uredi stol' : 'Novi stol')),
              IconButton(
                tooltip: 'Zatvori',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Naziv stola',
                  border: OutlineInputBorder(),
                ),
                maxLength: 40,
              ),
              if (_tableDialogError != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _tableDialogError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (!canDelete)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Brisanje je onemogućeno dok stol ima aktivnu ili buduću rezervaciju ili nezavršeno plaćanje.',
                    style: TextStyle(color: Colors.red),
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
                onPressed: !canDelete
                    ? null
                    : () async {
                        if (await _confirmDeleteTable(index!) &&
                            context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                style: TextButton.styleFrom(
                  foregroundColor: !canDelete ? Colors.grey : Colors.red,
                ),
                child: const Text('Obriši'),
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
                if (nameController.text.trim().isEmpty) {
                  setStateDialog(
                    () => _tableDialogError = 'Naziv stola je obavezan.',
                  );
                  return;
                }
                final position = isEdit
                    ? null
                    : _findFreePosition(width: tableSize, height: tableSize);
                if (!isEdit && position == null) {
                  setStateDialog(
                    () => _tableDialogError =
                        'Nema slobodnog mjesta na tlocrtu za novi stol.',
                  );
                  return;
                }
                setState(() {
                  if (isEdit) {
                    tables[index!] = tables[index].copyWith(
                      name: nameController.text.trim(),
                      numberOfGuests: guests,
                    );
                  } else {
                    tables.add(
                      Tables(
                        id: 0,
                        name: nameController.text.trim(),
                        localeId: widget.localeId,
                        xCoordinate: position!.dx,
                        yCoordinate: position.dy,
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
    ).whenComplete(nameController.dispose);
  }

  void _showZoneDialog({Zone? zone, int? index}) {
    _zoneDialogError = null;
    final nameController = TextEditingController(text: zone?.name ?? '');
    double width = zone?.width ?? 160;
    double height = zone?.height ?? 80;
    final isEdit = zone != null;
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Row(
            children: [
              Expanded(child: Text(isEdit ? 'Uredi zonu' : 'Nova zona')),
              IconButton(
                tooltip: 'Zatvori',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Naziv zone',
                  border: OutlineInputBorder(),
                ),
                maxLength: 40,
              ),
              if (_zoneDialogError != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _zoneDialogError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
                onPressed: () async {
                  if (await _confirmDeleteZone(index!) && context.mounted) {
                    Navigator.pop(context);
                  }
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
                if (nameController.text.trim().isEmpty) {
                  setStateDialog(
                    () => _zoneDialogError = 'Naziv zone je obavezan.',
                  );
                  return;
                }
                final position = isEdit
                    ? null
                    : _findFreePosition(width: width, height: height);
                final left = isEdit ? zone.xCoordinate ?? 0 : position?.dx ?? 0;
                final top = isEdit ? zone.yCoordinate ?? 0 : position?.dy ?? 0;
                if (position == null && !isEdit) {
                  setStateDialog(
                    () => _zoneDialogError =
                        'Nema slobodnog mjesta na tlocrtu za novu zonu.',
                  );
                  return;
                }
                if (!_canPlaceElement(
                  left: left,
                  top: top,
                  width: width,
                  height: height,
                  ignoredZoneIndex: index,
                )) {
                  setStateDialog(
                    () => _zoneDialogError =
                        'Zona se ne može preklapati s drugim elementima.',
                  );
                  return;
                }
                setState(() {
                  if (isEdit) {
                    zones[index!] = zones[index].copyWith(
                      name: nameController.text.trim(),
                      width: width,
                      height: height,
                    );
                  } else {
                    zones.add(
                      Zone(
                        id: 0,
                        name: nameController.text.trim(),
                        localeId: widget.localeId,
                        xCoordinate: position!.dx,
                        yCoordinate: position.dy,
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
    ).whenComplete(nameController.dispose);
  }

  Future<bool> _confirmDeleteTable(int index) async {
    final name = tables[index].name ?? 'stol';
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Brisanje stola')),
            IconButton(
              tooltip: 'Zatvori',
              onPressed: () => Navigator.pop(dialogContext, false),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: Text(
          'Želite li obrisati "$name"? Promjena se primjenjuje tek nakon snimanja tlocrta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Obriši', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return false;
    setState(() => tables.removeAt(index));
    return true;
  }

  Future<bool> _confirmDeleteZone(int index) async {
    final name = zones[index].name ?? 'zonu';
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Brisanje zone')),
            IconButton(
              tooltip: 'Zatvori',
              onPressed: () => Navigator.pop(dialogContext, false),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: Text(
          'Želite li obrisati "$name"? Promjena se primjenjuje tek nakon snimanja tlocrta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Obriši', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return false;
    setState(() => zones.removeAt(index));
    return true;
  }

  void _confirmSave() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Spremi raspored')),
            IconButton(
              tooltip: 'Zatvori',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
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
      await tableProvider.saveLayout(widget.localeId, tables);
      await zoneProvider.saveLayout(widget.localeId, zones);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Raspored uspješno snimljen!',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            width: 320,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError(e.toString());
    }
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
          final newX = (x + details.delta.dx)
              .clamp(0, canvasWidth - tableSize)
              .toDouble();
          final newY = (y + details.delta.dy)
              .clamp(0, canvasHeight - tableSize)
              .toDouble();
          if (!_canPlaceElement(
            left: newX,
            top: newY,
            width: tableSize,
            height: tableSize,
            ignoredTableIndex: index,
          )) {
            _showOverlapNotice();
            return;
          }
          setState(() {
            tables[index] = table.copyWith(
              xCoordinate: newX,
              yCoordinate: newY,
            );

            x = newX;
            y = newY;
          });
        },
        onPanEnd: (_) => _overlapNoticeShown = false,
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
          final newX = (x + details.delta.dx)
              .clamp(0, canvasWidth - w)
              .toDouble();
          final newY = (y + details.delta.dy)
              .clamp(0, canvasHeight - h)
              .toDouble();
          if (!_canPlaceElement(
            left: newX,
            top: newY,
            width: w,
            height: h,
            ignoredZoneIndex: index,
          )) {
            _showOverlapNotice();
            return;
          }
          setState(() {
            zones[index] = zone.copyWith(xCoordinate: newX, yCoordinate: newY);
            x = newX;
            y = newY;
          });
        },
        onPanEnd: (_) => _overlapNoticeShown = false,
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
