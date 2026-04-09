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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: FormBuilder(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Ime + Prezime
            Row(
              children: [
                Expanded(
                  child: _inputField(
                    'Ime',
                    'firstName',
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _inputField(
                    'Prezime',
                    'lastName',
                    icon: Icons.person_outline,
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
            const SizedBox(height: 14),

            _inputField(
              'Email',
              'email',
              icon: Icons.email_outlined,
              keyboard: TextInputType.emailAddress,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(errorText: 'Email je obavezan'),
                FormBuilderValidators.email(errorText: 'Email nije validan'),
              ]),
            ),
            const SizedBox(height: 14),

            _inputField(
              'Telefon',
              'phone',
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 14),

            // Datum rođenja
            FormBuilderDateTimePicker(
              name: 'birthDate',
              inputType: InputType.date,
              decoration: _decoration('Datum rođenja', Icons.calendar_today),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              onChanged: (value) {
                if (value != null) {
                  int age = DateTime.now().year - value.year;
                  setState(() {
                    dateError = (age < 18 || value.isAfter(DateTime.now()))
                        ? 'Morate imati 18+ godina'
                        : null;
                  });
                }
              },
            ),
            if (dateError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    dateError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),
            const SizedBox(height: 14),

            // Lozinka
            _inputField(
              'Lozinka',
              'password',
              icon: Icons.lock_outline,
              obscure: _obscurePassword,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 14),

            // Potvrda lozinke
            _inputField(
              'Potvrda lozinke',
              'confirmPassword',
              icon: Icons.lock_outline,
              obscure: _obscureConfirm,
              errorText: confirmPasswordError,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              onChanged: (val) {
                final password =
                    _formKey.currentState?.fields['password']?.value;
                setState(() {
                  confirmPasswordError = val != password
                      ? 'Lozinke se ne poklapaju'
                      : null;
                });
              },
            ),
            const SizedBox(height: 24),

            // Dugme registracija
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Registrujte se',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Nazad na login
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text.rich(
                  TextSpan(
                    text: 'Već imate račun? ',
                    style: TextStyle(color: Colors.black54),
                    children: [
                      TextSpan(
                        text: 'Prijavite se',
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
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
