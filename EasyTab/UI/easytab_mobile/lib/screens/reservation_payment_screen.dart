import 'package:easytab_mobile/exceptions/api_exception.dart';
import 'package:easytab_mobile/models/create_order_response.dart';
import 'package:easytab_mobile/models/reservation_checkout_request.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/payment_provider.dart';
import 'package:easytab_mobile/providers/recommendation_provider.dart';
import 'package:easytab_mobile/providers/reservation_provider.dart';
import 'package:easytab_mobile/screens/paypal_checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easytab_mobile/widgets/form_feedback.dart';
import 'package:easytab_mobile/providers/utils.dart';

const paymentCurrencyNote =
    'Naplata se vrši u EUR po fiksnom kursu 1 EUR = 1,95583 KM';

Future<bool> confirmReservationPayment(
  BuildContext context,
  double price,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: dialogTitle(ctx, 'Potvrda plaćanja'),
        content: Text(
          'Plaćate ${price.toStringAsFixed(2)} KM za rezervaciju.\n\n$paymentCurrencyNote',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Plati'),
          ),
        ],
      ),
    ) ??
    false;

class ReservationPaymentScreen extends StatefulWidget {
  final ReservationCheckoutRequest request;
  final double price;
  final String localeName;
  final String? localeLogo;
  const ReservationPaymentScreen({
    super.key,
    required this.request,
    required this.price,
    required this.localeName,
    this.localeLogo,
  });

  @override
  State<ReservationPaymentScreen> createState() =>
      _ReservationPaymentScreenState();
}

class _ReservationPaymentScreenState extends State<ReservationPaymentScreen> {
  final _payments = PaymentProvider();
  CreateOrderResponse? _order;
  bool _approved = false;
  bool _paid = false;
  bool _busy = false;
  double? _paidAmount;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pay(confirmed: true);
    });
  }

  Future<void> _pay({bool confirmed = false}) async {
    if (_busy || _paid) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final reservations = context.read<ReservationProvider>();
    final recommendations = context.read<RecommendationProvider>();
    try {
      if (!confirmed &&
          !await confirmReservationPayment(context, widget.price)) {
        return;
      }
      if (!mounted) return;
      _order ??= await _payments.createOrder(widget.request);
      if (!mounted) return;
      if (!_approved) {
        final result = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (_) =>
                PayPalCheckoutScreen(approvalUrl: _order!.approvalUrl),
          ),
        );
        if (!mounted) return;
        if (result != 'approved') {
          setState(
            () => _message =
                'Plaćanje je prekinuto. Rezervacija nije kreirana. Možete pokušati ponovo ili zatvoriti ekran.',
          );
          return;
        }
        _approved = true;
      }
      final payment = await _payments.capture(_order!.orderId);
      if (!payment.isCompleted) {
        throw ApiClientException(
          'Naplata nije potvrđena. Provjerite status ponovnim pokušajem.',
        );
      }
      recommendations.invalidate();
      if (mounted) {
        setState(() {
          _paid = true;
          _paidAmount = payment.amountKm;
        });
      }
    } on ApiClientException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Nije moguće potvrditi plaćanje. Provjerite internet vezu i pokušajte ponovo. Ako je naplata izvršena, rezervacija će se prikazati nakon serverske provjere.',
        );
      }
    } finally {
      final userId = AuthProvider.currentUserId;
      if (userId != null) await reservations.loadAll(userId);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _payments.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Plaćanje rezervacije'),
        leading: IconButton(
          tooltip: 'Nazad',
          icon: const Icon(Icons.arrow_back),
          onPressed: _busy ? null : () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            tooltip: 'Zatvori',
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: ImageUtils.buildImage(widget.localeLogo),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.localeName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_paid) ...[
              if (_busy) ...[
                const LinearProgressIndicator(),
                const Text(
                  'Osvježavanje podataka rezervacije je u toku. Molimo sačekajte.',
                ),
              ],
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              Text(
                'Plaćeno · ${_paidAmount!.toStringAsFixed(2)} KM',
                textAlign: TextAlign.center,
              ),
              const Text(
                'Rezervacija je kreirana i čeka potvrdu lokala.',
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text('Cijena: ${widget.price.toStringAsFixed(2)} KM'),
              const Text(paymentCurrencyNote),
              const Text('Rezervacija se kreira tek nakon uspješne naplate.'),
              if (_busy) ...[
                const LinearProgressIndicator(),
                const Text('Obrada plaćanja je u toku. Molimo sačekajte.'),
              ],
              if (_message != null)
                Text(
                  _message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ElevatedButton(
                onPressed: _busy ? null : _pay,
                child: Text(_message == null ? 'Plati' : 'Plati ponovo'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
