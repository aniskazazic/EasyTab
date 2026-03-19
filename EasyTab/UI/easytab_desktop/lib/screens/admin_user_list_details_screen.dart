import 'dart:io';

import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/user.dart';
import 'package:easytab_desktop/providers/user_provider.dart';
import 'package:easytab_desktop/providers/file_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

class AdminUserDetailsScreen extends StatefulWidget {
  final User? user;

  const AdminUserDetailsScreen({super.key, this.user});

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  final formKey = GlobalKey<FormBuilderState>();
  late UserProvider userProvider;
  late FileProvider fileProvider;
  bool isLoading = false;

  File? _imageFile;

  bool get _isInsert => widget.user == null;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
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
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    var result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _imageFile = File(result.files.single.path!);
      });
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

      // Upload na FileController -> dobij puni URL -> backend izvuce filename
      if (_imageFile != null) {
        final imageUrl = await fileProvider.uploadImage(
          _imageFile!,
          'ImageFolder/ProfilePictures',
        );
        request['profilePicture'] = imageUrl;
      }

      if (request['birthDate'] is DateTime) {
        request['birthDate'] = (request['birthDate'] as DateTime)
            .toIso8601String();
      }

      // Ukloni prazna polja
      request.removeWhere(
        (key, value) => value == null || value.toString().isEmpty,
      );

      if (_isInsert) {
        await userProvider.insert(request);
        _showSuccess('Korisnik uspješno dodan!');
      } else {
        await userProvider.update(widget.user!.id!, request);
        _showSuccess('Korisnik uspješno ažuriran!');
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
      title: _isInsert ? 'Novi korisnik' : 'Uredi korisnika',
      child: Column(
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
          onPressed: isLoading ? null : _handleSave,
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  _isInsert ? 'Dodaj korisnika' : 'Spremi izmjene',
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
        "firstName": widget.user?.firstName ?? '',
        "lastName": widget.user?.lastName ?? '',
        "username": widget.user?.username ?? '',
        "email": widget.user?.email ?? '',
        "phoneNumber": widget.user?.phoneNumber ?? '',
        "birthDate": widget.user?.birthDate,
        "password": '',
        "passwordConfirmation": '',
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: "firstName",
                    decoration: const InputDecoration(
                      labelText: "Ime",
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
                    name: "lastName",
                    decoration: const InputDecoration(
                      labelText: "Prezime",
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

            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: "username",
                    decoration: const InputDecoration(
                      labelText: "Korisničko ime",
                      border: OutlineInputBorder(),
                    ),
                    enabled: _isInsert,
                    validator: _isInsert
                        ? FormBuilderValidators.required(
                            errorText: 'Korisničko ime je obavezno',
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderTextField(
                    name: "email",
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_isInsert && (value == null || value.isEmpty))
                        return 'Email je obavezan';
                      if (value != null &&
                          value.isNotEmpty &&
                          !value.contains('@'))
                        return 'Unesite validan email';
                      return null;
                    },
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
                  child: FormBuilderDateTimePicker(
                    name: "birthDate",
                    inputType: InputType.date,
                    decoration: const InputDecoration(
                      labelText: "Datum rođenja",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: "password",
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _isInsert
                          ? "Lozinka"
                          : "Nova lozinka (ostavite prazno ako ne mijenjate)",
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_isInsert && (value == null || value.isEmpty))
                        return 'Lozinka je obavezna';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderTextField(
                    name: "passwordConfirmation",
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _isInsert
                          ? "Potvrda lozinke"
                          : "Potvrda nove lozinke",
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_isInsert && (value == null || value.isEmpty))
                        return 'Potvrda lozinke je obavezna';
                      final password =
                          formKey.currentState?.fields['password']?.value
                              as String?;
                      if (password != null &&
                          password.isNotEmpty &&
                          value != password)
                        return 'Lozinke se ne podudaraju';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview slike
                if (_imageFile != null || widget.user?.profilePicture != null)
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _imageFile != null
                          ? Image.file(_imageFile!, fit: BoxFit.cover)
                          : Image.network(
                              widget.user!.profilePicture!,
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
                            ),
                    ),
                  ),

                Expanded(
                  child: InkWell(
                    onTap: _pickImage,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Profilna slika",
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _imageFile != null
                                ? 'Slika odabrana ✓'
                                : 'Odaberite sliku',
                            style: TextStyle(
                              color: _imageFile != null
                                  ? Colors.green
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
