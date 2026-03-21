import 'dart:io';
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
import 'package:easytab_desktop/providers/file_provider.dart';
import 'package:easytab_desktop/providers/user_provider.dart';
import 'package:file_picker/file_picker.dart';
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
  late FileProvider fileProvider;
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

  bool get _isInsert => widget.locale == null;

  @override
  void initState() {
    super.initState();
    localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    fileProvider = Provider.of<FileProvider>(context, listen: false);
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

        if (_isInsert) userProvider.get(filter: {"RetrieveAll": true}),
      ]);

      setState(() {
        _categories = (results[0] as SearchResult<Category>).items ?? [];
        _countries = (results[1] as SearchResult<Country>).items ?? [];
        _allCities = (results[2] as SearchResult<City>).items ?? [];

        if (_isInsert) {
          final allUsers = (results[3] as SearchResult<User>).items ?? [];
          _owners = allUsers
              .where(
                (u) =>
                    u.userRoles?.any((r) => r.role?.name == 'Owner') ?? false,
              )
              .toList();
        }

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

    if (_image != null) {
      final imageUrl = await fileProvider.uploadImage(
        _image!,
        'ImageFolder/LocaleLogo',
      );
      request['logo'] = imageUrl;
    }

    for (final key in ['startOfWorkingHours', 'endOfWorkingHours']) {
      final val = request[key];
      if (val is TimeOfDay) {
        final h = val.hour.toString().padLeft(2, '0');
        final m = val.minute.toString().padLeft(2, '0');
        request[key] = '$h:$m:00';
      }
    }

    request.removeWhere(
      (key, value) => value == null || value.toString().isEmpty,
    );

    try {
      if (_isInsert) {
        await localeProvider.insert(request);
        _showSuccess('Lokal uspješno dodan!');
      } else {
        request.remove('ownerId');
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
      title: _isInsert ? 'Novi lokal' : 'Uredi lokal',
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
            _isInsert ? 'Dodaj lokal' : 'Spremi izmjene',
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

        if (_isInsert) "ownerId": null,
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
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

            Row(
              children: [
                Expanded(
                  child: FormBuilderField<TimeOfDay>(
                    name: "startOfWorkingHours",
                    validator: FormBuilderValidators.required(
                      errorText: 'Početak radnog vremena je obavezan',
                    ),
                    builder: (field) {
                      final time = field.value;
                      return InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: time ?? TimeOfDay.now(),
                          );
                          if (picked != null) field.didChange(picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Početak radnog vremena',
                            border: const OutlineInputBorder(),
                            errorText: field.errorText,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                time != null
                                    ? time.format(context)
                                    : 'Odaberite vrijeme',
                                style: TextStyle(
                                  color: time != null ? null : Colors.grey,
                                ),
                              ),
                              const Icon(Icons.access_time),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderField<TimeOfDay>(
                    name: "endOfWorkingHours",
                    validator: FormBuilderValidators.required(
                      errorText: 'Kraj radnog vremena je obavezan',
                    ),
                    builder: (field) {
                      final time = field.value;
                      return InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: time ?? TimeOfDay.now(),
                          );
                          if (picked != null) field.didChange(picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Kraj radnog vremena',
                            border: const OutlineInputBorder(),
                            errorText: field.errorText,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                time != null
                                    ? time.format(context)
                                    : 'Odaberite vrijeme',
                                style: TextStyle(
                                  color: time != null ? null : Colors.grey,
                                ),
                              ),
                              const Icon(Icons.access_time),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
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

            Row(
              children: [
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
                if (_isInsert) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: FormBuilderDropdown<int>(
                      name: "ownerId",
                      decoration: const InputDecoration(
                        labelText: "Vlasnik",
                        border: OutlineInputBorder(),
                      ),
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
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Preview
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
                        // Puni URL koji dolazi iz MapToResponse
                        ? Image.network(
                            widget.locale!.logo!,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) =>
                                progress == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 36,
                                color: Colors.grey,
                              ),
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
                // Picker
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: getImage,
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
                      if (!_isInsert &&
                          widget.locale?.logo != null &&
                          _image == null)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Obriši logo'),
                          onPressed: () => _deleteImage(
                            fileUrl: widget.locale!.logo!,
                            subfolder: 'ImageFolder/LocaleLogo',
                            onDeleted: () async {
                              await localeProvider.update(widget.locale!.id!, {
                                'name': widget.locale!.name,
                                'address': widget.locale!.address,
                                'logo': '',
                              });
                              if (mounted) Navigator.pop(context);
                            },
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

  File? _image;

  void getImage() async {
    var result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _image = File(result.files.single.path!);
      });
    }
  }

  Future<void> _deleteImage({
    required String fileUrl,
    required String subfolder,
    required VoidCallback onDeleted,
  }) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Brisanje slike'),
        content: const Text('Da li ste sigurni da želite obrisati sliku?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await fileProvider.deleteImage(fileUrl, subfolder);
                onDeleted();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Slika uspješno obrisana!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: const Text('Obriši', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
