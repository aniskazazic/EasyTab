import 'package:easytab_desktop/layouts/master_screen.dart';
import 'package:easytab_desktop/models/locale.dart';
import 'package:easytab_desktop/models/search_result.dart';
import 'package:easytab_desktop/providers/locale_provider.dart';
import 'package:easytab_desktop/screens/locale_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LocaleListScreen extends StatefulWidget {
  const LocaleListScreen({super.key});

  @override
  State<LocaleListScreen> createState() => _LocaleListScreenState();
}

class _LocaleListScreenState extends State<LocaleListScreen> {
  late LocaleProvider localeProvider;

  TextEditingController nameController = TextEditingController();

  SearchResult<Locale>? locales;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localeProvider = context.read<LocaleProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Locale List',
      child: Center(
        child: Column(children: [_buildSearch(), _builtResultView()]),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Name of locale',
                border: const OutlineInputBorder(),
              ),
              controller: nameController,
            ),
          ),
          SizedBox(width: 15),
          ElevatedButton(
            onPressed: () async {
              var filter = {"Name": nameController.text};
              var locale = await localeProvider.getLocale(filter);
              debugPrint(
                locale?.items?.firstOrNull?.endOfWorkingHours != null
                    ? TimeOfDay.fromDateTime(
                        locale!.items!.first.startOfWorkingHours!,
                      ).format(context)
                    : '',
              );
              locales = locale;
              setState(() {});
            },
            child: Text('Search'),
          ),
        ],
      ),
    );
  }

  Widget _builtResultView() {
    return Expanded(
      child: Container(
        width: double.infinity,
        child: SingleChildScrollView(
          child: DataTable(
            columns: [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Address')),
              DataColumn(label: Text('City Name')),
              DataColumn(label: Text('Category Name')),
              DataColumn(label: Text('Start of Working Hours')),
              DataColumn(label: Text('End of Working Hours')),
              DataColumn(label: Text('Length of Reservation')),
              DataColumn(label: Text('Logo')),
              DataColumn(label: Text('Phone Number')),
            ],
            rows:
                locales?.items
                    ?.map(
                      (e) => DataRow(
                        onSelectChanged: (value) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  LocaleDetailsScreen(locale: e),
                            ),
                          );
                        },
                        cells: [
                          DataCell(Text(e.name ?? '')),
                          DataCell(Text(e.address ?? '')),
                          DataCell(Text(e.cityName ?? '')),
                          DataCell(Text(e.categoryName ?? '')),
                          DataCell(
                            Text(
                              e.startOfWorkingHours != null
                                  ? TimeOfDay.fromDateTime(
                                      e.startOfWorkingHours!,
                                    ).format(context)
                                  : '',
                            ),
                          ),
                          DataCell(
                            Text(
                              e.endOfWorkingHours != null
                                  ? TimeOfDay.fromDateTime(
                                      e.endOfWorkingHours!,
                                    ).format(context)
                                  : '',
                            ),
                          ),
                          DataCell(
                            Text(e.lengthOfReservation?.toString() ?? ''),
                          ),
                          DataCell(Text(e.logo ?? '')),
                          DataCell(Text(e.phoneNumber ?? '')),
                        ],
                      ),
                    )
                    .toList() ??
                [],
          ),
        ),
      ),
    );
  }
}

/* za vrijeme lokala
debugPrint(
  products?.items?.firstOrNull?.endOfWorkingHours != null
      ? TimeOfDay.fromDateTime(
          products!.items!.first.startOfWorkingHours!,
        ).format(context)
      : '',
);
*/
