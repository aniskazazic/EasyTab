import 'dart:convert';
import 'dart:io';
import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/user.dart';
import 'package:easytab_desktop/providers/auth_provider.dart';
import 'package:easytab_desktop/providers/user_provider.dart';
import 'package:easytab_desktop/providers/utils.dart';
import 'package:easytab_desktop/widgets/desktop_password_section.dart';
import 'package:easytab_desktop/widgets/owner_sidebar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class OwnerSettingsScreen extends StatefulWidget {
  const OwnerSettingsScreen({super.key});

  @override
  State<OwnerSettingsScreen> createState() => _OwnerSettingsScreenState();
}

class _OwnerSettingsScreenState extends State<OwnerSettingsScreen> {
  final formKey = GlobalKey<FormBuilderState>();
  late UserProvider userProvider;
  bool isLoading = true;
  File? _imageFile;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userId =
        int.tryParse(AuthProvider.accessTokenDecoded?['Id'] ?? '0') ?? 0;
    if (userId == 0) {
      if (mounted) setState(() => isLoading = false);
      return;
    }
    try {
      final freshUser = await userProvider.getById(userId);
      if (!mounted) return;
      setState(() {
        AuthProvider.currentUser = freshUser;
        isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        formKey.currentState?.patchValue({
          'firstName': freshUser.firstName,
          'lastName': freshUser.lastName,
          'username': freshUser.username,
          'email': freshUser.email,
          'phoneNumber': freshUser.phoneNumber,
          'birthDate': freshUser.birthDate,
        });
      });
    } catch (e) {
      debugPrint('Greska pri ucitavanju korisnika: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Greska'),
        content: Text(message.replaceAll('Exception: ', '')),
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
        title: const Text('Uspjesno'),
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
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _imageFile = File(result.files.single.path!));
    }
  }

  Future<void> _handleSave() async {
    formKey.currentState?.saveAndValidate();
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => isLoading = true);
    var profileUpdated = false;
    try {
      final request = Map<String, dynamic>.from(
        formKey.currentState?.value ?? {},
      );
      if (_imageFile != null)
        request['profilePicture'] = base64Encode(_imageFile!.readAsBytesSync());
      if (request['birthDate'] is DateTime) {
        request['birthDate'] = (request['birthDate'] as DateTime)
            .toUtc()
            .toIso8601String();
      }
      request.removeWhere(
        (key, value) => value == null || value.toString().isEmpty,
      );
      final currentPassword = request.remove('currentPassword');
      final newPassword = request.remove('password');
      final passwordConfirmation = request.remove('passwordConfirmation');
      final userId = AuthProvider.currentUser?.id;
      if (userId == null) {
        _showError('Korisnik nije prijavljen!');
        return;
      }
      final updatedUser = await userProvider.update(userId, request);
      AuthProvider.currentUser = updatedUser;
      profileUpdated = true;
      if (_changePassword) {
        await userProvider.changePassword({
          'id': userId,
          'password': currentPassword,
          'newPassword': newPassword,
          'confirmNewPassword': passwordConfirmation,
        });
      }
      if (mounted) _showSuccess('Podaci uspjesno azurirani!');
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      _showError(
        profileUpdated
            ? 'Profil je sacuvan, ali lozinka nije promijenjena: $message'
            : message,
      );
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
        content: const Text('Da li ste sigurni da zelite obrisati sliku?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Otkazi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await userProvider.update(user!.id!, {'profilePicture': ''});
                if (!mounted) return;
                setState(() => AuthProvider.currentUser?.profilePicture = null);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Slika uspjesno obrisana!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: const Text('Obrisi', style: TextStyle(color: Colors.white)),
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
      child: isLoading && user == null
          ? const Center(child: CircularProgressIndicator())
          : _buildOwnerSettings(user),
    );
  }

  Column _buildOwnerSettings(User? user) {
    return Column(
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
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : imageProviderFromString(user?.profilePicture),
                          child:
                              user?.profilePicture == null && _imageFile == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            _imageFile != null
                                ? 'Slika odabrana'
                                : 'Promijeni sliku',
                          ),
                        ),
                        if (user?.profilePicture != null && _imageFile == null)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('Obrisi sliku'),
                            onPressed: _confirmDeleteImage,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
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
                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderTextField(
                          name: 'username',
                          decoration: const InputDecoration(
                            labelText: 'Korisnicko ime',
                            border: OutlineInputBorder(),
                          ),
                          enabled: user != null,
                          validator: user != null
                              ? FormBuilderValidators.required(
                                  errorText: 'Korisnicko ime je obavezno',
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
                  Row(
                    children: [
                      Expanded(
                        child: FormBuilderDateTimePicker(
                          name: 'birthDate',
                          inputType: InputType.date,
                          format: DateFormat('dd/MM/yyyy'),
                          decoration: const InputDecoration(
                            labelText: 'Datum rodjenja',
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
                  DesktopPasswordSection(
                    formKey: formKey,
                    isSelf: true,
                    onChanged: (value) => _changePassword = value,
                  ),
                ],
              ),
            ),
          ),
        ),
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
    );
  }
}
