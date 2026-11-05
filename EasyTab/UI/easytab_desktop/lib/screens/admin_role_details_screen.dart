import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/role.dart';
import 'package:easytab_desktop/providers/role_provider.dart';
import 'package:easytab_desktop/providers/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

class AdminRoleDetailsScreen extends StatefulWidget {
  final Role? role;
  const AdminRoleDetailsScreen({super.key, this.role});

  @override
  State<AdminRoleDetailsScreen> createState() => _AdminRoleDetailsScreenState();
}

class _AdminRoleDetailsScreenState extends State<AdminRoleDetailsScreen> {
  final formKey = GlobalKey<FormBuilderState>();
  late RoleProvider roleProvider;
  bool isLoading = false;
  bool get _isSystem =>
      widget.role != null && RoleProvider.isSystemRole(widget.role!);

  @override
  void initState() {
    super.initState();
    roleProvider = Provider.of<RoleProvider>(context, listen: false);
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
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (isLoading ||
        _isSystem ||
        !(formKey.currentState?.saveAndValidate() ?? false)) {
      return;
    }

    setState(() => isLoading = true);
    try {
      var request = Map<String, dynamic>.from(
        formKey.currentState?.value ?? {},
      );
      request['name'] = (request['name'] as String).trim();
      if (widget.role == null) {
        await roleProvider.insert(request);
        if (!mounted) return;
        _showSuccess('Uloga uspješno dodana!');
      } else {
        await roleProvider.update(widget.role!.id!, request);
        if (!mounted) return;
        _showSuccess('Uloga uspješno ažurirana!');
      }
    } catch (e) {
      if (!mounted) return;
      if (!showApiFieldErrors(formKey.currentState, e)) {
        _showError(userError(e));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: widget.role == null ? 'Nova uloga' : 'Uredi ulogu',
      showCloseButton: true,
      child: Column(
        children: [
          Expanded(
            child: FormBuilder(
              key: formKey,
              enabled: !isLoading && !_isSystem,
              initialValue: {
                "name": widget.role?.name ?? '',
                "description": widget.role?.description ?? '',
              },
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    FormBuilderTextField(
                      name: "name",
                      maxLength: 50,
                      decoration: const InputDecoration(
                        labelText: "Naziv uloge",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Naziv uloge je obavezan.'
                          : value.trim().length > 50
                          ? 'Naziv uloge može imati najviše 50 znakova.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: "description",
                      maxLines: 3,
                      maxLength: 100,
                      validator: (value) => value != null && value.length > 100
                          ? 'Opis uloge može imati najviše 100 znakova.'
                          : null,
                      decoration: const InputDecoration(
                        labelText: "Opis",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: Tooltip(
                message: _isSystem ? 'Sistemska uloga' : '',
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: isLoading || _isSystem ? null : _handleSave,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.role == null
                              ? 'Dodaj ulogu'
                              : 'Spremi izmjene',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
}
