import 'package:easytab_mobile/exceptions/api_exception.dart';
import 'package:easytab_mobile/models/create_order_response.dart';
import 'package:easytab_mobile/models/payment_response.dart';
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

String _chargeDetails(CreateOrderResponse order) =>
    'Cijena rezervacije: ${order.amountKm.toStringAsFixed(2)} KM\n'
    'PayPal naplaćuje: ${order.amount.toStringAsFixed(2)} ${order.currency}\n'
    'Primijenjeni kurs: 1 ${order.currency} = ${order.exchangeRate} KM\n'
    'Iznos u ${order.currency} je zaokružen na 2 decimale.';

Future<bool> _confirmPayment(
  BuildContext context,
  CreateOrderResponse order,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: dialogTitle(ctx, 'Potvrda plaćanja'),
        content: Text(_chargeDetails(order)),
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
  bool _busy = false;
  PaymentResponse? _payment;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pay();
    });
  }

  Future<void> _pay() async {
    if (_busy || _payment != null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final reservations = context.read<ReservationProvider>();
    final recommendations = context.read<RecommendationProvider>();
    try {
      final order = _order ?? await _payments.createOrder(widget.request);
      if (!mounted) return;
      setState(() => _order = order);
      if (!_approved) {
        if (!await _confirmPayment(context, order)) {
          if (mounted) {
            setState(
              () => _message =
                  'Plaćanje nije pokrenuto. Rezervacija nije kreirana. Možete pokušati ponovo ili zatvoriti ekran.',
            );
          }
          return;
        }
        if (!mounted) return;
        final result = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (_) =>
                PayPalCheckoutScreen(approvalUrl: order.approvalUrl),
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
      final payment = await _payments.capture(order.orderId);
      if (!payment.isCompleted) {
        throw ApiClientException(
          'Naplata nije potvrđena. Provjerite status ponovnim pokušajem.',
        );
      }
      recommendations.invalidate();
      if (mounted) setState(() => _payment = payment);
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
            if (_payment != null) ...[
              if (_busy) ...[
                const LinearProgressIndicator(),
                const Text(
                  'Osvježavanje podataka rezervacije je u toku. Molimo sačekajte.',
                ),
              ],
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              Text(
                'Plaćeno · ${_payment!.amountKm.toStringAsFixed(2)} KM '
                '(${_payment!.amount.toStringAsFixed(2)} ${_payment!.currency})',
                textAlign: TextAlign.center,
              ),
              const Text(
                'Rezervacija je kreirana i čeka potvrdu lokala.',
                textAlign: TextAlign.center,
              ),
            ] else ...[
              if (_order == null) ...[
                Text('Cijena: ${widget.price.toStringAsFixed(2)} KM'),
                const Text(
                  'Iznos naplate i primijenjeni kurs preuzimaju se sa servera prije potvrde plaćanja.',
                ),
              ] else
                Text(_chargeDetails(_order!)),
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
