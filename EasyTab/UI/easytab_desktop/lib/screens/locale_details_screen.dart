import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/category.dart';
import 'package:easytab_desktop/models/city.dart';
import 'package:easytab_desktop/models/country.dart';
import 'package:easytab_desktop/models/locale.dart';
import 'package:easytab_desktop/models/search_result.dart';
import 'package:easytab_desktop/models/user.dart';
import 'package:easytab_desktop/providers/category_provider.dart';
import 'package:easytab_desktop/providers/city_provider.dart';
import 'package:easytab_desktop/providers/country_provider.dart';
import 'package:easytab_desktop/providers/locale_provider.dart';
import 'package:easytab_desktop/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

class LocaleDetailsScreen extends StatefulWidget {
  final Locale? locale;

  const LocaleDetailsScreen({super.key, this.locale});

  @override
  State<LocaleDetailsScreen> createState() => _LocaleDetailsScreenState();
}

class _LocaleDetailsScreenState extends State<LocaleDetailsScreen> {
  final formKey = GlobalKey<FormBuilderState>();

  late LocaleProvider localeProvider;
  late CityProvider cityProvider;
  late CountryProvider countryProvider;
  late CategoryProvider categoryProvider;
  late UserProvider userProvider;

  List<Country> _countries = [];
  List<City> _allCities = [];
  List<City> _filteredCities = [];
  List<Category> _categories = [];
  List<User> _owners = [];

  int? selectedCountryId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    countryProvider = Provider.of<CountryProvider>(context, listen: false);
    cityProvider = Provider.of<CityProvider>(context, listen: false);
    userProvider = Provider.of<UserProvider>(context, listen: false);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        categoryProvider.get(filter: {"RetrieveAll": true}),
        countryProvider.get(filter: {"RetrieveAll": true}),
        cityProvider.get(filter: {"RetrieveAll": true}),
        userProvider.get(filter: {"RetrieveAll": true}),
      ]);

      final allUsers = (results[3] as SearchResult<User>).items ?? [];

      setState(() {
        _categories = (results[0] as SearchResult<Category>).items ?? [];
        _countries = (results[1] as SearchResult<Country>).items ?? [];
        _allCities = (results[2] as SearchResult<City>).items ?? [];

        // Filtriraj samo ownere
        _owners = allUsers
            .where(
              (u) => u.userRoles?.any((r) => r.role?.name == 'Owner') ?? false,
            )
            .toList();

        // Ako je edit, postavi odabranu državu i filtriraj gradove
        if (widget.locale?.cityId != null) {
          final city = _allCities.firstWhere(
            (c) => c.id == widget.locale!.cityId,
            orElse: () => City(),
          );
          selectedCountryId = city.countryId;
          _filteredCities = selectedCountryId != null
              ? _allCities
                    .where((c) => c.countryId == selectedCountryId)
                    .toList()
              : [];
        }

        isLoading = false;
      });
      // U _loadData() nakon učitavanja usera dodaj:
      print("Svi useri: ${allUsers.length}");
      for (var u in allUsers) {
        print(
          "User: ${u.firstName}, Roles: ${u.userRoles?.map((r) => r.role?.name).toList()}",
        );
      }
      print("Owneri: ${_owners.length}");
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

    var request = Map<String, dynamic>.from(formKey.currentState?.value ?? {});

    // Ukloni prazna polja
    request.removeWhere(
      (key, value) => value == null || value.toString().isEmpty,
    );

    try {
      if (widget.locale == null) {
        await localeProvider.insert(request);
        _showSuccess('Lokal uspješno dodan!');
      } else {
        await localeProvider.update(widget.locale!.id!, request);
        _showSuccess('Lokal uspješno ažuriran!');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: widget.locale == null ? 'Novi lokal' : 'Uredi lokal',
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _buildForm()),
                _buildSaveButton(),
              ],
            ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E40AF),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _handleSave,
          child: Text(
            widget.locale == null ? 'Dodaj lokal' : 'Spremi izmjene',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return FormBuilder(
      key: formKey,
      initialValue: {
        "name": widget.locale?.name ?? '',
        "address": widget.locale?.address ?? '',
        "lengthOfReservation":
            widget.locale?.lengthOfReservation?.toString() ?? '',
        "phoneNumber": widget.locale?.phoneNumber ?? '',
        "cityId": widget.locale?.cityId,
        "categoryId": widget.locale?.categoryId,
        "ownerId": widget.locale?.ownerId,
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            // Naziv i adresa
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: "name",
                    decoration: const InputDecoration(
                      labelText: "Naziv lokala",
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: 'Naziv je obavezan',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderTextField(
                    name: "address",
                    decoration: const InputDecoration(
                      labelText: "Adresa",
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: 'Adresa je obavezna',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Telefon i duzina rezervacije
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: "phoneNumber",
                    decoration: const InputDecoration(
                      labelText: "Broj telefona",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderTextField(
                    name: "lengthOfReservation",
                    decoration: const InputDecoration(
                      labelText: "Dužina rezervacije (sati)",
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: 'Dužina rezervacije je obavezna',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Država i grad
            Row(
              children: [
                // Dropdown za državu
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selectedCountryId,
                    decoration: const InputDecoration(
                      labelText: "Država",
                      border: OutlineInputBorder(),
                    ),
                    items: _countries
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCountryId = value;
                        // Reset grad i filtriraj gradove
                        _filteredCities = value == null
                            ? []
                            : _allCities
                                  .where((c) => c.countryId == value)
                                  .toList();
                      });
                      // Reset cityId u formi
                      formKey.currentState?.fields['cityId']?.didChange(null);
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Dropdown za grad
                // Dropdown za grad
                Expanded(
                  child: FormBuilderDropdown<int>(
                    name: "cityId",
                    decoration: InputDecoration(
                      labelText: "Grad",
                      labelStyle: TextStyle(
                        color: selectedCountryId == null ? Colors.grey : null,
                      ),
                      border: const OutlineInputBorder(),
                      hintText: selectedCountryId == null
                          ? 'Prvo odaberite državu'
                          : null,
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    enabled: selectedCountryId != null,
                    validator: FormBuilderValidators.required(
                      errorText: 'Grad je obavezan',
                    ),
                    items: _filteredCities
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name ?? ''),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Kategorija i vlasnik
            Row(
              children: [
                // Dropdown za kategoriju
                Expanded(
                  child: FormBuilderDropdown<int>(
                    name: "categoryId",
                    decoration: const InputDecoration(
                      labelText: "Kategorija",
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: 'Kategorija je obavezna',
                    ),
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name ?? ''),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(width: 16),

                // Dropdown za vlasnika
                Expanded(
                  child: FormBuilderDropdown<int>(
                    name: "ownerId",
                    decoration: const InputDecoration(
                      labelText: "Vlasnik",
                      border: OutlineInputBorder(),
                    ),
                    // Ukloni hint — samo labelText
                    validator: FormBuilderValidators.required(
                      errorText: 'Vlasnik je obavezan',
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Odaberite vlasnika'),
                      ),
                      ..._owners.map(
                        (u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(
                            '${u.firstName ?? ''} ${u.lastName ?? ''}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
