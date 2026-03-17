import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/city.dart';
import 'package:easytab_desktop/models/country.dart';
import 'package:easytab_desktop/models/search_result.dart';
import 'package:easytab_desktop/providers/city_provider.dart';
import 'package:easytab_desktop/providers/country_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

class AdminCityDetailsScreen extends StatefulWidget {
  final City? city;
  const AdminCityDetailsScreen({super.key, this.city});

  @override
  State<AdminCityDetailsScreen> createState() => _AdminCityDetailsScreenState();
}

class _AdminCityDetailsScreenState extends State<AdminCityDetailsScreen> {
  final formKey = GlobalKey<FormBuilderState>();
  late CityProvider cityProvider;
  late CountryProvider countryProvider;
  SearchResult<Country>? countries;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cityProvider = Provider.of<CityProvider>(context, listen: false);
    countryProvider = Provider.of<CountryProvider>(context, listen: false);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      countries = await countryProvider.get(filter: {"RetrieveAll": true});
      setState(() => isLoading = false);
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
      if (widget.city == null) {
        await cityProvider.insert(request);
        _showSuccess('Grad uspješno dodan!');
      } else {
        await cityProvider.update(widget.city!.id!, request);
        _showSuccess('Grad uspješno ažuriran!');
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
      title: widget.city == null ? 'Novi grad' : 'Uredi grad',
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: FormBuilder(
                    key: formKey,
                    initialValue: {
                      "name": widget.city?.name ?? '',
                      "countryId": widget.city?.countryId,
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        children: [
                          FormBuilderTextField(
                            name: "name",
                            decoration: const InputDecoration(
                              labelText: "Naziv grada",
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Naziv je obavezan'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          FormBuilderDropdown(
                            name: "countryId",
                            decoration: const InputDecoration(
                              labelText: "Država",
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value == null ? 'Država je obavezna' : null,
                            items:
                                countries?.items
                                    ?.map(
                                      (c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.name ?? ''),
                                      ),
                                    )
                                    .toList() ??
                                [],
                          ),
                        ],
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
                      child: Text(
                        widget.city == null ? 'Dodaj grad' : 'Spremi izmjene',
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
