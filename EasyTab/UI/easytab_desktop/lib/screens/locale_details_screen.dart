import 'dart:convert';
import 'dart:io';

import 'package:easytab_desktop/models/category.dart';
import 'package:easytab_desktop/models/city.dart';
import 'package:easytab_desktop/models/country.dart';
import 'package:easytab_desktop/models/search_result.dart';
import 'package:easytab_desktop/providers/category_provider.dart';
import 'package:easytab_desktop/providers/city_provider.dart';
import 'package:easytab_desktop/providers/country_provider.dart';
import 'package:easytab_desktop/providers/locale_provider.dart';
//import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/locale.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

class LocaleDetailsScreen extends StatefulWidget {
  Locale? locale;

  LocaleDetailsScreen({super.key, this.locale});

  @override
  State<LocaleDetailsScreen> createState() => _LocaleDetailsScreen();
}

class _LocaleDetailsScreen extends State<LocaleDetailsScreen> {
  final formKey = GlobalKey<FormBuilderState>();

  Map<String, dynamic> _initialValue = {};

  late LocaleProvider localeProvider;
  late CityProvider cityProvider;
  late CountryProvider countryProvider;
  late CategoryProvider categoryProvider;

  SearchResult<City>? city;
  SearchResult<Category>? category;
  SearchResult<Country>? country;

  bool isLoading = true;
  int? selectedCountryId;

  @override
  void initState() {
    localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    categoryProvider = context.read<CategoryProvider>();
    countryProvider = context.read<CountryProvider>();
    cityProvider = context.read<CityProvider>();
    super.initState();

    _initialValue = {
      "name": widget.locale?.name ?? '',
      "address": widget.locale?.address ?? '',
      "lengthOfReservation":
          widget.locale?.lengthOfReservation?.toString() ?? '',
      "phoneNumber": widget.locale?.phoneNumber ?? '',
      "cityId": widget.locale?.cityId,
      "categoryId": widget.locale?.categoryId,
    };

    initFormData();
  }

  dynamic initFormData() async {
    category = await categoryProvider.get();
    country = await countryProvider.get();
    city = await cityProvider.get();

    setState(() {
      isLoading = false;
    });
  }

  File? _image;
  String? _base64Image;

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: "Locale Details",
      child: Column(children: [_buildForm(), _buildSaveButton()]),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () async {
        formKey.currentState?.saveAndValidate();
        if (formKey.currentState?.validate() ?? false) {
          print(formKey.currentState?.value);
          var request = Map.from(formKey.currentState?.value ?? {});
          if (widget.locale == null) {
            widget.locale = await localeProvider.insert(request);
          } else {
            widget.locale = await localeProvider.update(
              widget.locale!.id!,
              request,
            );
          }
        }
      },
      child: Text("Save"),
    );
  }

  Widget _buildForm() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return FormBuilder(
      key: formKey,
      initialValue: _initialValue,
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            FormBuilderTextField(
              name: "name",
              decoration: InputDecoration(labelText: "Name: "),
            ),
            FormBuilderTextField(
              name: "address",
              decoration: InputDecoration(labelText: "Address: "),
            ),
            FormBuilderTextField(
              name: "lengthOfReservation",
              decoration: InputDecoration(labelText: "Length of reservation: "),
            ),
            FormBuilderTextField(
              name: "phoneNumber",
              decoration: InputDecoration(labelText: "Phone number: "),
            ),
            // Dropdown za drzave
            SizedBox(height: 20),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: FormBuilderDropdown(
                    name: "cityId",
                    decoration: InputDecoration(labelText: "City: "),
                    items:
                        city?.items
                            ?.map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name ?? ""),
                              ),
                            )
                            .toList() ??
                        [],
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: FormBuilderDropdown(
                    name: "categoryId",
                    decoration: InputDecoration(labelText: "Category: "),
                    items: (category?.items ?? [])
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name ?? ""),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
            /*Row(
              children: [
                Expanded(
                  child: FormBuilderField(
                    name: "logo",
                    builder: (FormFieldState<dynamic> field) {
                      return TextButton(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform
                              .pickFiles();
                          if (result != null) {
                            _image = File(result.files.single.path!);
                            _base64Image = base64Encode(
                              _image!.readAsBytesSync(),
                            );
                          }
                        },
                        child: Text("Upload logo:"),
                      );
                    },
                  ),
                ),
              ],
            ),*/
          ],
        ),
      ),
    );
  }
}
