import 'dart:io';
import 'package:easytab_desktop/models/category.dart';
import 'package:easytab_desktop/models/city.dart';
import 'package:easytab_desktop/models/country.dart';
import 'package:easytab_desktop/models/locale.dart' as model;
import 'package:easytab_desktop/models/search_result.dart';
import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:easytab_desktop/providers/category_provider.dart';
import 'package:easytab_desktop/providers/city_provider.dart';
import 'package:easytab_desktop/providers/country_provider.dart';
import 'package:easytab_desktop/providers/file_provider.dart';
import 'package:easytab_desktop/providers/locale_provider.dart';
import 'package:easytab_desktop/widgets/owner_sidebar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

class OwnerLocaleDetailsScreen extends StatefulWidget {
  final model.Locale? locale;
  final VoidCallback? onSaved;

  const OwnerLocaleDetailsScreen({super.key, this.locale, this.onSaved});

  @override
  State<OwnerLocaleDetailsScreen> createState() =>
      _OwnerLocaleDetailsScreenState();
}

class _OwnerLocaleDetailsScreenState extends State<OwnerLocaleDetailsScreen> {
  final formKey = GlobalKey<FormBuilderState>();

  late LocaleProvider localeProvider;
  late FileProvider fileProvider;
  late CityProvider cityProvider;
  late CountryProvider countryProvider;
  late CategoryProvider categoryProvider;

  List<Country> _countries = [];
  List<City> _allCities = [];
  List<City> _filteredCities = [];
  List<Category> _categories = [];

  int? selectedCountryId;
  bool isLoading = true;
  File? _image;

  bool get _isInsert => widget.locale == null;

  @override
  void initState() {
    super.initState();
    localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    fileProvider = Provider.of<FileProvider>(context, listen: false);
    categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    countryProvider = Provider.of<CountryProvider>(context, listen: false);
    cityProvider = Provider.of<CityProvider>(context, listen: false);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        categoryProvider.get(filter: {"RetrieveAll": true}),
        countryProvider.get(filter: {"RetrieveAll": true}),
        cityProvider.get(filter: {"RetrieveAll": true}),
      ]);

      setState(() {
        _categories = (results[0] as SearchResult<Category>).items ?? [];
        _countries = (results[1] as SearchResult<Country>).items ?? [];
        _allCities = (results[2] as SearchResult<City>).items ?? [];

        // Postavi državu i gradove za edit
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
              widget.onSaved?.call();
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

    var request = Map<String, dynamic>.from(formKey.currentState!.value);

    // Upload slike ako je odabrana
    if (_image != null) {
      final imageUrl = await fileProvider.uploadImage(
        _image!,
        'ImageFolder/LocaleLogo',
      );
      request['logo'] = imageUrl;
    }

    // Formatiraj vremena
    for (final key in ['startOfWorkingHours', 'endOfWorkingHours']) {
      final val = request[key];
      if (val is TimeOfDay) {
        final h = val.hour.toString().padLeft(2, '0');
        final m = val.minute.toString().padLeft(2, '0');
        request[key] = '$h:$m:00';
      }
    }

    // Ukloni prazna polja
    request.removeWhere(
      (key, value) => value == null || value.toString().isEmpty,
    );

    // Automatski dodaj ownerId od logiranog usera
    if (_isInsert) {
      request['ownerId'] = AuthProvider.currentUser?.id;
    } else {
      request.remove('ownerId');
    }

    try {
      if (_isInsert) {
        await localeProvider.insert(request);
        _showSuccess('Lokal uspješno dodan!');
      } else {
        await localeProvider.update(widget.locale!.id!, request);
        _showSuccess('Postavke uspješno sačuvane!');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _getImage() async {
    var result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _image = File(result.files.single.path!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const OwnerSidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nazad + naslov
                  Row(
                    children: [
                      if (Navigator.canPop(context))
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Nazad'),
                        ),
                      if (Navigator.canPop(context)) const SizedBox(width: 16),
                      Text(
                        _isInsert ? 'Novi lokal' : 'Postavke lokala',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Expanded(child: _buildForm()),
                  if (!isLoading) _buildSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E40AF),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _handleSave,
          child: Text(
            _isInsert ? 'Dodaj lokal' : 'Spremi postavke',
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
        "startOfWorkingHours": widget.locale?.startOfWorkingHours != null
            ? TimeOfDay.fromDateTime(widget.locale!.startOfWorkingHours!)
            : null,
        "endOfWorkingHours": widget.locale?.endOfWorkingHours != null
            ? TimeOfDay.fromDateTime(widget.locale!.endOfWorkingHours!)
            : null,
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
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

            // Telefon i dužina rezervacije
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

            // Radno vrijeme
            Row(
              children: [
                Expanded(
                  child: FormBuilderField<TimeOfDay>(
                    name: "startOfWorkingHours",
                    validator: FormBuilderValidators.required(
                      errorText: 'Početak radnog vremena je obavezan',
                    ),
                    builder: (field) => InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime:
                              field.value ??
                              const TimeOfDay(hour: 8, minute: 0),
                        );
                        if (picked != null) field.didChange(picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Početak radnog vremena',
                          border: const OutlineInputBorder(),
                          errorText: field.errorText,
                        ),
                        child: Text(
                          field.value != null
                              ? field.value!.format(context)
                              : 'Odaberite vrijeme',
                          style: TextStyle(
                            color: field.value != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderField<TimeOfDay>(
                    name: "endOfWorkingHours",
                    validator: FormBuilderValidators.required(
                      errorText: 'Kraj radnog vremena je obavezan',
                    ),
                    builder: (field) => InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime:
                              field.value ??
                              const TimeOfDay(hour: 23, minute: 0),
                        );
                        if (picked != null) field.didChange(picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Kraj radnog vremena',
                          border: const OutlineInputBorder(),
                          errorText: field.errorText,
                        ),
                        child: Text(
                          field.value != null
                              ? field.value!.format(context)
                              : 'Odaberite vrijeme',
                          style: TextStyle(
                            color: field.value != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Država i grad
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selectedCountryId,
                    decoration: const InputDecoration(
                      labelText: "Država",
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Odaberite državu'),
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
                        _filteredCities = value == null
                            ? []
                            : _allCities
                                  .where((c) => c.countryId == value)
                                  .toList();
                      });
                      formKey.currentState?.fields['cityId']?.didChange(null);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderDropdown<int>(
                    name: "cityId",
                    decoration: InputDecoration(
                      labelText: "Grad",
                      border: const OutlineInputBorder(),
                      hintText: selectedCountryId == null
                          ? 'Prvo odaberite državu'
                          : null,
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

            // Kategorija
            FormBuilderDropdown<int>(
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
            const SizedBox(height: 16),

            // Logo
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _image != null
                        ? Image.file(_image!, fit: BoxFit.cover)
                        : widget.locale?.logo != null
                        ? Image.network(
                            widget.locale!.logo!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.store,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: _getImage,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Logo lokala',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _image != null
                                ? 'Nova slika odabrana ✓'
                                : widget.locale?.logo != null
                                ? 'Promijeni logo'
                                : 'Odaberite logo',
                            style: TextStyle(
                              color: _image != null
                                  ? Colors.green
                                  : widget.locale?.logo != null
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                          ),
                          const Icon(Icons.file_upload),
                        ],
                      ),
                    ),
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
