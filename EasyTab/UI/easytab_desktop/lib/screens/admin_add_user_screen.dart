import 'dart:convert';
import 'dart:io';
import 'package:easytab_desktop/exceptions/api_exception.dart';
import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/locale.dart' as models;
import 'package:easytab_desktop/models/role.dart';
import 'package:easytab_desktop/providers/locale_provider.dart';
import 'package:easytab_desktop/providers/role_provider.dart';
import 'package:easytab_desktop/providers/user_provider.dart';
import 'package:easytab_desktop/providers/utils.dart';
import 'package:easytab_desktop/providers/worker_provider.dart';
import 'package:easytab_desktop/widgets/desktop_password_section.dart';
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
  late RoleProvider roleProvider;

  static const _userRoleName = 'korisnik';
  static const _ownerRoleName = 'vlasnik';
  static const _rolesNotOfferedOnUserTab = {'admin', 'vlasnik', 'radnik'};

  final _userFormKey = GlobalKey<FormBuilderState>();
  final _ownerFormKey = GlobalKey<FormBuilderState>();
  final _workerFormKey = GlobalKey<FormBuilderState>();

  File? _userImage;
  File? _ownerImage;
  File? _workerImage;
  final Map<String, String> _imageErrors = {};

  List<models.Locale> _locales = [];
  bool _isLoadingLocales = true;
  bool _localeLoadFailed = false;
  List<Role> _roles = [];
  bool _isLoadingRoles = true;
  bool _roleLoadFailed = false;
  final Map<String, String> _roleErrors = {};
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    userProvider = context.read<UserProvider>();
    workerProvider = context.read<WorkerProvider>();
    localeProvider = context.read<LocaleProvider>();
    roleProvider = context.read<RoleProvider>();
    _loadLocales();
    _loadRoles();
  }

  static String _roleKey(Role role) => role.name?.trim().toLowerCase() ?? '';

  List<Role> get _userTabRoles => _roles
      .where((role) => !_rolesNotOfferedOnUserTab.contains(_roleKey(role)))
      .toList();

  Role? _roleByName(String name) {
    for (final role in _roles) {
      if (_roleKey(role) == name) return role;
    }
    return null;
  }

  Future<void> _loadRoles() async {
    setState(() {
      _isLoadingRoles = true;
      _roleLoadFailed = false;
    });
    try {
      final roles = await fetchAllPages(
        (filter) => roleProvider.get(filter: filter),
      );
      if (!mounted) return;
      final roleField = _userFormKey.currentState?.fields['roleId'];
      final stillOffered = roles.any(
        (role) =>
            role.id == roleField?.value &&
            !_rolesNotOfferedOnUserTab.contains(_roleKey(role)),
      );
      if (roleField != null && !stillOffered) roleField.didChange(null);
      setState(() => _roles = roles);
    } catch (e) {
      if (mounted) setState(() => _roleLoadFailed = true);
    } finally {
      if (mounted) setState(() => _isLoadingRoles = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLocales() async {
    if (mounted) {
      setState(() {
        _isLoadingLocales = true;
        _localeLoadFailed = false;
      });
    }
    try {
      final locales = await fetchAllPages(
        (filter) => localeProvider.get(filter: filter),
      );
      if (mounted) setState(() => _locales = locales);
    } catch (e) {
      if (mounted) {
        setState(() => _localeLoadFailed = true);
        _showError(userError(e));
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocales = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Greška'),
        content: Text(message),
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
    var result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      onPicked(File(result.files.single.path!));
    }
  }

  void _showImageOrFormError(Object error, String imageKey) {
    final imageError = error is ApiClientException
        ? error.imageValidationErrors['profilePicture']
        : null;
    if (imageError != null) {
      setState(() => _imageErrors[imageKey] = imageError);
      return;
    }

    final roleError = error is ApiClientException
        ? _roleValidationError(error)
        : null;
    if (roleError != null) {
      setState(() => _roleErrors[imageKey] = roleError);
      _loadRoles();
      return;
    }

    _showError(userError(error));
  }

  String? _roleValidationError(ApiClientException error) {
    for (final entry in error.validationErrors.entries) {
      if (entry.key.toLowerCase() == 'roleids' && entry.value.isNotEmpty) {
        return entry.value.first;
      }
    }
    return null;
  }

  Map<String, dynamic> _buildRequest(
    GlobalKey<FormBuilderState> formKey,
    File? image,
  ) {
    var request = Map<String, dynamic>.from(formKey.currentState?.value ?? {});

    if (image != null) {
      request['profilePicture'] = base64Encode(image.readAsBytesSync());
    }

    if (request['birthDate'] is DateTime) {
      request['birthDate'] = (request['birthDate'] as DateTime)
          .toIso8601String()
          .split('T')
          .first;
    }

    request.removeWhere(
      (key, value) => value == null || value.toString().isEmpty,
    );

    return request;
  }

  // Spremi korisnika
  Future<void> _saveUser() async {
    setState(() => _roleErrors.remove('user'));
    _userFormKey.currentState?.saveAndValidate();
    if (!(_userFormKey.currentState?.validate() ?? false)) return;

    setState(() => isLoading = true);
    try {
      var request = _buildRequest(_userFormKey, _userImage);
      request['roleIds'] = [request.remove('roleId')];
      await userProvider.insert(request);
      _showSuccess('Korisnik uspješno dodan!');
    } catch (e) {
      _showImageOrFormError(e, 'user');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Spremi vlasnika
  Future<void> _saveOwner() async {
    final ownerRole = _roleByName(_ownerRoleName);
    if (ownerRole == null) return;

    setState(() => _roleErrors.remove('owner'));
    _ownerFormKey.currentState?.saveAndValidate();
    if (!(_ownerFormKey.currentState?.validate() ?? false)) return;

    setState(() => isLoading = true);
    try {
      var request = _buildRequest(_ownerFormKey, _ownerImage);
      request['roleIds'] = [ownerRole.id];
      await userProvider.insert(request);
      _showSuccess('Vlasnik uspješno dodan!');
    } catch (e) {
      _showImageOrFormError(e, 'owner');
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
      var request = _buildRequest(_workerFormKey, _workerImage);

      request['localeId'] = _workerFormKey.currentState?.value['localeId'];

      await workerProvider.insert(request);
      _showSuccess('Radnik uspješno dodan!');
    } catch (e) {
      _showImageOrFormError(e, 'worker');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Dodaj korisnika',
      showCloseButton: true,
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
                  _buildImagePicker(
                    image: _userImage,
                    error: _imageErrors['user'],
                    onPick: () => _pickImage((file) {
                      setState(() {
                        _userImage = file;
                        _imageErrors.remove('user');
                      });
                    }),
                  ),
                  const SizedBox(height: 16),
                  _buildNameRow(),
                  const SizedBox(height: 16),
                  _buildUsernameEmailRow(),
                  const SizedBox(height: 16),
                  _buildPhoneBirthRow(),
                  const SizedBox(height: 16),
                  _buildUserRoleField(),
                  const SizedBox(height: 16),
                  // Separator
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Lozinka',
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
                  DesktopPasswordSection(
                    formKey: _userFormKey,
                    isRequired: true,
                    showSwitch: false,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        _buildSaveButton('Dodaj korisnika', _roles.isEmpty ? null : _saveUser),
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
                  _buildImagePicker(
                    image: _ownerImage,
                    error: _imageErrors['owner'],
                    onPick: () => _pickImage((file) {
                      setState(() {
                        _ownerImage = file;
                        _imageErrors.remove('owner');
                      });
                    }),
                  ),
                  const SizedBox(height: 16),
                  _buildNameRow(),
                  const SizedBox(height: 16),
                  _buildUsernameEmailRow(),
                  const SizedBox(height: 16),
                  _buildPhoneBirthRow(),
                  const SizedBox(height: 16),
                  _buildOwnerRoleField(),
                  const SizedBox(height: 16),
                  // Separator
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Lozinka',
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
                  DesktopPasswordSection(
                    formKey: _ownerFormKey,
                    isRequired: true,
                    showSwitch: false,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        _buildSaveButton(
          'Dodaj vlasnika',
          _roleByName(_ownerRoleName) == null ? null : _saveOwner,
        ),
      ],
    );
  }

  // ─── RADNIK TAB ───
  Widget _buildWorkerTab() {
    if (_isLoadingLocales) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_localeLoadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Lokale nije moguće učitati. Pokušajte ponovo.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadLocales,
              child: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }

    if (_locales.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Radnika nije moguće dodati jer nema dostupnih lokala. '
            'Prvo dodajte lokal.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: FormBuilder(
            key: _workerFormKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildImagePicker(
                    image: _workerImage,
                    error: _imageErrors['worker'],
                    onPick: () => _pickImage((file) {
                      setState(() {
                        _workerImage = file;
                        _imageErrors.remove('worker');
                      });
                    }),
                  ),
                  const SizedBox(height: 16),
                  _buildNameRow(),
                  const SizedBox(height: 16),
                  _buildUsernameEmailRow(),
                  const SizedBox(height: 16),
                  _buildPhoneBirthRow(),
                  const SizedBox(height: 16),
                  _buildFixedRoleField('Radnik'),
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
                  // Separator
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Lozinka',
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
                  DesktopPasswordSection(
                    formKey: _workerFormKey,
                    isRequired: true,
                    showSwitch: false,
                  ),
                  const SizedBox(height: 16),
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

  Widget _buildNameRow() {
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

  Widget _buildUsernameEmailRow() {
    return Row(
      children: [
        Expanded(
          child: FormBuilderTextField(
            name: 'username',
            maxLength: 50,
            inputFormatters: usernameInputFormatters,
            decoration: const InputDecoration(
              labelText: 'Korisničko ime',
              border: OutlineInputBorder(),
            ),
            validator: validateUsername,
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

  Widget _buildPhoneBirthRow() {
    return Row(
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
        Expanded(
          child: FormBuilderDateTimePicker(
            name: 'birthDate',
            inputType: InputType.date,
            format: dateOnlyFormatter,
            decoration: const InputDecoration(
              labelText: 'Datum rođenja',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            initialDate: latestBirthDate,
            firstDate: earliestBirthDate,
            lastDate: latestBirthDate,
            validator: validateBirthDate,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker({
    required File? image,
    required String? error,
    required VoidCallback onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
        ),
        if (error != null) _buildErrorText(error),
      ],
    );
  }

  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        error,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  Widget? _buildRoleLoadState() {
    if (_roles.isNotEmpty) return null;
    if (_isLoadingRoles) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Učitavanje uloga...'),
        ],
      );
    }
    if (_roleLoadFailed) {
      return Row(
        children: [
          const Expanded(
            child: Text(
              'Uloge nije moguće učitati, pa spremanje nije moguće. '
              'Pokušajte ponovo.',
            ),
          ),
          TextButton(
            onPressed: _loadRoles,
            child: const Text('Pokušaj ponovo'),
          ),
        ],
      );
    }
    return null;
  }

  Widget _buildUserRoleField() {
    final loadState = _buildRoleLoadState();
    if (loadState != null) return loadState;

    final error = _roleErrors['user'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormBuilderDropdown<int>(
          name: 'roleId',
          initialValue: _roleByName(_userRoleName)?.id,
          decoration: const InputDecoration(
            labelText: 'Uloga',
            border: OutlineInputBorder(),
          ),
          validator: FormBuilderValidators.required(
            errorText: 'Odaberite ulogu',
          ),
          items: _userTabRoles
              .map(
                (role) => DropdownMenuItem(
                  value: role.id,
                  child: Text(role.name ?? ''),
                ),
              )
              .toList(),
        ),
        if (error != null) _buildErrorText(error),
      ],
    );
  }

  Widget _buildFixedRoleField(String roleName) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Uloga',
        border: OutlineInputBorder(),
        helperText: 'Uloga je određena vrstom naloga i ne može se mijenjati.',
      ),
      child: Text(roleName),
    );
  }

  Widget _buildOwnerRoleField() {
    final loadState = _buildRoleLoadState();
    if (loadState != null) return loadState;

    final error =
        _roleErrors['owner'] ??
        (_roleByName(_ownerRoleName) == null
            ? "Uloga 'Vlasnik' više nije dostupna, pa vlasnika nije moguće dodati."
            : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFixedRoleField('Vlasnik'),
        if (error != null) _buildErrorText(error),
      ],
    );
  }

  Widget _buildSaveButton(String label, VoidCallback? onPressed) {
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
