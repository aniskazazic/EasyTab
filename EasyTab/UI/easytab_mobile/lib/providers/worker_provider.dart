import 'package:easytab_mobile/models/worker.dart';
import 'package:easytab_mobile/providers/base_provider.dart';

class WorkerProvider extends BaseProvider<Worker> {
  WorkerProvider() : super("Workers");

  @override
  Worker fromJson(json) => Worker.fromJson(json);

  Future<List<Worker>> getByLocale(int localeId) async {
    var result = await get(filter: {"LocaleId": localeId, "RetrieveAll": true});
    return result.items ?? [];
  }
}
