import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:easytab_mobile/providers/user_provider.dart';
import 'package:easytab_mobile/models/user.dart';
import 'package:easytab_mobile/models/search_result.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late UserProvider userProvider;
  final _formKey = GlobalKey<FormBuilderState>();

  String? confirmPasswordError;
  String? dateError;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    userProvider = context.read<UserProvider>();
  }

  Future<void> _handleRegister() async {
    var isValid = _formKey.currentState!.saveAndValidate();

    if (!isValid || confirmPasswordError != null || dateError != null) return;

    setState(() => _isLoading = true);

    try {
      var req = Map.from(_formKey.currentState!.value);

      DateTime dob = req['birthDate'];
      req['birthDate'] = dob.toIso8601String().split('T')[0];

      await userProvider.insert({
        'firstName': req['firstName'],
        'lastName': req['lastName'],
        'username': req['username'],
        'email': req['email'],
        'password': req['password'],
        'passwordConfirmation': req['confirmPassword'],
        'phoneNumber': req['phone'],
        'birthDate': req['birthDate'],
      });

      if (mounted) _showSuccess();
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Uspješno'),
        content: const Text('Registracija uspješna! Možete se prijaviti.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Prijava', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF1E40AF),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(children: [_buildHeader(), _buildForm()]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1E40AF),
      padding: const EdgeInsets.only(top: 60, bottom: 36, left: 32, right: 32),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person_add, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 12),
          const Text(
            'Kreirajte račun',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pridružite se EasyTab zajednici',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              _sectionTitle('Osnovni podaci'),

              Row(
                children: [
                  Expanded(
                    child: _inputField('Ime', 'firstName', icon: Icons.person),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _inputField(
                      'Prezime',
                      'lastName',
                      icon: Icons.person,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _inputField(
                'Korisničko ime',
                'username',
                icon: Icons.alternate_email,
              ),
              const SizedBox(height: 20),
              // Datum rođenja
              FormBuilderDateTimePicker(
                name: 'birthDate',
                inputType: InputType.date,
                decoration: _decoration('Datum rođenja', Icons.calendar_today),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(errorText: 'Obavezno polje'),
                  (value) {
                    if (value == null) return null;

                    int age = DateTime.now().year - value.year;

                    if (age < 18 || value.isAfter(DateTime.now())) {
                      return 'Morate imati 18+ godina';
                    }
                    return null;
                  },
                ]),
              ),

              const SizedBox(height: 20),
              _sectionTitle('Kontakt'),

              _inputField('Email', 'email', icon: Icons.email),
              const SizedBox(height: 14),

              _inputField('Telefon', 'phone', icon: Icons.phone),

              const SizedBox(height: 20),
              _sectionTitle('Sigurnost'),

              _inputField(
                'Lozinka',
                'password',
                icon: Icons.lock,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Obavezno polje';
                  }
                },
              ),

              const SizedBox(height: 14),

              _inputField(
                'Potvrda lozinke',
                'confirmPassword',
                icon: Icons.lock,
                obscure: _obscureConfirm,
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Obavezno polje';
                  }

                  final password =
                      _formKey.currentState?.fields['password']?.value;

                  if (val != password) {
                    return 'Lozinke se ne poklapaju';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Registruj se',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Već imaš račun? Prijavi se'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String hint,
    String name, {
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    Function(String?)? onChanged,
    String? errorText,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return FormBuilderTextField(
      name: name,
      obscureText: obscure,
      keyboardType: keyboard,
      onChanged: onChanged,
      validator:
          validator ??
          FormBuilderValidators.required(errorText: 'Obavezno polje'),
      decoration: _decoration(hint, icon, suffix, errorText),
    );
  }

  InputDecoration _decoration(
    String hint,
    IconData icon, [
    Widget? suffix,
    String? errorText,
  ]) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E40AF)),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}
