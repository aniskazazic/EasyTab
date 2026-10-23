import 'dart:convert';
import 'package:easytab_desktop/exceptions/api_exception.dart';
import 'dart:io';
import 'package:easytab_desktop/models/worker.dart';
import 'package:easytab_desktop/providers/utils.dart';
import 'package:easytab_desktop/providers/worker_provider.dart';
import 'package:easytab_desktop/widgets/desktop_password_section.dart';
import 'package:easytab_desktop/widgets/owner_sidebar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

class OwnerWorkerDetailsScreen extends StatefulWidget {
  final int localeId;
  final Worker? worker;
  final Future<void> Function()? onSaved;

  const OwnerWorkerDetailsScreen({
    super.key,
    required this.localeId,
    this.worker,
    this.onSaved,
  });

  @override
  State<OwnerWorkerDetailsScreen> createState() =>
      _OwnerWorkerDetailsScreenState();
}

class _OwnerWorkerDetailsScreenState extends State<OwnerWorkerDetailsScreen> {
  final formKey = GlobalKey<FormBuilderState>();
  late WorkerProvider workerProvider;
  bool isLoading = false;
  bool _isLoadingWorker = false;
  bool _changePassword = false;
  File? _image;
  String? _profilePictureError;
  Worker? _worker;
  bool get _isInsert => widget.worker == null;

  @override
  void initState() {
    super.initState();
    workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    _worker = widget.worker;
    if (_worker?.id != null) _loadWorker(_worker!.id!);
  }

  Future<void> _loadWorker(int id) async {
    setState(() => _isLoadingWorker = true);
    try {
      final worker = await workerProvider.getById(id);
      if (mounted) setState(() => _worker = worker);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingWorker = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
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
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uspješno'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () async {
              await widget.onSaved?.call();
              if (!mounted) return;
              navigator.pop();
              navigator.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _getImage() async {
    var result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _image = File(result.files.single.path!);
        _profilePictureError = null;
      });
    }
  }

  Future<void> _handleSave() async {
    formKey.currentState?.saveAndValidate();
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() => isLoading = true);

    try {
      final request = Map<String, dynamic>.from(
        formKey.currentState?.value ?? {},
      );

      // Formatiraj datum rođenja
      final birthDate = request['birthDate'];
      if (birthDate is DateTime) {
        request['birthDate'] = birthDate.toIso8601String().split('T').first;
      }

      // Upload slike ako je odabrana
      if (_image != null) {
        request['profilePicture'] = base64Encode(_image!.readAsBytesSync());
      }

      // Ukloni prazna polja
      request.removeWhere(
        (key, value) => value == null || value.toString().isEmpty,
      );

      if (_isInsert) {
        request['localeId'] = widget.localeId;
        await workerProvider.insert(request);
        _showSuccess('Radnik uspješno dodan!');
      } else {
        final newPassword = request.remove('password');
        final passwordConfirmation = request.remove('passwordConfirmation');
        if (!_changePassword) {
          request.remove('password');
        } else if (newPassword != passwordConfirmation) {
          _showError('Lozinke se ne podudaraju.');
          return;
        }
        await workerProvider.update(_worker!.id!, request);

        _showSuccess('Radnik uspješno ažuriran!');
      }
    } catch (e) {
      final message = e.toString().replaceAll("Exception: ", "");
      final imageError = e is ApiClientException
          ? e.imageValidationErrors['profilePicture']
          : null;
      if (imageError != null) {
        setState(() => _profilePictureError = imageError);
      } else {
        _showError(message);
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          OwnerSidebar(activeLocaleId: widget.localeId),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (Navigator.canPop(context))
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Nazad'),
                        ),
                      const SizedBox(width: 16),
                      Text(
                        _isInsert ? 'Novi radnik' : 'Uredi radnika',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _isLoadingWorker
                        ? const Center(child: CircularProgressIndicator())
                        : _buildForm(),
                  ),
                  _buildSaveButton(),
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
          onPressed: isLoading || _isLoadingWorker ? null : _handleSave,
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  _isInsert ? 'Dodaj radnika' : 'Spremi izmjene',
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
        'firstName': _worker?.firstName ?? '',
        'lastName': _worker?.lastName ?? '',
        'username': _worker?.username ?? '',
        'email': _worker?.email ?? '',
        'phoneNumber': _worker?.phoneNumber ?? '',
        'password': '',
        'passwordConfirmation': '',
        'birthDate': _worker?.birthDate,
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Profilna slika
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipOval(
                    child: _image != null
                        ? Image.file(_image!, fit: BoxFit.cover)
                        : imageProviderFromString(_worker?.profilePicture) !=
                              null
                        ? Image(
                            image: imageProviderFromString(
                              _worker?.profilePicture,
                            )!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey,
                          ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _getImage,
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Profilna slika',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _image != null
                                    ? 'Nova slika odabrana ✓'
                                    : _worker?.profilePicture != null
                                    ? 'Promijeni sliku'
                                    : 'Odaberite sliku',
                                style: TextStyle(
                                  color: _image != null
                                      ? Colors.green
                                      : _worker?.profilePicture != null
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                              ),
                              const Icon(Icons.file_upload),
                            ],
                          ),
                        ),
                      ),
                      if (_profilePictureError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _profilePictureError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      // Dugme za brisanje — prikazuje se samo ako ima sliku
                      if (!_isInsert &&
                          _worker?.profilePicture != null &&
                          _image == null)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Obriši sliku'),
                          onPressed: _confirmDeleteProfilePicture,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ime i prezime
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'firstName',
                    decoration: const InputDecoration(
                      labelText: 'Ime',
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: 'Ime je obavezno',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'lastName',
                    decoration: const InputDecoration(
                      labelText: 'Prezime',
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: 'Prezime je obavezno',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Username i email
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'username',
                    decoration: const InputDecoration(
                      labelText: 'Korisničko ime',
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: 'Korisničko ime je obavezno',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'email',
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                        errorText: 'Email je obavezan',
                      ),
                      FormBuilderValidators.email(
                        errorText: 'Unesite validan email',
                      ),
                    ]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Telefon i datum rođenja
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'phoneNumber',
                    decoration: const InputDecoration(
                      labelText: 'Broj telefona',
                      border: OutlineInputBorder(),
                    ),
                    validator: validatePhone,
                  ),
                ),
                const SizedBox(width: 16),
                // Datum rođenja
                Expanded(
                  child: FormBuilderField<DateTime>(
                    name: 'birthDate',
                    builder: (field) => InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: field.value ?? DateTime(1990, 1, 1),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) field.didChange(picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Datum rođenja',
                          border: const OutlineInputBorder(),
                          errorText: field.errorText,
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          field.value != null
                              ? formatDateOnly(field.value!)
                              : 'Odaberite datum rođenja',
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

            DesktopPasswordSection(
              formKey: formKey,
              isSelf: false,
              isRequired: _isInsert,
              showSwitch: !_isInsert,
              onChanged: (value) => _changePassword = value,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteProfilePicture() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Brisanje slike')),
            IconButton(
              tooltip: 'Zatvori',
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: const Text('Da li ste sigurni da želite obrisati sliku?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Obriši', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || _worker?.id == null) return;

    try {
      await workerProvider.update(_worker!.id!, {
        'firstName': _worker!.firstName,
        'lastName': _worker!.lastName,
        'profilePicture': '',
      });
      await widget.onSaved?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slika uspješno obrisana.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }
}
