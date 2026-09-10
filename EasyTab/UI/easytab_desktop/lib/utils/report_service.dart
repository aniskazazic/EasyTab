import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportService {
  static final _dateTimeFormat = DateFormat('dd.MM.yyyy. HH:mm');
  static final _fileStampFormat = DateFormat('yyyy-MM-dd_HHmm');

  static const _blue = PdfColor.fromInt(0xFF1E40AF);
  static const _lightBlue = PdfColor.fromInt(0xFFEFF6FF);
  static const _border = PdfColor.fromInt(0xFFDBEAFE);
  static const _text = PdfColor.fromInt(0xFF172033);
  static const _mutedText = PdfColor.fromInt(0xFF64748B);
  static const _white = PdfColors.white;

  static Future<Directory> downloadsDirectory() async {
    final home = Platform.isWindows
        ? Platform.environment['USERPROFILE']
        : Platform.environment['HOME'];

    if (home == null || home.isEmpty) {
      throw Exception('Nije moguće pronaći Downloads folder.');
    }

    final downloads = Directory('$home${Platform.pathSeparator}Downloads');
    if (!await downloads.exists()) {
      await downloads.create(recursive: true);
    }
    return downloads;
  }

  static Future<String> saveAdminReport({
    required int users,
    required int locales,
    required int reviews,
    required int countries,
    required int cities,
    required int categories,
  }) async {
    final generatedAt = DateTime.now();
    final document = _newDocument();

    document.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(),
        header: (context) => _header(
          title: 'Administratorski izvjestaj',
          subtitle: 'Pregled statistike sistema',
          generatedAt: generatedAt,
        ),
        footer: _footer,
        build: (context) => [
          pw.SizedBox(height: 22),
          _sectionTitle('Sazetak sistema'),
          pw.SizedBox(height: 14),
          pw.Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statCard('Korisnici', users.toString()),
              _statCard('Lokali', locales.toString()),
              _statCard('Recenzije', reviews.toString()),
              _statCard('Drzave', countries.toString()),
              _statCard('Gradovi', cities.toString()),
              _statCard('Kategorije', categories.toString()),
            ],
          ),
          pw.SizedBox(height: 28),
          _sectionTitle('Detaljan pregled'),
          pw.SizedBox(height: 12),
          _dataTable(
            headers: const ['Stavka', 'Ukupan broj'],
            rows: [
              ['Korisnici', '$users'],
              ['Lokali', '$locales'],
              ['Recenzije', '$reviews'],
              ['Drzave', '$countries'],
              ['Gradovi', '$cities'],
              ['Kategorije', '$categories'],
            ],
          ),
        ],
      ),
    );

    return _writePdf(
      'EasyTab_Global_Izvjestaj_${_fileStampFormat.format(generatedAt)}.pdf',
      document,
    );
  }

  static Future<String> saveOwnerReport({
    required String localeName,
    required int todayReservations,
    required int activeTables,
    required int totalTables,
    required int todayGuests,
    required List<Map<String, dynamic>> tableDistribution,
  }) async {
    final generatedAt = DateTime.now();
    final locale = localeName.trim().isEmpty
        ? 'Nije odabran lokal'
        : localeName;
    final occupancy = totalTables > 0
        ? ((activeTables / totalTables) * 100).toStringAsFixed(0)
        : '0';
    final document = _newDocument();

    document.addPage(
      pw.MultiPage(
        pageTheme: _pageTheme(),
        header: (context) => _header(
          title: 'Izvjestaj vlasnika',
          subtitle: locale,
          generatedAt: generatedAt,
        ),
        footer: _footer,
        build: (context) => [
          pw.SizedBox(height: 22),
          _sectionTitle('Danasnji pregled'),
          pw.SizedBox(height: 14),
          pw.Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statCard('Rezervacije', '$todayReservations'),
              _statCard('Aktivni stolovi', '$activeTables / $totalTables'),
              _statCard('Popunjenost', '$occupancy %'),
              _statCard('Ocekivani gosti', '$todayGuests'),
            ],
          ),
          pw.SizedBox(height: 28),
          _sectionTitle('Raspodjela stolova po velicini'),
          pw.SizedBox(height: 12),
          if (tableDistribution.isEmpty)
            _emptyState(
              totalTables == 0
                  ? 'Nema stolova za ovaj lokal.'
                  : 'Nema podataka o raspodjeli stolova.',
            )
          else
            _dataTable(
              headers: const ['Velicina stola', 'Broj stolova', 'Udio'],
              rows: tableDistribution.map((item) {
                final percentage = item['percentage'];
                final percentageText = percentage is num
                    ? '${percentage.toStringAsFixed(0)} %'
                    : '${percentage ?? 0} %';
                return [
                  '${item['seats'] ?? '-'} mjesta',
                  '${item['count'] ?? 0}',
                  percentageText,
                ];
              }).toList(),
            ),
        ],
      ),
    );

    return _writePdf(
      'EasyTab_Izvjestaj_${_sanitizeFileName(locale)}_${_fileStampFormat.format(generatedAt)}.pdf',
      document,
    );
  }

  static pw.Document _newDocument() => pw.Document(
    title: 'EasyTab izvjestaj',
    author: 'EasyTab',
    creator: 'EasyTab desktop aplikacija',
  );

  static pw.PageTheme _pageTheme() => pw.PageTheme(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 42),
    theme: pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    ),
  );

  static pw.Widget _header({
    required String title,
    required String subtitle,
    required DateTime generatedAt,
  }) => pw.Container(
    padding: const pw.EdgeInsets.all(20),
    decoration: pw.BoxDecoration(
      color: _blue,
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(
          width: 92,
          child: pw.Row(
            children: [
              _tableIcon(),
              pw.SizedBox(width: 8),
              pw.Text(
                'EASYTAB',
                style: pw.TextStyle(
                  color: _white,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  color: _white,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                subtitle,
                style: const pw.TextStyle(color: _white, fontSize: 10),
              ),
            ],
          ),
        ),
        pw.SizedBox(
          width: 92,
          child: pw.Text(
            'Generisano\n${_dateTimeFormat.format(generatedAt)}',
            textAlign: pw.TextAlign.right,
            style: const pw.TextStyle(color: _white, fontSize: 8.5),
          ),
        ),
      ],
    ),
  );

  static pw.Widget _tableIcon() => pw.Container(
    width: 28,
    height: 28,
    alignment: pw.Alignment.center,
    decoration: pw.BoxDecoration(
      color: _white,
      borderRadius: pw.BorderRadius.circular(7),
    ),
    child: pw.CustomPaint(
      size: const PdfPoint(20, 20),
      painter: (canvas, size) {
        canvas
          ..setColor(_blue)
          ..setLineWidth(1.6)
          ..drawRect(4, 7, 12, 6)
          ..strokePath()
          ..moveTo(6, 7)
          ..lineTo(6, 3)
          ..moveTo(14, 7)
          ..lineTo(14, 3)
          ..strokePath();
      },
    ),
  );

  static pw.Widget _footer(pw.Context context) => pw.Container(
    alignment: pw.Alignment.centerRight,
    padding: const pw.EdgeInsets.only(top: 12),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _border, width: .7)),
    ),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            'EasyTab',
            style: const pw.TextStyle(color: _mutedText, fontSize: 8),
          ),
        ),
        pw.Text(
          'Stranica ${context.pageNumber} od ${context.pagesCount}',
          style: const pw.TextStyle(color: _mutedText, fontSize: 8),
        ),
      ],
    ),
  );

  static pw.Widget _sectionTitle(String text) => pw.Text(
    text,
    style: pw.TextStyle(
      color: _text,
      fontSize: 15,
      fontWeight: pw.FontWeight.bold,
    ),
  );

  static pw.Widget _statCard(String label, String value) => pw.Container(
    width: 160,
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: _lightBlue,
      border: pw.Border.all(color: _border),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(color: _mutedText, fontSize: 9),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: _blue,
            fontSize: 21,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  static pw.Widget _dataTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) => pw.Table(
    border: pw.TableBorder.all(color: _border, width: .7),
    columnWidths: {
      for (var index = 0; index < headers.length; index++)
        index: pw.FlexColumnWidth(index == 0 ? 2 : 1),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _blue),
        children: headers
            .map(
              (header) => pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Text(
                  header,
                  style: pw.TextStyle(
                    color: _white,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            )
            .toList(),
      ),
      for (var index = 0; index < rows.length; index++)
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: index.isEven ? _white : _lightBlue,
          ),
          children: rows[index]
              .map(
                (cell) => pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    cell,
                    style: const pw.TextStyle(color: _text, fontSize: 9),
                  ),
                ),
              )
              .toList(),
        ),
    ],
  );

  static pw.Widget _emptyState(String text) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(18),
    decoration: pw.BoxDecoration(
      color: _lightBlue,
      border: pw.Border.all(color: _border),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Text(
      text,
      style: const pw.TextStyle(color: _mutedText, fontSize: 10),
    ),
  );

  static Future<String> _writePdf(String fileName, pw.Document document) async {
    final directory = await downloadsDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(await document.save(), flush: true);
    return file.path;
  }

  static String _sanitizeFileName(String value) {
    final cleaned = value.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    return cleaned.isEmpty ? 'izvjestaj' : cleaned.replaceAll(' ', '_');
  }
}
