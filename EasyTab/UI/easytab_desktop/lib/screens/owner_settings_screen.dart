import 'dart:io';
import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:easytab_desktop/providers/file_provider.dart';
import 'package:easytab_desktop/providers/user_provider.dart';
import 'package:easytab_desktop/widgets/owner_sidebar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

class OwnerSettingsScreen extends StatefulWidget {
  const OwnerSettingsScreen({super.key});

  @override
  State<OwnerSettingsScreen> createState() => _OwnerSettingsScreenState();
}

class _OwnerSettingsScreenState extends State<OwnerSettingsScreen> {
  final formKey = GlobalKey<FormBuilderState>();
  late UserProvider userProvider;
  late FileProvider fileProvider;
  bool isLoading = false;
  File? _imageFile;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirmation = true;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    fileProvider = Provider.of<FileProvider>(context, listen: false);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userId = AuthProvider.currentUser?.id;
    if (userId == null) return;

    try {
      final freshUser = await userProvider.getById(userId);
      if (mounted) {
        setState(() {
          AuthProvider.currentUser = freshUser;
        });
      }
    } catch (e) {
      debugPrint('Greška pri učitavanju korisnika: $e');
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
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
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
      setState(() => _imageFile = File(result.files.single.path!));
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

      request.removeWhere(
        (key, value) => value == null || value.toString().isEmpty,
      );

      final userId = AuthProvider.currentUser?.id;
      if (userId == null) {
        _showError('Greška: Korisnik nije prijavljen!');
        return;
      }

      final updatedUser = await userProvider.update(userId, request);
      AuthProvider.currentUser = updatedUser;

      if (mounted) {
        _showSuccess('Podaci uspješno ažurirani!');
      }
    } catch (e) {
      _showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _confirmDeleteImage() async {
    final user = AuthProvider.currentUser;
    if (user?.profilePicture == null) return;

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
                await fileProvider.deleteImage(
                  user!.profilePicture!,
                  'ImageFolder/ProfilePictures',
                  userId: user.id,
                );
                if (mounted) {
                  setState(() {
                    AuthProvider.currentUser = AuthProvider.currentUser
                      ?..profilePicture = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Slika uspješno obrisana!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // _showSuccess('Slika uspješno obrisana!');
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

  @override
  Widget build(BuildContext context) {
    final user = AuthProvider.currentUser;

    return MasterScreen(
      title: 'Postavke',
      sidebar: const OwnerSidebar(),
      child: Column(
        children: [
          Expanded(
            child: FormBuilder(
              key: formKey,
              initialValue: {
                'firstName': user?.firstName ?? '',
                'lastName': user?.lastName ?? '',
                'username': user?.username ?? '',
                'email': user?.email ?? '',
                'phoneNumber': user?.phoneNumber ?? '',
                'birthDate': user?.birthDate,
                'password': '',
                'passwordConfirmation': '',
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profilna slika
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                              color: Colors.grey.shade100,
                            ),
                            child: ClipOval(
                              child: _imageFile != null
                                  ? Image.file(_imageFile!, fit: BoxFit.cover)
                                  : user?.profilePicture != null
                                  ? Image.network(
                                      user!.profilePicture!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Dugme promijeni sliku — uvijek vidljivo
                          TextButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.camera_alt),
                            label: Text(
                              _imageFile != null
                                  ? 'Slika odabrana ✓'
                                  : 'Promijeni sliku',
                              style: TextStyle(
                                color: _imageFile != null
                                    ? Colors.green
                                    : const Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                          // Dugme obriši — samo ako postoji slika u bazi i nije odabrana nova
                          if (user?.profilePicture != null &&
                              _imageFile == null)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Obriši sliku'),
                              onPressed: _confirmDeleteImage,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

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

                    // username i email
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'username',
                            decoration: const InputDecoration(
                              labelText: "Korisničko ime",
                              border: OutlineInputBorder(),
                            ),
                            enabled: user != null,
                            validator: user != null
                                ? FormBuilderValidators.required(
                                    errorText: 'Korisničko ime je obavezno',
                                  )
                                : null,
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

                    // Datum rođenja i broj telefona
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderDateTimePicker(
                            name: 'birthDate',
                            inputType: InputType.date,
                            decoration: const InputDecoration(
                              labelText: 'Datum rođenja',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'phoneNumber',
                            decoration: const InputDecoration(
                              labelText: 'Broj telefona',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Separator
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Promjena lozinke',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Lozinka
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'password',
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText:
                                  'Nova lozinka (ostavite prazno ukoliko ne mijenjate lozinku)',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'passwordConfirmation',
                            obscureText: _obscurePasswordConfirmation,
                            decoration: InputDecoration(
                              labelText: 'Potvrda nove lozinke',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePasswordConfirmation
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePasswordConfirmation =
                                      !_obscurePasswordConfirmation,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final password =
                                  formKey
                                          .currentState
                                          ?.fields['password']
                                          ?.value
                                      as String?;
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
                  ],
                ),
              ),
            ),
          ),

          // Dugme spremi
          Padding(
            padding: const EdgeInsets.all(16),
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
                    : const Text(
                        'Spremi izmjene',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
