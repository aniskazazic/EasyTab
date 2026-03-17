import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/user.dart';
import 'package:easytab_desktop/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
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
  Map<String, dynamic> _initialValue = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);

    _initialValue = {
      "firstName": widget.user?.firstName ?? '',
      "lastName": widget.user?.lastName ?? '',
      "username": widget.user?.username ?? '',
      "email": widget.user?.email ?? '',
      "phoneNumber": widget.user?.phoneNumber ?? '',
      "password": '',
      "passwordConfirmation": '',
    };
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
              Navigator.pop(context); // zatvori dialog
              Navigator.pop(context); // vrati se na listu
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: widget.user == null ? 'Novi korisnik' : 'Uredi korisnika',
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
                  widget.user == null ? 'Dodaj korisnika' : 'Spremi izmjene',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    formKey.currentState?.saveAndValidate();
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() => isLoading = true);

    try {
      var request = Map<String, dynamic>.from(
        formKey.currentState?.value ?? {},
      );

      // Ukloni prazna polja
      request.removeWhere(
        (key, value) => value == null || value.toString().isEmpty,
      );

      if (widget.user == null) {
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

  Widget _buildForm() {
    return FormBuilder(
      key: formKey,
      initialValue: _initialValue,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
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
                    validator: (value) => value == null || value.isEmpty
                        ? 'Ime je obavezno'
                        : null,
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
                    validator: (value) => value == null || value.isEmpty
                        ? 'Prezime je obavezno'
                        : null,
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
                    validator: (value) => value == null || value.isEmpty
                        ? 'Korisničko ime je obavezno'
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
                      if (value == null || value.isEmpty)
                        return 'Email je obavezan';
                      if (!value.contains('@')) return 'Unesite validan email';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: "phoneNumber",
              decoration: const InputDecoration(
                labelText: "Broj telefona",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Password polja samo ako je novi korisnik ili ako admin želi promijeniti
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: "password",
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: widget.user == null
                          ? "Lozinka"
                          : "Nova lozinka (ostavite prazno ako ne mijenjate)",
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (widget.user == null &&
                          (value == null || value.isEmpty)) {
                        return 'Lozinka je obavezna';
                      }
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
                      labelText: widget.user == null
                          ? "Potvrda lozinke"
                          : "Potvrda nove lozinke",
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (widget.user == null &&
                          (value == null || value.isEmpty)) {
                        return 'Potvrda lozinke je obavezna';
                      }
                      final password =
                          formKey.currentState?.fields['password']?.value
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
    );
  }
}
