import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:easytab_mobile/widgets/form_feedback.dart';

class PayPalCheckoutScreen extends StatefulWidget {
  final String approvalUrl;
  const PayPalCheckoutScreen({super.key, required this.approvalUrl});

  @override
  State<PayPalCheckoutScreen> createState() => _PayPalCheckoutScreenState();
}

class _PayPalCheckoutScreenState extends State<PayPalCheckoutScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;
  bool _finished = false;
  bool _confirming = false;
  String? _pendingResult;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final path = Uri.tryParse(request.url)?.path ?? '';
            if (request.isMainFrame &&
                (path.endsWith('/paypal/return') ||
                    path.endsWith('/paypal/cancel'))) {
              _finish(
                path.endsWith('/paypal/return') ? 'approved' : 'cancelled',
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame != false) {
              setState(() {
                _failed = true;
                _loading = false;
              });
            }
          },
        ),
      );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _failed = false;
      _loading = true;
    });
    try {
      await _controller.loadRequest(Uri.parse(widget.approvalUrl));
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  void _finish(String result) {
    if (!mounted || _finished) return;
    if (_confirming) {
      _pendingResult = result;
      return;
    }
    setState(() => _finished = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  Future<void> _close() async {
    if (_confirming || _finished) return;
    _confirming = true;
    final close = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: dialogTitle(ctx, 'Prekinuti plaćanje?'),
        content: const Text(
          'Plaćanje je u toku. Bez potvrđene naplate rezervacija neće biti kreirana.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nastavi plaćanje'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
    _confirming = false;
    if (_pendingResult != null) {
      _finish(_pendingResult!);
    } else if (close == true) {
      _finish('cancelled');
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _finished,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _close();
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('PayPal plaćanje'),
        leading: BackButton(onPressed: _close),
        actions: [
          IconButton(
            onPressed: _close,
            tooltip: 'Zatvori',
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_failed) WebViewWidget(controller: _controller),
          if (_loading) const LinearProgressIndicator(),
          if (_failed)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PayPal se nije mogao učitati. Provjerite internet vezu i pokušajte ponovo.',
                    ),
                    ElevatedButton(
                      onPressed: _load,
                      child: const Text('Pokušaj ponovo'),
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
