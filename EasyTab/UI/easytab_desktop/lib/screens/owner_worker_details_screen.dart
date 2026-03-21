import 'dart:io';
import 'package:easytab_desktop/models/worker.dart';
import 'package:easytab_desktop/providers/file_provider.dart';
import 'package:easytab_desktop/providers/worker_provider.dart';
import 'package:easytab_desktop/widgets/owner_sidebar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

class OwnerWorkerDetailsScreen extends StatefulWidget {
  final int localeId;
  final Worker? worker;
  final VoidCallback? onSaved;

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
  late FileProvider fileProvider;
  bool isLoading = false;
  File? _image;

  bool get _isInsert => widget.worker == null;

  @override
  void initState() {
    super.initState();
    workerProvider = Provider.of<WorkerProvider>(context, listen: false);
    fileProvider = Provider.of<FileProvider>(context, listen: false);
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

  void _getImage() async {
    var result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _image = File(result.files.single.path!));
    }
  }

  Future<void> _handleSave() async {
    formKey.currentState?.saveAndValidate();
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() => isLoading = true);

    try {
      var request = Map<String, dynamic>.from(
        formKey.currentState?.value ?? {},
      );

      // Formatiraj datum rođenja
      final birthDate = request['birthDate'];
      if (birthDate is DateTime) {
        request['birthDate'] = birthDate.toIso8601String();
      }

      // Upload slike ako je odabrana
      if (_image != null) {
        final imageUrl = await fileProvider.uploadImage(
          _image!,
          'ImageFolder/ProfilePictures',
        );
        request['profilePicture'] = imageUrl;
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
        await workerProvider.update(widget.worker!.id!, request);
        _showSuccess('Radnik uspješno ažuriran!');
      }
    } catch (e) {
      _showError(e.toString());
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
                  Expanded(child: _buildForm()),
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
          onPressed: isLoading ? null : _handleSave,
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
        'firstName': widget.worker?.firstName ?? '',
        'lastName': widget.worker?.lastName ?? '',
        'username': widget.worker?.username ?? '',
        'email': widget.worker?.email ?? '',
        'phoneNumber': widget.worker?.phoneNumber ?? '',
        'password': '',
        'passwordConfirmation': '',
        'birthDate': widget.worker?.birthDate,
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
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
                              ? '${field.value!.day}.${field.value!.month}.${field.value!.year}'
                              : 'Odaberite datum',
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

            // Lozinka
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'password',
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _isInsert
                          ? 'Lozinka'
                          : 'Nova lozinka (ostavite prazno)',
                      border: const OutlineInputBorder(),
                    ),
                    validator: _isInsert
                        ? FormBuilderValidators.required(
                            errorText: 'Lozinka je obavezna',
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'passwordConfirmation',
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _isInsert
                          ? 'Potvrda lozinke'
                          : 'Potvrda nove lozinke',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final password =
                          formKey.currentState?.fields['password']?.value
                              as String?;
                      if (_isInsert && (value == null || value.isEmpty)) {
                        return 'Potvrda lozinke je obavezna';
                      }
                      if (password != null &&
                          password.isNotEmpty &&
                          value != password) {
                        return 'Lozinke se ne podudaraju';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                        : widget.worker?.profilePicture != null
                        ? Image.network(
                            widget.worker!.profilePicture!,
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
                                    : widget.worker?.profilePicture != null
                                    ? 'Promijeni sliku'
                                    : 'Odaberite sliku',
                                style: TextStyle(
                                  color: _image != null
                                      ? Colors.green
                                      : widget.worker?.profilePicture != null
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                              ),
                              const Icon(Icons.file_upload),
                            ],
                          ),
                        ),
                      ),
                      // Dugme za brisanje — prikazuje se samo ako ima sliku
                      if (!_isInsert &&
                          widget.worker?.profilePicture != null &&
                          _image == null)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Obriši sliku'),
                          onPressed: () => _deleteImage(
                            fileUrl: widget.worker!.profilePicture!,
                            subfolder: 'ImageFolder/ProfilePictures',
                            onDeleted: () async {
                              // Postavi sliku na null u bazi
                              await workerProvider.update(widget.worker!.id!, {
                                'firstName': widget.worker!.firstName,
                                'lastName': widget.worker!.lastName,
                                'profilePicture': '',
                              });
                              widget.onSaved?.call();
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
