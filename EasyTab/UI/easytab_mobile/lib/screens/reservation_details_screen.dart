import 'package:easytab_mobile/models/locale.dart' as model;
import 'package:easytab_mobile/models/table.dart';
import 'package:easytab_mobile/models/time_slot.dart';
import 'package:easytab_mobile/providers/reservation_provider.dart';
import 'package:flutter/material.dart';

class ReservationDetailsScreen extends StatefulWidget {
  final model.Locale locale;
  final Tables selectedTable;

  const ReservationDetailsScreen({
    super.key,
    required this.locale,
    required this.selectedTable,
  });

  @override
  State<ReservationDetailsScreen> createState() =>
      _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState extends State<ReservationDetailsScreen> {
  DateTime _selectedDate = DateTime.now();

  int? _selectedSlotIndex;
  bool _isProcessing = false;

  List<TimeSlot> _slots = [];
  bool _slotsLoading = false;
  String? _slotsError;

  final ReservationProvider _reservationProvider = ReservationProvider();

  model.Locale get locale => widget.locale;
  Tables get table => widget.selectedTable;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    final tableId = table.id;
    if (tableId == null) return;

    setState(() {
      _slotsLoading = true;
      _slotsError = null;
      _selectedSlotIndex = null;
    });

    try {
      final slots = await _reservationProvider.getAvailableSlots(
        tableId,
        _selectedDate,
      );
      print(
        '[Slots] tableId=$tableId date=$_selectedDate count=${slots.length}',
      );
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _slotsLoading = false;
      });
    } catch (e) {
      print('[Slots] ERROR: $e');
      if (!mounted) return;
      setState(() {
        _slotsError = 'Greška pri učitavanju termina.';
        _slotsLoading = false;
      });
    }
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E40AF),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedSlotIndex = null;
      });
      _loadSlots();
    }
  }

  Future<void> _processPayment() async {
    if (_selectedSlotIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Molimo odaberite termin'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isProcessing = false);

    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    final slot = _slots[_selectedSlotIndex!];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF16A34A),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Rezervacija potvrđena!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _confirmRow('Lokal', locale.name ?? '-'),
                    const SizedBox(height: 6),
                    _confirmRow('Stol', table.name ?? '-'),
                    const SizedBox(height: 6),
                    _confirmRow('Datum', _fmtDate(_selectedDate)),
                    const SizedBox(height: 6),
                    _confirmRow('Termin', '${slot.start} - ${slot.end}'),
                    const SizedBox(height: 6),
                    _confirmRow(
                      'Gosti',
                      '${table.numberOfGuests ?? '-'} ${(table.numberOfGuests ?? 0) == 1 ? 'osoba' : 'osobe/a'}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Zatvori',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _confirmRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14.5, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTableInfoBanner(),
                  _buildDateAndGuestsSection(),
                  _buildTimeSlotsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildPayButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF1E40AF)),
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
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rezervišite - "${table.name ?? 'Stol'}"',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    locale.name ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableInfoBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E40AF),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E40AF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.table_restaurant,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  table.name ?? 'Odabrani stol',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Kapacitet: ${table.numberOfGuests ?? '-'} ${(table.numberOfGuests ?? 0) == 1 ? 'osoba' : 'osobe/a'}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 15),
                SizedBox(width: 4),
                Text(
                  'Odabran',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtGuestCount(int? count) {
    if (count == null) return '-';
    if (count == 1) return '1 osoba';
    if (count >= 2 && count <= 4) return '$count osobe';
    return '$count osoba';
  }

  Widget _buildDateAndGuestsSection() {
    final guestsText = _fmtGuestCount(table.numberOfGuests);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _SectionCard(
              label: 'Datum',
              child: GestureDetector(
                onTap: _pickDate,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: Color(0xFF1E40AF),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}.',
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Color(0xFF64748B),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SectionCard(
              label: 'Broj gostiju',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 20,
                    color: Color(0xFF1E40AF),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    guestsText,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
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

  Widget _buildTimeSlotsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dostupni termini :',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          if (_slotsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: Color(0xFF1E40AF)),
              ),
            )
          else if (_slotsError != null)
            _buildErrorCard(_slotsError!)
          else if (_slots.isEmpty)
            _buildNoSlotsCard()
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _slots.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemBuilder: (context, i) {
                final slot = _slots[i];
                final isSelected = _selectedSlotIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSlotIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1E40AF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1E40AF).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Text(
                      '${slot.start} - ${slot.end}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 36, color: Color(0xFFE57373)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 13),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _loadSlots,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Pokušaj ponovo'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSlotsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.schedule_outlined, size: 36, color: Color(0xFFCBD5E1)),
          SizedBox(height: 8),
          Text(
            'Nema dostupnih termina za odabrani datum.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return Container(
      color: const Color(0xFFF5F7FA),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                disabledBackgroundColor: const Color(0xFF93C5FD),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Rezerviši i plati',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outlined, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                'Plaćanje putem PayPal-a  ·  100% sigurno',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String label;
  final Widget child;

  const _SectionCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(height: 30, child: child),
        ],
      ),
    );
  }
}
