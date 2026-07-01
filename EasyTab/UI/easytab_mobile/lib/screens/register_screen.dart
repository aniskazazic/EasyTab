import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Greška'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF1E40AF))),
          ),
        ],
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF1E40AF),
              size: 24,
            ),
            SizedBox(width: 8),
            Text('Uspješno'),
          ],
        ),
        content: const Text('Registracija uspješna! Možete se prijaviti.'),
        actions: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
              ),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text(
                'Prijava',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(children: [_buildHeader(size), _buildFormCard()]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return Container(
      height: size.height * 0.32,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: size.width * 0.15,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Container(
      height: size.height * 0.25,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kreirajte račun',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pridružite se EasyTab zajednici',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 32, bottom: 32, left: 24, right: 24),
      child: FormBuilder(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Osnovni podaci
            _sectionTitle('Osnovni podaci', Icons.person_rounded),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _inputField(
                    'Ime',
                    'firstName',
                    icon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _inputField(
                    'Prezime',
                    'lastName',
                    icon: Icons.badge_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _inputField(
              'Korisničko ime',
              'username',
              icon: Icons.alternate_email_rounded,
            ),
            const SizedBox(height: 14),

            FormBuilderDateTimePicker(
              name: 'birthDate',
              inputType: InputType.date,
              decoration: _decoration(
                'Datum rođenja',
                Icons.calendar_today_rounded,
              ),
              format: DateFormat('dd/MM/yyyy'),
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

            const SizedBox(height: 24),
            _sectionDivider(),
            const SizedBox(height: 20),

            // Section: Kontakt
            _sectionTitle('Kontakt', Icons.contact_mail_rounded),
            const SizedBox(height: 12),

            _inputField('Email adresa', 'email', icon: Icons.email_outlined),
            const SizedBox(height: 14),

            _inputField('Broj telefona', 'phone', icon: Icons.phone_outlined),

            const SizedBox(height: 24),
            _sectionDivider(),
            const SizedBox(height: 20),

            // Section: Sigurnost
            _sectionTitle('Sigurnost', Icons.shield_outlined),
            const SizedBox(height: 12),

            _inputField(
              'Lozinka',
              'password',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey[500],
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Obavezno polje';
                return null;
              },
            ),
            const SizedBox(height: 14),

            _inputField(
              'Potvrda lozinke',
              'confirmPassword',
              icon: Icons.lock_person_outlined,
              obscure: _obscureConfirm,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey[500],
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Obavezno polje';
                final password =
                    _formKey.currentState?.fields['password']?.value;
                if (val != password) return 'Lozinke se ne poklapaju';
                return null;
              },
            ),

            const SizedBox(height: 28),

            // Register button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E40AF).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                          'Registruj se',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Login link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Već imate račun? ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Prijavi se',
                    style: TextStyle(
                      color: Color(0xFF1E40AF),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E40AF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1E40AF), size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _sectionDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        const SizedBox(width: 8),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF1E40AF),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
      ],
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
      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
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
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      errorText: errorText,
      prefixIcon: Icon(icon, color: const Color(0xFF1E40AF), size: 18),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
    );
  }
}
