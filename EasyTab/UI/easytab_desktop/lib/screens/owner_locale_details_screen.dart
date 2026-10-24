import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:easytab_desktop/widgets/reservation_price_field.dart';
import 'package:easytab_desktop/exceptions/api_exception.dart';
import 'package:easytab_desktop/models/category.dart';
import 'package:easytab_desktop/models/city.dart';
import 'package:easytab_desktop/models/country.dart';
import 'package:easytab_desktop/models/locale.dart' as model;
import 'package:easytab_desktop/models/localeimage.dart';
import 'package:easytab_desktop/models/search_result.dart';
import 'package:easytab_desktop/providers/category_provider.dart';
import 'package:easytab_desktop/providers/city_provider.dart';
import 'package:easytab_desktop/providers/country_provider.dart';
import 'package:easytab_desktop/providers/locale_provider.dart';
import 'package:easytab_desktop/providers/localeimage_provider.dart';
import 'package:easytab_desktop/providers/utils.dart';
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
  late CityProvider cityProvider;
  late CountryProvider countryProvider;
  late CategoryProvider categoryProvider;
  late LocaleImageProvider localeImageProvider;

  SearchResult<LocaleImage>? localeImagesResult;

  List<Country> _countries = [];
  List<City> _allCities = [];
  List<City> _filteredCities = [];
  List<Category> _categories = [];

  List<LocaleImage> newImages = [];

  int? selectedCountryId;
  bool isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  File? _image;
  String? _logoError;
  String? _galleryError;

  bool get _isInsert => widget.locale == null;

  @override
  void initState() {
    super.initState();
    localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    countryProvider = Provider.of<CountryProvider>(context, listen: false);
    cityProvider = Provider.of<CityProvider>(context, listen: false);
    localeImageProvider = Provider.of<LocaleImageProvider>(
      context,
      listen: false,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        categoryProvider.get(filter: {"Page": 1, "PageSize": 100}),
        countryProvider.get(filter: {"Page": 1, "PageSize": 100}),
        cityProvider.get(filter: {"Page": 1, "PageSize": 100}),
      ]);

      var localeimages = SearchResult<LocaleImage>();

      if (widget.locale != null) {
        localeimages = await localeImageProvider.get(
          filter: {"localeId": widget.locale!.id},
        );
      }

      setState(() {
        _categories = (results[0] as SearchResult<Category>).items ?? [];
        _countries = (results[1] as SearchResult<Country>).items ?? [];
        _allCities = (results[2] as SearchResult<City>).items ?? [];

        if (widget.locale != null) {
          localeImagesResult = localeimages;
        }

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
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _loadError = 'Greška pri učitavanju podataka: $e';
      });
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Greška'),
        content: Text(message.replaceAll("Exception: ", "")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Uspješno'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              widget.onSaved?.call();
              Navigator.pop(dialogContext);
              Navigator.pop(dialogContext);
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
      request['logo'] = base64Encode(_image!.readAsBytesSync());
    }

    if (newImages.isNotEmpty) {
      request['images'] = newImages.map((image) => image.toJson()).toList();
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

    request['reservationPrice'] = double.parse(
      (request['reservationPrice'] as String).trim().replaceAll(',', '.'),
    );

    request.removeWhere(
      (key, value) => value == null || value.toString().isEmpty,
    );

    request.remove('ownerId');

    setState(() => _isSaving = true);
    try {
      request['lengthOfReservation'] = double.parse(
        request['lengthOfReservation'] as String,
      );

      if (_isInsert) {
        await localeProvider.insert(request);
        _showSuccess('Lokal uspješno dodan!');
      } else {
        await localeProvider.update(widget.locale!.id!, request);
        _showSuccess('Postavke uspješno sačuvane!');
      }
    } catch (e) {
      final imageErrors = e is ApiClientException
          ? e.imageValidationErrors
          : const <String, String>{};
      if (imageErrors.isNotEmpty) {
        setState(() {
          _logoError = imageErrors['logo'];
          _galleryError = imageErrors['images'];
        });
      } else {
        _showError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _getImage() async {
    var result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _image = File(result.files.single.path!);
        _logoError = null;
      });
    }
  }

  Future<void> _confirmDeleteLogo() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Brisanje loga')),
            IconButton(
              tooltip: 'Zatvori',
              onPressed: () => Navigator.pop(dialogContext, false),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: const Text(
          'Da li ste sigurni da želite obrisati logo lokala?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Obriši', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (shouldDelete != true || widget.locale?.id == null) return;

    try {
      await localeProvider.update(widget.locale!.id!, {
        'logo': '',
        'reservationPrice': widget.locale!.reservationPrice,
      });
      if (!mounted) return;

      setState(() => widget.locale!.logo = null);
      widget.onSaved?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logo je uspješno obrisan.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _deleteLocaleImage(LocaleImage image) async {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Brisanje slike')),
            IconButton(
              tooltip: 'Zatvori',
              onPressed: () => Navigator.pop(dialogContext, false),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: const Text('Da li ste sigurni da želite obrisati ovu sliku?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                if (image.id != 0) {
                  await localeImageProvider.delete(image.id!);
                  if (mounted) {
                    setState(() {
                      localeImagesResult?.items?.removeWhere(
                        (item) => item.id == image.id,
                      );
                    });
                  }
                } else {
                  setState(() {
                    newImages.remove(image);
                    _galleryError = null;
                  });
                }

                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Slika uspješno obrisana!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) _showError(e.toString());
              }
            },
            child: const Text('Obriši', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
                  const SizedBox(height: 15),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _loadError != null
                      ? Expanded(
                          child: Center(
                            child: Text(
                              _loadError!,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Expanded(child: _buildForm()),
                  if (!isLoading && _loadError == null) _buildSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SizedBox _buildImageList() {
    List<LocaleImage> allImages = [];

    if (localeImagesResult?.items != null) {
      allImages.addAll(localeImagesResult!.items!);
    }

    allImages.addAll(newImages);

    return SizedBox(
      height: 150,
      child: ScrollConfiguration(
        behavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {...PointerDeviceKind.values},
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: allImages.length,
          itemBuilder: (context, index) {
            final image = allImages[index];
            if (image.base64Content == null || image.base64Content!.isEmpty) {
              return const SizedBox(
                width: 200,
                child: Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              );
            }
            return Stack(
              children: [
                SizedBox(
                  width: 200,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageFromBase64String(image.base64Content!),
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 13,
                  child: InkWell(
                    onTap: () => _deleteLocaleImage(image),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
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
        'reservationPrice':
            widget.locale?.reservationPrice?.toStringAsFixed(2) ?? '',
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
                        : imageProviderFromString(widget.locale?.logo) != null
                        ? Image(
                            image: imageProviderFromString(
                              widget.locale?.logo,
                            )!,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
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
                      if (_logoError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _logoError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      if (!_isInsert &&
                          widget.locale?.logo != null &&
                          _image == null)
                        TextButton.icon(
                          onPressed: _confirmDeleteLogo,
                          icon: const Icon(Icons.delete),
                          label: const Text('Obriši logo'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                    validator: validatePhone,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderTextField(
                    name: "lengthOfReservation",
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: "Dužina rezervacije (sati)",
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                        errorText: 'Dužina rezervacije je obavezna',
                      ),
                      validateReservationLength,
                    ]),
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
            const ReservationPriceField(),
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
                    key: ValueKey(selectedCountryId),
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
            const SizedBox(height: 8),

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
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
              child: Row(
                children: [
                  Text('Slike lokala', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            if (_galleryError != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _galleryError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            if ((localeImagesResult?.items?.isNotEmpty ?? false) ||
                newImages.isNotEmpty)
              _buildImageList(),
          ],
        ),
      ),
    );
  }

  Future _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );

      if (result != null) {
        setState(() => _galleryError = null);
        for (var file in result.files) {
          var bytes = await file.xFile.readAsBytes();
          final base64String = base64Encode(bytes);
          final extension = file.extension?.toLowerCase().replaceFirst(
            RegExp(r'^\.'),
            '',
          );
          final contentType = extension == 'jpg' || extension == 'jpeg'
              ? 'image/jpeg'
              : extension == 'png'
              ? 'image/png'
              : 'image/${extension ?? ''}';

          setState(() {
            newImages.add(
              LocaleImage(
                id: 0,
                fileName: file.name,
                contentType: contentType,
                base64Content: base64String,
                localeId: 0,
              ),
            );
          });
        }
      }
    } catch (e) {
      _showError(e.toString());
    }
  }
}
