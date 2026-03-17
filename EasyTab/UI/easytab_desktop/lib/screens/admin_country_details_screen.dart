import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/country.dart';
import 'package:easytab_desktop/providers/country_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

class AdminCountryDetailsScreen extends StatefulWidget {
  final Country? country;
  const AdminCountryDetailsScreen({super.key, this.country});

  @override
  State<AdminCountryDetailsScreen> createState() =>
      _AdminCountryDetailsScreenState();
}

class _AdminCountryDetailsScreenState extends State<AdminCountryDetailsScreen> {
  final formKey = GlobalKey<FormBuilderState>();
  late CountryProvider countryProvider;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    countryProvider = Provider.of<CountryProvider>(context, listen: false);
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

  void _showSuccess(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uspješno'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    formKey.currentState?.saveAndValidate();
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() => isLoading = true);
    try {
      var request = Map<String, dynamic>.from(
        formKey.currentState?.value ?? {},
      );
      if (widget.country == null) {
        await countryProvider.insert(request);
        _showSuccess('Država uspješno dodana!');
      } else {
        await countryProvider.update(widget.country!.id!, request);
        _showSuccess('Država uspješno ažurirana!');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: widget.country == null ? 'Nova država' : 'Uredi državu',
      child: Column(
        children: [
          Expanded(
            child: FormBuilder(
              key: formKey,
              initialValue: {"name": widget.country?.name ?? ''},
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: FormBuilderTextField(
                  name: "name",
                  decoration: const InputDecoration(
                    labelText: "Naziv države",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Naziv je obavezan'
                      : null,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isLoading ? null : _handleSave,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.country == null
                            ? 'Dodaj državu'
                            : 'Spremi izmjene',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
