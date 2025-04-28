import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

Future<List<dynamic>> importExcel() async {
  List<Map<String, String>> students = [];

  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xls', 'xlsx', 'csv'],
    withData: true,
  );

  if (result == null) {
    print('No file selected');
    return students;
  }

  PlatformFile file = result.files.first;

  if (file.bytes == null) {
    print('No bytes found');
    return students;
  }

  var excel = Excel.decodeBytes(file.bytes!);

  for (var table in excel.tables.keys) {
    for (var row in excel.tables[table]!.rows) {
      if (row.length >= 2) {
        students.add({
          'fname': row[0]?.value.toString() ?? '',
          'name': row[1]?.value.toString() ?? '',
        });
      }
    }
  }

  return students;
}
