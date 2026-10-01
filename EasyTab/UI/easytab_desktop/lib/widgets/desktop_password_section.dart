import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class DesktopPasswordSection extends StatefulWidget {
  final GlobalKey<FormBuilderState> formKey;
  final bool isSelf;
  final bool isRequired;
  final bool showSwitch;
  final ValueChanged<bool>? onChanged;

  const DesktopPasswordSection({
    super.key,
    required this.formKey,
    this.isSelf = false,
    this.isRequired = false,
    this.showSwitch = true,
    this.onChanged,
  });

  @override
  State<DesktopPasswordSection> createState() => _DesktopPasswordSectionState();
}

class _DesktopPasswordSectionState extends State<DesktopPasswordSection> {
  bool _enabled = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _obscureCurrent = true;

  @override
  void initState() {
    super.initState();
    _enabled = !widget.showSwitch;
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Potvrda lozinke je obavezna';
    }

    final password =
        widget.formKey.currentState?.fields['password']?.value as String?;
    return password == value ? null : 'Lozinke se ne podudaraju';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showSwitch)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Promijeni lozinku'),
            value: _enabled,
            onChanged: (value) {
              setState(() => _enabled = value);
              widget.onChanged?.call(value);
            },
          ),
        if (_enabled) ...[
          Row(
            children: [
              if (widget.isSelf) ...[
                Expanded(
                  child: FormBuilderTextField(
                    name: 'currentPassword',
                    obscureText: _obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Trenutna lozinka',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Unesite trenutnu lozinku'
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: FormBuilderTextField(
                  name: 'password',
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: widget.isRequired ? 'Lozinka' : 'Nova lozinka',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Lozinka je obavezna'
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FormBuilderTextField(
                  name: 'passwordConfirmation',
                  obscureText: _obscureConfirmation,
                  decoration: InputDecoration(
                    labelText: widget.isRequired
                        ? 'Potvrda lozinke'
                        : 'Potvrda nove lozinke',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmation
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setState(
                        () => _obscureConfirmation = !_obscureConfirmation,
                      ),
                    ),
                  ),
                  validator: _validateConfirmation,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
