import 'package:easytab_mobile/models/user.dart';
import 'package:easytab_mobile/providers/auth_provider.dart';
import 'package:easytab_mobile/providers/user_provider.dart';
import 'package:easytab_mobile/providers/utils.dart';
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
  Map<String, dynamic> _initalValue = {};
  late UserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
  }

  @override
  Widget build(BuildContext context) {
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
                    initialValue: _initalValue,
                    child: Column(
                      children: [
                        FormBuilderTextField(
                          name: "password",
                          decoration: const InputDecoration(
                            labelText: "Lozinka",
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
                          decoration: const InputDecoration(
                            labelText: "Nova lozinka",
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Ovo polje je obavezno";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        FormBuilderTextField(
                          name: "confirmNewPassword",
                          decoration: const InputDecoration(
                            labelText: "Potvrdi novu lozinku",
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Ovo polje je obavezno";
                            } else if (value !=
                                _formKey.currentState!.value['newPassword']) {
                              return "Nova lozinka i potvrda lozinke se ne podudaraju";
                            } else {
                              return null;
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildSaveButton(context),
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

  ElevatedButton _buildSaveButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () async {
        _formKey.currentState?.save();

        try {
          if (_formKey.currentState!.validate()) {
            await _userProvider.changePassword({
              'id': AuthProvider.accessTokenDecoded?['Id'],
              'password': _formKey.currentState?.value['password'],
              'newPassword': _formKey.currentState?.value['newPassword'],
              'confirmNewPassword':
                  _formKey.currentState?.value['confirmNewPassword'],
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Lozinka uspješno ažurirana"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, 'reload');
          }
        } on Exception catch (e) {
          if (mounted) alertBox(context, "Greška", e.toString());
        }
      },
      child: const Text("Sačuvaj promjene", style: TextStyle(fontSize: 16)),
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
          Text(
            "Promjena lozinke",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
