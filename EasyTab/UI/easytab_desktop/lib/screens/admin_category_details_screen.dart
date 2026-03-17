import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/category.dart';
import 'package:easytab_desktop/providers/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

class AdminCategoryDetailsScreen extends StatefulWidget {
  final Category? category;
  const AdminCategoryDetailsScreen({super.key, this.category});

  @override
  State<AdminCategoryDetailsScreen> createState() =>
      _AdminCategoryDetailsScreenState();
}

class _AdminCategoryDetailsScreenState
    extends State<AdminCategoryDetailsScreen> {
  final formKey = GlobalKey<FormBuilderState>();
  late CategoryProvider categoryProvider;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
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
    formKey.currentState?.saveAndValidate();
    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() => isLoading = true);
    try {
      var request = Map<String, dynamic>.from(
        formKey.currentState?.value ?? {},
      );
      if (widget.category == null) {
        await categoryProvider.insert(request);
        _showSuccess('Kategorija uspješno dodana!');
      } else {
        await categoryProvider.update(widget.category!.id!, request);
        _showSuccess('Kategorija uspješno ažurirana!');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: widget.category == null ? 'Nova kategorija' : 'Uredi kategoriju',
      child: Column(
        children: [
          Expanded(
            child: FormBuilder(
              key: formKey,
              initialValue: {
                "name": widget.category?.name ?? '',
                "description": widget.category?.description ?? '',
              },
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    FormBuilderTextField(
                      name: "name",
                      decoration: const InputDecoration(
                        labelText: "Naziv kategorije",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Naziv je obavezan'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: "description",
                      maxLines: 3,
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
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: isLoading ? null : _handleSave,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.category == null
                            ? 'Dodaj kategoriju'
                            : 'Spremi izmjene',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
