import 'dart:convert';

import 'package:easytab_mobile/exceptions/api_exception.dart';
import 'package:easytab_mobile/models/user.dart';
import 'package:easytab_mobile/providers/user_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:easytab_mobile/widgets/form_feedback.dart';
import 'package:easytab_mobile/screens/change_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:easytab_mobile/providers/utils.dart';

class ProfileEditScreen extends StatefulWidget {
  final User user;

  const ProfileEditScreen({super.key, required this.user});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  Map<String, dynamic> _initalValue = {};

  late UserProvider _userProvider;

  String? base64ProfileImage;
  String? _profilePictureError;
  bool _removeProfileImage = false;
  bool _isSaving = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();

    base64ProfileImage = widget.user.profilePicture;

    _initalValue = {
      'firstName': widget.user.firstName,
      'lastName': widget.user.lastName,
      'email': widget.user.email,
      'username': widget.user.username,
      'phoneNumber': widget.user.phoneNumber,
      'birthDate': widget.user.birthDate,
    };

    _userProvider = context.read<UserProvider>();
  }

  Future _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        var file = result.files.first;
        var bytes = await file.xFile.readAsBytes();
        if (!mounted) return;
        final isJpeg =
            bytes.length >= 3 &&
            bytes[0] == 0xff &&
            bytes[1] == 0xd8 &&
            bytes[2] == 0xff;
        final isPng =
            bytes.length >= 8 &&
            bytes.take(8).join(',') == '137,80,78,71,13,10,26,10';
        if (bytes.length > 300 * 1024 || (!isJpeg && !isPng)) {
          setState(
            () => _profilePictureError =
                ApiClientException.imageValidationMessage,
          );
          return;
        }
        final base64String = base64Encode(bytes);

        setState(() {
          base64ProfileImage = base64String;
          _removeProfileImage = false;
          _profilePictureError = null;
        });
      }
    } catch (e) {
      if (mounted) showFeedback(context, userError(e), error: true);
    }
  }

  Future<void> _confirmRemoveProfileImage() async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: dialogTitle(dialogContext, 'Brisanje slike'),
        content: const Text('Da li ste sigurni da želite obrisati sliku?'),
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

    if (shouldRemove == true && mounted) {
      setState(() {
        base64ProfileImage = null;
        _removeProfileImage = true;
        _profilePictureError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user.id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Uredi profil')),
        body: const Center(
          child: Text('Profil nije učitan. Vratite se i pokušajte ponovo.'),
        ),
      );
    }
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildForm(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSaveButton(),
          ),
        ],
      ),
    );
  }

  ElevatedButton _buildSaveButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: _isSaving
          ? null
          : () async {
              _formKey.currentState?.save();

              try {
                if (_formKey.currentState!.validate()) {
                  if (_profilePictureError != null) return;
                  setState(() => _isSaving = true);
                  Map<String, dynamic> request = Map.of(
                    _formKey.currentState!.value,
                  );
                  for (final field in [
                    'firstName',
                    'lastName',
                    'email',
                    'username',
                    'phoneNumber',
                  ]) {
                    if (request[field] is String) {
                      request[field] = (request[field] as String).trim();
                    }
                  }

                  if (request['birthDate'] is DateTime) {
                    request['birthDate'] = (request['birthDate'] as DateTime)
                        .toIso8601String();
                  }

                  if (base64ProfileImage != null) {
                    request['profilePicture'] = base64ProfileImage;
                  } else if (_removeProfileImage) {
                    request['profilePicture'] = '';
                  }

                  await _userProvider.update(widget.user.id!, request);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Profil uspješno ažuriran"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context, 'reload');
                  }
                }
              } on Exception catch (e) {
                final imageError = e is ApiClientException
                    ? e.imageValidationErrors['profilePicture']
                    : null;
                if (mounted && imageError != null) {
                  setState(() => _profilePictureError = imageError);
                } else if (mounted &&
                    !FormValidation.showApiErrors(_formKey.currentState, e)) {
                  showFeedback(context, userError(e), error: true);
                }
              } finally {
                if (mounted) setState(() => _isSaving = false);
              }
            },
      child: Text(
        _isSaving ? 'Čuvanje promjena…' : 'Sačuvaj promjene',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  FormBuilder _buildForm() {
    return FormBuilder(
      key: _formKey,
      enabled: !_isSaving,
      initialValue: _initalValue,
      child: Column(
        children: [
          InkWell(
            onTap: _isSaving ? null : _pickFile,
            child: CircleAvatar(
              backgroundImage:
                  ImageUtils.imageProvider(base64ProfileImage) ??
                  const AssetImage('assets/images/no-image.png'),
              radius: 90,
            ),
          ),
          if (base64ProfileImage != null)
            TextButton.icon(
              onPressed: _isSaving ? null : _confirmRemoveProfileImage,
              icon: const Icon(Icons.delete),
              label: const Text('Obriši sliku'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          if (_profilePictureError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _profilePictureError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          SwitchListTile(
            title: const Text('Promijeni lozinku'),
            subtitle: const Text(
              'Otvara posebnu formu uz potvrdu stare lozinke. Profil sačuvajte zasebno.',
            ),
            value: _isChangingPassword,
            onChanged: _isSaving
                ? null
                : (_) async {
                    setState(() => _isChangingPassword = true);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangePasswordScreen(user: widget.user),
                      ),
                    );
                    if (mounted) setState(() => _isChangingPassword = false);
                  },
          ),
          FormBuilderTextField(
            name: "firstName",
            decoration: const InputDecoration(labelText: "Ime"),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Ime je obavezno";
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          FormBuilderTextField(
            name: "lastName",
            decoration: const InputDecoration(labelText: "Prezime"),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Prezime je obavezno";
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          FormBuilderTextField(
            name: "username",
            decoration: const InputDecoration(labelText: "Korisničko ime"),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Korisničko ime je obavezno";
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          FormBuilderTextField(
            name: "email",
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: "Email",
              errorMaxLines: 4,
            ),
            validator: FormValidation.email,
          ),
          const SizedBox(height: 20),
          FormBuilderTextField(
            name: "phoneNumber",
            decoration: const InputDecoration(
              labelText: 'Broj telefona (opcionalno)',
              errorMaxLines: 4,
            ),
            keyboardType: TextInputType.phone,
            validator: FormValidation.phone,
          ),
          const SizedBox(height: 20),
          FormBuilderDateTimePicker(
            name: 'birthDate',
            inputType: InputType.date,
            format: dateOnlyFormatter,
            decoration: const InputDecoration(labelText: "Datum rođenja"),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            validator: FormValidation.adult,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1E40AF),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        20,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Uredi profil",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
