import 'dart:io';
import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/locale.dart' as models;
import 'package:easytab_desktop/providers/file_provider.dart';
import 'package:easytab_desktop/providers/locale_provider.dart';
import 'package:easytab_desktop/providers/user_provider.dart';
import 'package:easytab_desktop/providers/worker_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

class AdminAddUserScreen extends StatefulWidget {
  final VoidCallback? onSaved;

  const AdminAddUserScreen({super.key, this.onSaved});

  @override
  State<AdminAddUserScreen> createState() => _AdminAddUserScreenState();
}

class _AdminAddUserScreenState extends State<AdminAddUserScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late UserProvider userProvider;
  late WorkerProvider workerProvider;
  late LocaleProvider localeProvider;
  late FileProvider fileProvider;

  final _userFormKey = GlobalKey<FormBuilderState>();
  final _ownerFormKey = GlobalKey<FormBuilderState>();
  final _workerFormKey = GlobalKey<FormBuilderState>();

  File? _userImage;
  File? _ownerImage;
  File? _workerImage;

  List<models.Locale> _locales = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    userProvider = context.read<UserProvider>();
    workerProvider = context.read<WorkerProvider>();
    localeProvider = context.read<LocaleProvider>();
    fileProvider = context.read<FileProvider>();
    _loadLocales();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLocales() async {
    try {
      final result = await localeProvider.get(filter: {"RetrieveAll": true});
      setState(() => _locales = result.items ?? []);
    } catch (e) {
      debugPrint('Error loading locales: $e');
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

  Future<void> _pickImage(Function(File) onPicked) async {
    var result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      onPicked(File(result.files.single.path!));
    }
  }

  Future<Map<String, dynamic>> _buildRequest(
    GlobalKey<FormBuilderState> formKey,
    File? image,
    String subfolder,
  ) async {
    var request = Map<String, dynamic>.from(formKey.currentState?.value ?? {});

    if (image != null) {
      final imageUrl = await fileProvider.uploadImage(image, subfolder);
      request['profilePicture'] = imageUrl;
    }

    if (request['birthDate'] is DateTime) {
      request['birthDate'] = (request['birthDate'] as DateTime)
          .toIso8601String();
    }

    request.removeWhere(
      (key, value) => value == null || value.toString().isEmpty,
    );

    return request;
  }

  // Spremi korisnika
  Future<void> _saveUser() async {
    _userFormKey.currentState?.saveAndValidate();
    if (!(_userFormKey.currentState?.validate() ?? false)) return;

    setState(() => isLoading = true);
    try {
      var request = await _buildRequest(
        _userFormKey,
        _userImage,
        'ImageFolder/ProfilePictures',
      );
      //request['roleIds'] = [3]; // User rola
      await userProvider.insert(request);
      _showSuccess('Korisnik uspješno dodan!');
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Spremi vlasnika
  Future<void> _saveOwner() async {
    _ownerFormKey.currentState?.saveAndValidate();
    if (!(_ownerFormKey.currentState?.validate() ?? false)) return;

    setState(() => isLoading = true);
    try {
      var request = await _buildRequest(
        _ownerFormKey,
        _ownerImage,
        'ImageFolder/ProfilePictures',
      );
      request['roleIds'] = [2]; // Owner rola
      await userProvider.insert(request);
      _showSuccess('Vlasnik uspješno dodan!');
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Spremi radnika
  Future<void> _saveWorker() async {
    _workerFormKey.currentState?.saveAndValidate();
    if (!(_workerFormKey.currentState?.validate() ?? false)) return;

    setState(() => isLoading = true);
    try {
      var request = await _buildRequest(
        _workerFormKey,
        _workerImage,
        'ImageFolder/ProfilePictures',
      );

      request['localeId'] = _workerFormKey.currentState?.value['localeId'];
      request['roleIds'] = [3];

      await workerProvider.insert(request);
      _showSuccess('Radnik uspješno dodan!');
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Dodaj korisnika',
      child: Column(
        children: [
          // Tab bar
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1E40AF),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF1E40AF),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Korisnik'),
                Tab(text: 'Vlasnik'),
                Tab(text: 'Radnik'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildUserTab(), _buildOwnerTab(), _buildWorkerTab()],
            ),
          ),
        ],
      ),
    );
  }

  // ─── KORISNIK TAB ───
  Widget _buildUserTab() {
    return Column(
      children: [
        Expanded(
          child: FormBuilder(
            key: _userFormKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildNameRow(_userFormKey),
                  const SizedBox(height: 16),
                  _buildUsernameEmailRow(_userFormKey),
                  const SizedBox(height: 16),
                  _buildPhoneBirthRow(_userFormKey),
                  const SizedBox(height: 16),
                  _buildPasswordRow(_userFormKey),
                  const SizedBox(height: 16),
                  _buildImagePicker(
                    image: _userImage,
                    onPick: () =>
                        _pickImage((f) => setState(() => _userImage = f)),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildSaveButton('Dodaj korisnika', _saveUser),
      ],
    );
  }

  // ─── VLASNIK TAB ───
  Widget _buildOwnerTab() {
    return Column(
      children: [
        Expanded(
          child: FormBuilder(
            key: _ownerFormKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildNameRow(_ownerFormKey),
                  const SizedBox(height: 16),
                  _buildUsernameEmailRow(_ownerFormKey),
                  const SizedBox(height: 16),
                  _buildPhoneBirthRow(_ownerFormKey),
                  const SizedBox(height: 16),
                  _buildPasswordRow(_ownerFormKey),
                  const SizedBox(height: 16),
                  _buildImagePicker(
                    image: _ownerImage,
                    onPick: () =>
                        _pickImage((f) => setState(() => _ownerImage = f)),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildSaveButton('Dodaj vlasnika', _saveOwner),
      ],
    );
  }

  // ─── RADNIK TAB ───
  Widget _buildWorkerTab() {
    return Column(
      children: [
        Expanded(
          child: FormBuilder(
            key: _workerFormKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildNameRow(_workerFormKey),
                  const SizedBox(height: 16),
                  _buildUsernameEmailRow(_workerFormKey),
                  const SizedBox(height: 16),
                  _buildPhoneBirthRow(_workerFormKey),
                  const SizedBox(height: 16),
                  _buildPasswordRow(_workerFormKey),
                  const SizedBox(height: 16),

                  // Lokal dropdown — samo za radnika
                  FormBuilderDropdown<int>(
                    name: 'localeId',
                    decoration: const InputDecoration(
                      labelText: 'Lokal',
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: 'Odaberite lokal',
                    ),
                    items: _locales
                        .map(
                          (l) => DropdownMenuItem(
                            value: l.id,
                            child: Text(l.name ?? ''),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  _buildImagePicker(
                    image: _workerImage,
                    onPick: () =>
                        _pickImage((f) => setState(() => _workerImage = f)),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildSaveButton('Dodaj radnika', _saveWorker),
      ],
    );
  }

  // ─── SHARED WIDGETS ───

  Widget _buildNameRow(GlobalKey<FormBuilderState> key) {
    return Row(
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
    );
  }

  Widget _buildUsernameEmailRow(GlobalKey<FormBuilderState> key) {
    return Row(
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
              FormBuilderValidators.required(errorText: 'Email je obavezan'),
              FormBuilderValidators.email(errorText: 'Unesite validan email'),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneBirthRow(GlobalKey<FormBuilderState> key) {
    return Row(
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
      ],
    );
  }

  Widget _buildPasswordRow(GlobalKey<FormBuilderState> formKey) {
    return Row(
      children: [
        Expanded(
          child: FormBuilderTextField(
            name: 'password',
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Lozinka',
              border: OutlineInputBorder(),
            ),
            validator: FormBuilderValidators.required(
              errorText: 'Lozinka je obavezna',
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FormBuilderTextField(
            name: 'passwordConfirmation',
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Potvrda lozinke',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final password =
                  formKey.currentState?.fields['password']?.value as String?;
              if (value == null || value.isEmpty)
                return 'Potvrda lozinke je obavezna';
              if (password != null && password.isNotEmpty && value != password)
                return 'Lozinke se ne podudaraju';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker({
    required File? image,
    required VoidCallback onPick,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.grey.shade100,
          ),
          child: ClipOval(
            child: image != null
                ? Image.file(image, fit: BoxFit.cover)
                : const Icon(Icons.person, size: 40, color: Colors.grey),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: onPick,
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
                    image != null ? 'Slika odabrana ✓' : 'Odaberite sliku',
                    style: TextStyle(
                      color: image != null ? Colors.green : Colors.grey,
                    ),
                  ),
                  const Icon(Icons.file_upload),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E40AF),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
        ),
      ),
    );
  }
}
