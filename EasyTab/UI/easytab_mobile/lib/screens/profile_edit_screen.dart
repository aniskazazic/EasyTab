import 'dart:convert';

import 'package:easytab_mobile/models/user.dart';
import 'package:easytab_mobile/providers/user_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
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
        type: FileType.image,
      );

      if (result != null) {
        var file = result.files.first;
        var bytes = await file.xFile.readAsBytes();
        final base64String = base64Encode(bytes);

        setState(() {
          base64ProfileImage = base64String;
        });
      }
    } catch (e) {
      alertBox(context, "Error", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: _buildSaveButton(context),
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
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () async {
        _formKey.currentState?.save();

        try {
          if (_formKey.currentState!.validate()) {
            Map<String, dynamic> request = Map.of(_formKey.currentState!.value);

            if (request['birthDate'] is DateTime) {
              request['birthDate'] = (request['birthDate'] as DateTime)
                  .toIso8601String();
            }

            if (base64ProfileImage != null) {
              request['profilePicture'] = base64ProfileImage;
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
          if (mounted) alertBox(context, "Greška", e.toString());
        }
      },
      child: const Text("Sačuvaj promjene", style: TextStyle(fontSize: 16)),
    );
  }

  FormBuilder _buildForm() {
    return FormBuilder(
      key: _formKey,
      initialValue: _initalValue,
      child: Column(
        children: [
          InkWell(
            onTap: _pickFile,
            child: CircleAvatar(
              backgroundImage: base64ProfileImage != null
                  ? imageFromBase64WithouthDimensions(base64ProfileImage!)
                  : const AssetImage('assets/images/no-image.png'),
              radius: 90,
            ),
          ),
          FormBuilderTextField(
            name: "firstName",
            decoration: const InputDecoration(labelText: "Ime"),
            validator: (value) {
              if (value == null || value.isEmpty) {
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
              if (value == null || value.isEmpty) {
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
              if (value == null || value.isEmpty) {
                return "Korisničko ime je obavezno";
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          FormBuilderTextField(
            name: "email",
            decoration: const InputDecoration(labelText: "Email"),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Email je obavezan";
              } else if (!RegExp(
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
              ).hasMatch(value)) {
                return "Invalid email";
              } else {
                return null;
              }
            },
          ),
          const SizedBox(height: 20),
          FormBuilderTextField(
            name: "phoneNumber",
            decoration: const InputDecoration(labelText: "Broj telefona"),
          ),
          const SizedBox(height: 20),
          FormBuilderDateTimePicker(
            name: 'birthDate',
            inputType: InputType.date,
            format: DateFormat('dd.MM.yyyy'),
            decoration: const InputDecoration(labelText: "Datum rođenja"),
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
          Text(
            "Uredi profil",
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
