import 'package:easytab_mobile/models/user.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/user_provider.dart';
import 'package:easytab_mobile/widgets/form_feedback.dart';
import 'package:easytab_mobile/exceptions/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  final User? user;
  const ChangePasswordScreen({super.key, required this.user});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSaving = false;
  final Map<String, bool> _hiddenPasswords = {
    'password': true,
    'newPassword': true,
    'confirmNewPassword': true,
  };
  late UserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
  }

  @override
  Widget build(BuildContext context) {
    if (AuthProvider.currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Promjena lozinke')),
        body: const Center(
          child: Text('Prijavite se ponovo za promjenu lozinke.'),
        ),
      );
    }
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
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
                  child: FormBuilder(
                    key: _formKey,
                    enabled: !_isSaving,
                    child: Column(
                      children: [
                        FormBuilderTextField(
                          name: "password",
                          obscureText: _hiddenPasswords['password']!,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: "Stara lozinka",
                            errorMaxLines: 3,
                            suffixIcon: _passwordVisibilityButton('password'),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ovo polje je obavezno';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        FormBuilderTextField(
                          name: "newPassword",
                          obscureText: _hiddenPasswords['newPassword']!,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: "Nova lozinka",
                            errorMaxLines: 3,
                            suffixIcon: _passwordVisibilityButton(
                              'newPassword',
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Ovo polje je obavezno";
                            }
                            if (value.length < 6) {
                              return "Lozinka mora imati najmanje 6 karaktera.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        FormBuilderTextField(
                          name: "confirmNewPassword",
                          obscureText: _hiddenPasswords['confirmNewPassword']!,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: "Potvrdi novu lozinku",
                            errorMaxLines: 3,
                            suffixIcon: _passwordVisibilityButton(
                              'confirmNewPassword',
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Ovo polje je obavezno";
                            } else if (value !=
                                _formKey
                                    .currentState!
                                    .fields['newPassword']
                                    ?.value) {
                              return "Nova lozinka i potvrda lozinke se ne podudaraju";
                            } else {
                              return null;
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordVisibilityButton(String field) => IconButton(
    tooltip: _hiddenPasswords[field]! ? 'Prikaži lozinku' : 'Sakrij lozinku',
    onPressed: _isSaving
        ? null
        : () => setState(() {
            _hiddenPasswords[field] = !_hiddenPasswords[field]!;
          }),
    icon: Icon(
      _hiddenPasswords[field]!
          ? Icons.visibility_outlined
          : Icons.visibility_off_outlined,
    ),
  );

  ElevatedButton _buildSaveButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: _isSaving
          ? null
          : () async {
              _formKey.currentState?.save();

              try {
                if (_formKey.currentState!.validate()) {
                  setState(() => _isSaving = true);
                  await _userProvider.changePassword({
                    'id': AuthProvider.accessTokenDecoded?['Id'],
                    'password': _formKey.currentState?.value['password'],
                    'newPassword': _formKey.currentState?.value['newPassword'],
                    'confirmNewPassword':
                        _formKey.currentState?.value['confirmNewPassword'],
                  });
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Lozinka uspješno ažurirana"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context, 'reload');
                }
              } on Exception catch (e) {
                if (mounted &&
                    e is ApiClientException &&
                    e.message == 'Pogrešni kredencijali !') {
                  _formKey.currentState?.fields['password']?.invalidate(
                    'Stara lozinka nije ispravna.',
                  );
                } else if (mounted &&
                    !FormValidation.showApiErrors(_formKey.currentState, e)) {
                  showFeedback(context, userError(e), error: true);
                }
              } finally {
                if (mounted) setState(() => _isSaving = false);
              }
            },
      child: Text(
        _isSaving ? 'Čuvanje lozinke…' : 'Sačuvaj promjene',
        style: const TextStyle(fontSize: 16),
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
              "Promjena lozinke",
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
